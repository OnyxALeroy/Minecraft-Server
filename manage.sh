#!/bin/bash

# Configuration
SERVICE="mc"
PROPS_FILE="./server-data/server.properties"
TUNING_FILE="./server.env"
GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo unknown)

# Run backup.sh in a one-off container (server must be stopped)
bk() {
    docker compose run --rm --no-deps -T -e GIT_COMMIT="$GIT_COMMIT" \
        --entrypoint /minecraft/backup.sh "$SERVICE" "$@"
}

is_running() {
    [ -n "$(docker compose ps -q --status running "$SERVICE" 2>/dev/null)" ]
}

# Stop gracefully (world is saved), back up, verify. Returns 1 on failure.
do_backup() {
    echo "Stopping server so the world is saved and consistent..."
    docker compose stop "$SERVICE"
    bk create
}

# Send a console command to the running server through the internal RCON
mc_cmd() {
    is_running || { echo "ERROR: server is not running (./manage.sh start)."; return 1; }
    docker compose exec -T "$SERVICE" sh -c \
        'rcon-cli --port 25575 --password "$(grep "^rcon.password=" /data/server.properties | cut -d= -f2-)" "$@"' \
        _ "$@"
}

case "$1" in
    "start")
        echo "Starting Minecraft server..."
        docker compose up -d
        ;;
    "stop")
        echo "Stopping Minecraft server..."
        docker compose down
        ;;
    "restart")
        echo "Restarting Minecraft server..."
        # Recreate (not just restart) so edits to server.env are picked up
        docker compose up -d --force-recreate
        ;;
    "backup")
        WAS_RUNNING=false; is_running && WAS_RUNNING=true
        if do_backup; then STATUS=0; else STATUS=1; fi
        if [ "$WAS_RUNNING" = true ]; then
            echo "Starting server again..."
            docker compose up -d
        fi
        if [ "$STATUS" -ne 0 ]; then
            echo "ERROR: BACKUP FAILED. Don't do anything risky (Chunky, mod updates...) until it works."
            exit 1
        fi
        ;;
    "backups")
        bk list
        ;;
    "verify")
        [ -n "$2" ] || { echo "Usage: ./manage.sh verify <backup file>"; exit 1; }
        bk verify "$(basename "$2")"
        ;;
    "backup-info")
        [ -n "$2" ] || { echo "Usage: ./manage.sh backup-info <backup file>"; exit 1; }
        bk info "$(basename "$2")"
        ;;
    "restore")
        FILE="$2"
        if [ -z "$FILE" ]; then
            echo "Available backups (newest first):"
            bk list
            read -p "Backup file to restore: " FILE
        fi
        FILE=$(basename "$FILE")
        [ -n "$FILE" ] || { echo "Restore cancelled."; exit 1; }
        bk preview "$FILE" || { echo "ERROR: this backup can't be restored."; exit 1; }
        echo
        echo "WARNING: the current world, mods, config and server.properties will be replaced."
        echo "         (They are kept in server-data/pre-restore-<date>/, not deleted.)"
        read -p "Restore $FILE? (yes/no): " confirm
        if [ "$confirm" != "yes" ]; then
            echo "Restore cancelled."
            exit 0
        fi
        docker compose stop "$SERVICE"
        if bk restore "$FILE"; then
            echo "Starting server with the restored world..."
            docker compose up -d
        else
            echo "ERROR: RESTORE FAILED. Server left stopped; check the messages above."
            exit 1
        fi
        ;;
    "reset")
        echo "WARNING: This will DELETE your world and reinstall the modpack!"
        echo "         (A backup is taken first.)"
        read -p "Are you sure? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            if ls ./server-data/*/level.dat >/dev/null 2>&1 && ! do_backup; then
                echo "ERROR: backup failed, reset ABORTED (world untouched)."
                exit 1
            fi
            docker compose stop "$SERVICE"
            bk wipe
            echo "Starting server (fresh world)..."
            docker compose up -d
        else
            echo "World reset cancelled."
        fi
        ;;
    "properties")
        if [ -f "$PROPS_FILE" ]; then
            echo "Current server.properties:"
            echo "-----------------------------"
            grep -E "^(motd|level-name|level-type|difficulty|gamemode|level-seed|max-players|server-port|online-mode|view-distance|simulation-distance)=" "$PROPS_FILE"
        else
            echo "ERROR: server.properties not found. (Is the server running?)"
        fi
        ;;
    "edit")
        if [ -f "$PROPS_FILE" ]; then
            ${EDITOR:-nano} "$PROPS_FILE"
            echo "WARNING: Don't forget to run './manage.sh restart' to apply changes!"
        else
            echo "ERROR: server.properties not found."
        fi
        ;;
    "tune")
        ${EDITOR:-nano} "$TUNING_FILE"
        echo "WARNING: Don't forget to run './manage.sh restart' to apply changes!"
        ;;
    "console")
        echo "Attaching to the server console (type commands, e.g. 'spark tps')."
        echo "   Detach with Ctrl-P then Ctrl-Q. Ctrl-C would STOP the server!"
        docker attach mc-server
        ;;
    "whitelist")
        ACTION="$2"; shift 2 2>/dev/null
        case "$ACTION" in
            add|remove)
                [ $# -gt 0 ] || { echo "Usage: ./manage.sh whitelist $ACTION <player> [player...]"; exit 1; }
                for P in "$@"; do mc_cmd whitelist "$ACTION" "$P" || exit 1; done
                ;;
            list|reload)
                mc_cmd whitelist "$ACTION"
                ;;
            on|off)
                mc_cmd whitelist "$ACTION"
                echo "NOTE: until next restart only. Set WHITELIST in server.env to make it permanent."
                ;;
            *)
                echo "Usage: ./manage.sh whitelist add|remove <player...> | list | on | off | reload"
                exit 1
                ;;
        esac
        ;;
    "cmd")
        shift
        [ $# -gt 0 ] || { echo "Usage: ./manage.sh cmd <console command>  (e.g. ./manage.sh cmd spark tps)"; exit 1; }
        mc_cmd "$@"
        ;;
    "logs")
        echo "📄 Following CLEAN server logs (Spam hidden)..."
        echo "   (Use './manage.sh logs-full' to see everything)"
        # We pipe the logs into grep with -v (Invert Match)
        docker compose logs -f $SERVICE | grep -vE --line-buffered \
        "Lithium Class Analysis Error|Reference map|could not be read|Force-disabling mixin|Incorrect key|Configuration file .* is not correct|Correcting"
            ;;
    "logs-full")
        echo "📄 Following RAW server logs..."
        docker compose logs -f $SERVICE
        ;;
    "help"|*)
        echo "Minecraft Server Manager"
        echo "Usage: ./manage.sh [command]"
        echo "Commands: start, stop, restart, properties, edit, tune, console, cmd <command>, logs"
        echo "Players:  whitelist add|remove <player...>, whitelist list|on|off|reload"
        echo "Backups:  backup, backups, verify <file>, backup-info <file>, restore [file], reset"
        ;;
esac
