#!/bin/bash

# Configuration
SERVICE="mc"
PROPS_FILE="./server-data/server.properties"

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
        docker compose restart
        ;;
    "backup")
        echo "Starting Backup Workflow..."
        WORLD_BACKUP=true docker compose up -d --force-recreate
        echo "Backup complete (Server is restarting...)"
        ;;
    "reset")
        echo "WARNING: This will PERMANENTLY DELETE your world!"
        read -p "Are you sure? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            echo "Resetting world..."
            RESET_WORLD=true docker compose up -d --force-recreate
        else
            echo "World reset cancelled."
        fi
        ;;
    "properties")
        if [ -f "$PROPS_FILE" ]; then
            echo "Current server.properties:"
            echo "-----------------------------"
            grep -E "^(motd|level-name|level-type|difficulty|gamemode|level-seed|max-players|server-port|online-mode)" "$PROPS_FILE"
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
        echo "Commands: start, stop, restart, backup, reset, properties, edit, logs"
        ;;
esac
