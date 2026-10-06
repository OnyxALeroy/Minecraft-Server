#!/bin/bash
# Backup / restore helper. Runs inside a one-off container (see manage.sh)
# while the server is STOPPED, so the world files are consistent.
#
# Usage: backup.sh create | verify <file> | info <file> | preview <file>
#                  | restore <file> | list | wipe
set -euo pipefail

DATA_DIR=${DATA_DIR:-/data}
BACKUP_DIR=${BACKUP_DIR:-/backups}
MODPACK_DIR=${MODPACK_DIR:-/modpack}
INFO_NAME="BACKUP_INFO.txt"

mkdir -p "$BACKUP_DIR"
cd "$DATA_DIR"

# --- helpers ----------------------------------------------------------

level_name() {
    local name=""
    [ -f server.properties ] && name=$(grep -E '^level-name=' server.properties | tail -n 1 | cut -d= -f2- || true)
    echo "${name:-world}"
}

# Resolve a backup argument (name or path) to a file inside BACKUP_DIR
resolve() {
    [ -n "${1:-}" ] || { echo "ERROR: no backup file given." >&2; exit 1; }
    local f="$BACKUP_DIR/$(basename "$1")"
    [ -f "$f" ] || { echo "ERROR: backup not found: $(basename "$1")" >&2; exit 1; }
    echo "$f"
}

manifest_path() { echo "${1%.tar.gz}.txt"; }

write_manifest() {
    local out="$1" level="$2"
    local pack index
    pack=$(find "$MODPACK_DIR" -maxdepth 1 -name '*.mrpack' 2>/dev/null | head -n 1 || true)
    {
        echo "=== Minecraft server backup ==="
        echo "Created:        $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
        echo "World folder:   $level ($(du -sh "$level" 2>/dev/null | cut -f1))"
        echo "Repo commit:    ${GIT_COMMIT:-unknown}"
        echo "Java:           $(java -version 2>&1 | grep -v '^Picked up' | head -n 1 || echo unknown)"
        if [ -n "$pack" ]; then
            index=$(unzip -p "$pack" modrinth.index.json 2>/dev/null || echo '{}')
            echo "Modpack:        $(echo "$index" | jq -r '"\(.name // "?") \(.versionId // "")"')"
            echo "Modpack file:   $(basename "$pack")"
            echo "Modpack sha1:   $(sha1sum "$pack" | cut -d' ' -f1)"
            echo "Minecraft:      $(echo "$index" | jq -r '.dependencies.minecraft // "?"')"
            echo "Loader:         $(echo "$index" | jq -r '.dependencies | to_entries | map(select(.key != "minecraft") | "\(.key) \(.value)") | join(", ")')"
        else
            echo "Modpack:        none (fallback Fabric 1.20.1)"
        fi
        echo
        echo "=== server.env ==="
        for k in MEMORY_SIZE USE_AIKAR_FLAGS VIEW_DISTANCE SIMULATION_DISTANCE ENTITY_BROADCAST_RANGE \
                 SYNC_CHUNK_WRITES NETWORK_COMPRESSION_THRESHOLD MAX_TICK_TIME EXTRA_MODS; do
            echo "$k=${!k:-}"
        done
        echo
        echo "=== Mods (sha1  file) ==="
        if ls mods/*.jar >/dev/null 2>&1; then
            (cd mods && sha1sum -- *.jar | sort -k2)
        else
            echo "(none)"
        fi
        echo
        echo "=== server.properties ==="
        if [ -f server.properties ]; then
            sed -E 's/^(rcon\.password=).+/\1********/' server.properties
        else
            echo "(missing)"
        fi
    } > "$out"
}

verify() {
    local f="$1" listing level_dat
    echo "Verifying $(basename "$f")..."
    if ! gzip -t "$f" 2>/dev/null; then
        echo "   FAILED: archive is corrupted (gzip check)." >&2; return 1
    fi
    if ! listing=$(tar -tzf "$f" 2>/dev/null); then
        echo "   FAILED: archive is unreadable (tar check)." >&2; return 1
    fi
    level_dat=$(echo "$listing" | grep -E '^(\./)?[^/]+/level\.dat$' | head -n 1 || true)
    if [ -z "$level_dat" ]; then
        echo "   FAILED: no <world>/level.dat inside, this is not a usable world backup." >&2; return 1
    fi
    echo "   OK: $(du -h "$f" | cut -f1), $(echo "$listing" | wc -l) entries, world: ${level_dat%/level.dat}"
}

# Top-level names in the archive (world folders, mods, config, server.properties)
top_entries() {
    tar -tzf "$1" | sed -E 's#^\./##' | cut -d/ -f1 | grep -v -e '^$' -e "^${INFO_NAME}\$" | sort -u
}

print_info() {
    local f="$1" m
    m=$(manifest_path "$f")
    if [ -f "$m" ]; then
        cat "$m"
    elif tar -tzf "$f" 2>/dev/null | grep -qx "$INFO_NAME"; then
        tar -xzOf "$f" "$INFO_NAME"
    else
        echo "(no manifest: backup made before manifests existed)"
    fi
}

# --- commands ---------------------------------------------------------

cmd_create() {
    local level ts entries=()
    level=$(level_name)
    if [ ! -f "$level/level.dat" ]; then
        echo "ERROR: no world found at $DATA_DIR/$level (nothing to back up)." >&2; exit 1
    fi
    for e in "$level" world_nether world_the_end mods config server.properties \
             whitelist.json ops.json banned-players.json banned-ips.json; do
        [ -e "$e" ] && entries+=("$e")
    done

    ts=$(date +%Y%m%d_%H%M%S)
    name="$BACKUP_DIR/backup-$ts.tar.gz"
    tmp=$(mktemp -d)
    # globals (not local) so the EXIT trap can still see them
    trap 'rm -rf "${tmp:-}" "${name:-}.partial"' EXIT

    echo "Creating backup-$ts (${entries[*]})..."
    write_manifest "$tmp/$INFO_NAME" "$level"
    tar -czf "$name.partial" "${entries[@]}" -C "$tmp" "$INFO_NAME"

    verify "$name.partial"
    mv "$name.partial" "$name"
    cp "$tmp/$INFO_NAME" "$(manifest_path "$name")"
    echo "Backup OK: backups/$(basename "$name")"
    echo "Manifest:  backups/$(basename "$(manifest_path "$name")")"
}

cmd_preview() {
    local f="$1"
    verify "$f"
    echo
    print_info "$f" | sed -n '1,/^$/p'
    echo "=== Mod changes since this backup ==="
    local old new
    old=$(tar -tzf "$f" | sed -E 's#^\./##' | grep -E '^mods/[^/]+\.jar$' | sed 's#^mods/##' | sort || true)
    new=$(ls mods 2>/dev/null | grep '\.jar$' | sort || true)
    if [ -z "$old" ]; then
        echo "(backup has no mods/ folder: current mods will be kept)"
    else
        comm -23 <(echo "$old") <(echo "$new") | sed 's/^/   - only in backup:  /'
        comm -13 <(echo "$old") <(echo "$new") | sed 's/^/   + only in current: /'
        [ "$old" = "$new" ] && echo "   (identical)"
    fi
    return 0
}

cmd_restore() {
    local f="$1" ts aside
    verify "$f"
    ts=$(date +%Y%m%d_%H%M%S)
    aside="pre-restore-$ts"
    mkdir -p "$aside"

    echo "Moving current files to server-data/$aside/ ..."
    while read -r e; do
        [ -e "$e" ] && mv "$e" "$aside/"
    done < <(top_entries "$f")

    echo "Extracting $(basename "$f")..."
    if ! tar -xzf "$f" --exclude="$INFO_NAME"; then
        echo "ERROR: extraction failed, putting the previous files back..." >&2
        while read -r e; do rm -rf "$e"; done < <(top_entries "$f")
        mv "$aside"/* . 2>/dev/null || true
        rmdir "$aside" 2>/dev/null || true
        exit 1
    fi
    rmdir "$aside" 2>/dev/null || true
    echo "Restore OK. Previous state kept in server-data/$aside/ (delete it once you're happy)."
}

cmd_list() {
    local found=0 f m
    for f in $(ls -1t "$BACKUP_DIR"/*.tar.gz 2>/dev/null); do
        found=1
        m=$(manifest_path "$f")
        if [ -f "$m" ]; then
            printf '%-36s %6s  MC %-8s %s\n' "$(basename "$f")" "$(du -h "$f" | cut -f1)" \
                "$(grep -m1 '^Minecraft:' "$m" | awk '{print $2}')" \
                "$(grep -m1 '^Modpack:' "$m" | cut -d: -f2- | sed 's/^ *//')"
        else
            printf '%-36s %6s  (no manifest)\n' "$(basename "$f")" "$(du -h "$f" | cut -f1)"
        fi
    done
    [ "$found" = 1 ] || echo "(no backups yet)"
}

cmd_wipe() {
    local level
    level=$(level_name)
    echo "Wiping world ($level) and server install..."
    rm -rf "$level" world_nether world_the_end
    rm -f server.jar fabric-server-launch.jar
    rm -rf libraries versions mods config
    echo "Wipe done."
}

case "${1:-}" in
    create)  cmd_create ;;
    verify)  verify "$(resolve "${2:-}")" ;;
    info)    print_info "$(resolve "${2:-}")" ;;
    preview) cmd_preview "$(resolve "${2:-}")" ;;
    restore) cmd_restore "$(resolve "${2:-}")" ;;
    list)    cmd_list ;;
    wipe)    cmd_wipe ;;
    *) echo "Usage: backup.sh create|verify|info|preview|restore <file>|list|wipe" >&2; exit 1 ;;
esac
