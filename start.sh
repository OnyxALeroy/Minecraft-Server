#!/bin/bash
set -e

echo "=== Minecraft Server Startup ==="
cd /data

MEMORY_SIZE=${MEMORY_SIZE:-4G}

# Writes key=value into server.properties (replace if present, append if not).
# Does nothing when value is empty, so blank settings in server.env are left alone.
set_prop() {
    local key="$1" value="$2"
    [ -z "$value" ] && return 0
    if grep -q "^${key}=" server.properties; then
        sed -i "s|^${key}=.*|${key}=${value}|" server.properties
    else
        echo "${key}=${value}" >> server.properties
    fi
    echo "   ${key}=${value}"
}

# (Backup / restore / reset are handled by backup.sh via ./manage.sh)

# --- 3. INIT CONFIG ---
echo "eula=true" > eula.txt

if [ ! -f "server.properties" ]; then
    echo "Creating default server.properties..."
    cat > server.properties << 'EOF'
motd=Onyx's Modded Server
server-port=25565
max-players=20
view-distance=7
online-mode=true
difficulty=normal
EOF
fi

echo "Applying server.env overrides to server.properties..."
set_prop view-distance "$VIEW_DISTANCE"
set_prop simulation-distance "$SIMULATION_DISTANCE"
set_prop entity-broadcast-range-percentage "$ENTITY_BROADCAST_RANGE"
set_prop sync-chunk-writes "$SYNC_CHUNK_WRITES"
set_prop network-compression-threshold "$NETWORK_COMPRESSION_THRESHOLD"
set_prop max-tick-time "$MAX_TICK_TIME"
set_prop white-list "$WHITELIST"
set_prop enforce-whitelist "$WHITELIST"

# RCON lets ./manage.sh send console commands (whitelist, cmd...).
# Port 25575 is NOT published in docker-compose.yml: only reachable inside the container.
# New random password on every boot.
echo "Enabling internal RCON..."
set_prop enable-rcon true
set_prop rcon.port 25575
RCON_PW=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 24)
sed -i "s|^rcon.password=.*|rcon.password=${RCON_PW}|" server.properties
grep -q "^rcon.password=" server.properties || echo "rcon.password=${RCON_PW}" >> server.properties

# --- 4. INSTALL MODPACK ---
MRPACK_FILE=$(find /modpack -name "*.mrpack" | head -n 1)

if [ -n "$MRPACK_FILE" ]; then
    echo "Modpack Found: $(basename "$MRPACK_FILE")"
    echo "Installing Pack & Loader..."
    # Downloads mods AND the correct server.jar / fabric-loader
    mrpack-install "$MRPACK_FILE" --server-dir /data --server-file server.jar
else
    echo "ERROR: No .mrpack found in /modpack folder."
    if [ ! -f "fabric-server-launch.jar" ] && [ ! -f "server.jar" ]; then
        echo "Downloading Fallback: Fabric 1.20.1..."
        mrpack-install server fabric --minecraft-version 1.20.1 --loader-version latest --server-dir /data --server-file fabric-server-launch.jar

        # Auto-install Fabric API (Essential)
        echo "Downloading Fabric API..."
        mkdir -p mods
        wget -q -P mods/ https://cdn.modrinth.com/data/P7dR8mSH/versions/7.6.0+1.20.1/fabric-api-0.83.0+1.20.1.jar
    fi
fi

# --- 4b. EXTRA SERVER-SIDE MODS ---
if [ -n "$EXTRA_MODS" ]; then
    echo "Extra mods: $EXTRA_MODS"
    MC_VERSION="1.20.1"
    LOADER="fabric"
    if [ -n "$MRPACK_FILE" ]; then
        PACK_DEPS=$(unzip -p "$MRPACK_FILE" modrinth.index.json 2>/dev/null | jq -c '.dependencies // {}' 2>/dev/null || echo '{}')
        MC_VERSION=$(echo "$PACK_DEPS" | jq -r '.minecraft // "1.20.1"')
        if echo "$PACK_DEPS" | jq -e 'has("neoforge")' >/dev/null; then LOADER="neoforge"
        elif echo "$PACK_DEPS" | jq -e 'has("forge")' >/dev/null; then LOADER="forge"
        fi
    fi
    echo "   Target: Minecraft $MC_VERSION ($LOADER)"
    mkdir -p mods

    # Project IDs of every jar already in mods/ (identified by Modrinth via sha1),
    # so we never add a second copy of a mod the pack already ships.
    INSTALLED_IDS="[]"
    HASHES=$(find mods -maxdepth 1 -name '*.jar' -exec sha1sum {} + 2>/dev/null | awk '{print $1}' | jq -R . | jq -sc .)
    if [ "$HASHES" != "[]" ]; then
        INSTALLED_IDS=$(curl -sf -X POST https://api.modrinth.com/v2/version_files \
            -H 'Content-Type: application/json' \
            -d "{\"hashes\": $HASHES, \"algorithm\": \"sha1\"}" \
            | jq -c '[.[].project_id]' 2>/dev/null || echo "[]")
        INSTALLED_IDS=${INSTALLED_IDS:-[]}
    fi

    for SLUG in $EXTRA_MODS; do
        VERSION_JSON=$(curl -sfG "https://api.modrinth.com/v2/project/${SLUG}/version" \
            --data-urlencode "loaders=[\"${LOADER}\"]" \
            --data-urlencode "game_versions=[\"${MC_VERSION}\"]" \
            | jq -c '.[0] // empty' 2>/dev/null || true)
        if [ -z "$VERSION_JSON" ]; then
            echo "   WARNING: ${SLUG}: no ${LOADER} build for ${MC_VERSION}, skipping"
            continue
        fi
        PROJECT_ID=$(echo "$VERSION_JSON" | jq -r '.project_id')
        if echo "$INSTALLED_IDS" | jq -e --arg id "$PROJECT_ID" 'index($id) != null' >/dev/null; then
            echo "   ${SLUG}: already installed, skipping"
            continue
        fi
        FILE_URL=$(echo "$VERSION_JSON" | jq -r '(.files | map(select(.primary)) + .files)[0].url')
        FILE_NAME=$(echo "$VERSION_JSON" | jq -r '(.files | map(select(.primary)) + .files)[0].filename')
        if wget -q -O "mods/${FILE_NAME}" "$FILE_URL"; then
            echo "   ${SLUG}: installed ${FILE_NAME}"
        else
            rm -f "mods/${FILE_NAME}"
            echo "   WARNING: ${SLUG}: download failed, skipping"
        fi
    done
fi

# --- 5. LAUNCH ---
echo "Launching Java Process..."
if [ "$USE_AIKAR_FLAGS" = "false" ]; then
    JVM_FLAGS="-XX:+UseG1GC"
else
    # Aikar's flags (https://docs.papermc.io/paper/aikars-flags), heap < 12G variant
    JVM_FLAGS="-XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 \
-XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch \
-XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M \
-XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 \
-XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 \
-XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem \
-XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true"
fi
echo "   Heap: ${MEMORY_SIZE} | Aikar flags: ${USE_AIKAR_FLAGS:-true}"
# Smart detection of what jar to run
if [ -f "run.sh" ]; then
    chmod +x run.sh
    # Forge-style launchers read JVM args from this file
    echo "-Xms${MEMORY_SIZE} -Xmx${MEMORY_SIZE} ${JVM_FLAGS}" > user_jvm_args.txt
    exec ./run.sh
elif [ -f "fabric-server-launch.jar" ]; then
    exec java -Xms${MEMORY_SIZE} -Xmx${MEMORY_SIZE} ${JVM_FLAGS} -jar fabric-server-launch.jar nogui
else
    # Vanilla or generic server.jar
    exec java -Xms${MEMORY_SIZE} -Xmx${MEMORY_SIZE} ${JVM_FLAGS} -jar server.jar nogui
fi
