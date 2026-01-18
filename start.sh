#!/bin/bash
set -e

echo "=== Minecraft Server Startup ==="
cd /data

# --- 1. HANDLE RESET ---
if [ "$RESET_WORLD" = "true" ]; then
    echo "WARNING: RESET DETECTED: Wiping World & Server Jars..."

    # 1. Delete the World
    rm -rf world world_nether world_the_end

    # 2. Delete the Server Executables (Forces a re-install)
    rm -f server.jar fabric-server-launch.jar

    # 3. Delete libraries to ensure no version conflicts
    rm -rf libraries versions

    # 4. Delete old mods so we don't mix modpacks
    rm -rf mods config
fi

# --- 2. HANDLE BACKUP ---
if [ "$WORLD_BACKUP" = "true" ]; then
    echo "BACKUP DETECTED: Creating archive..."
    mkdir -p /backups
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    tar -czf "/backups/world-backup-${TIMESTAMP}.tar.gz" world world_nether world_the_end 2>/dev/null || echo "   (No world found to backup)"
fi

# --- 3. INIT CONFIG ---
echo "eula=true" > eula.txt

if [ ! -f "server.properties" ]; then
    echo "Creating default server.properties..."
    cat > server.properties << 'EOF'
motd=Onyx's Modded Server
server-port=25565
max-players=20
view-distance=10
online-mode=true
difficulty=normal
EOF
fi

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

# --- 5. LAUNCH ---
echo "Launching Java Process..."
# Smart detection of what jar to run
if [ -f "run.sh" ]; then
    chmod +x run.sh
    exec ./run.sh
elif [ -f "fabric-server-launch.jar" ]; then
    exec java -Xms${MEMORY_SIZE} -Xmx${MEMORY_SIZE} -XX:+UseG1GC -jar fabric-server-launch.jar nogui
else
    # Vanilla or generic server.jar
    exec java -Xms${MEMORY_SIZE} -Xmx${MEMORY_SIZE} -XX:+UseG1GC -jar server.jar nogui
fi
