#!/bin/bash

# Minecraft Server Startup Script with Modrinth Integration
set -e

echo "=== Minecraft Modded Server Startup ==="

# Function to download Minecraft server JAR
download_server() {
    local version=${MINECRAFT_VERSION:-latest}
    echo "Downloading Minecraft server version: $version"
    
    if [ "$version" = "latest" ]; then
        # Get latest version from Mojang API
        version=$(curl -s https://launchermeta.mojang.com/mc/game/version_manifest.json | jq -r '.latest.release')
    fi
    
    # Download server JAR
    local manifest_url="https://launchermeta.mojang.com/mc/game/version_manifest.json"
    local version_info=$(curl -s "$manifest_url" | jq -r --arg version "$version" '.versions[] | select(.id == $version)')
    local server_url=$(echo "$version_info" | jq -r '.downloads.server.url')
    
    wget -O server.jar "$server_url"
    echo "Server JAR downloaded successfully"
}

# Function to setup Modrinth instance
setup_modrinth() {
    echo "=== Setting up Modrinth Instance ==="
    
    # Check if Modrinth instance exists
    if [ -d "/minecraft/modrinth" ] && [ "$(ls -A /minecraft/modrinth)" ]; then
        echo "Modrinth instance found, processing..."
        
        # Use Modrinth CLI to install mods
        cd /minecraft/modrinth
        
        # Install mods from modrinth.json if it exists
        if [ -f "modrinth.json" ]; then
            echo "Installing mods from modrinth.json"
            modrinth install
        fi
        
        # Copy mods to server mods directory
        if [ -d "mods" ]; then
            cp -r mods/* /minecraft/mods/ 2>/dev/null || true
        fi
        
        # Copy config to server config directory
        if [ -d "config" ]; then
            cp -r config/* /minecraft/config/ 2>/dev/null || true
        fi
        
        echo "Modrinth setup completed"
    else
        echo "No Modrinth instance found. Server will run vanilla."
    fi
}

# Function to accept EULA
accept_eula() {
    if [ ! -f "/minecraft/server/eula.txt" ]; then
        echo "EULA not found. Creating eula.txt with accepted=true"
        echo "eula=true" > /minecraft/server/eula.txt
    fi
}

# Function to setup server properties
setup_properties() {
    if [ ! -f "/minecraft/server/server.properties" ]; then
        echo "Creating default server.properties"
        cat > /minecraft/server/server.properties << EOF
# Minecraft Server Properties
generator-settings=
allow-nether=true
level-name=world
enable-query=false
allow-flight=false
broadcast-console-to-ops=true
view-distance=10
server-ip=
resource-pack-sha1=
max-build-height=256
spawn-npcs=true
white-list=false
generate-structures=true
online-mode=true
difficulty=easy
network-compression-threshold=256
max-tick-time=60000
enforce-whitelist=false
use-native-transport=true
max-players=20
server-port=25565
server-name=Minecraft Server
motd=Welcome to my Minecraft Server!
EOF
    fi
}

# Main execution
cd /minecraft/server

# Download server if not exists
if [ ! -f "server.jar" ]; then
    download_server
fi

# Setup Modrinth
setup_modrinth

# Accept EULA
accept_eula

# Setup server properties
setup_properties

echo "=== Starting Minecraft Server ==="
echo "Memory allocated: ${MEMORY_SIZE:-4G}"
echo "Server port: 25565"

# Start the server with appropriate memory settings
exec java -Xms${MEMORY_SIZE:-4G} -Xmx${MEMORY_SIZE:-4G} -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true -jar server.jar nogui