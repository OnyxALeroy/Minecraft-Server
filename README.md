# Minecraft Modded Server - Docker Environment

A complete Docker-based setup for hosting a Minecraft modded server with Modrinth integration and easy management. This repository provides everything you need to run a modded Minecraft server with automatic world persistence, backups, and simple commands.

## Quick Start

### Prerequisites
- Docker and Docker Compose installed on your system
- At least 4GB of RAM available (8GB+ recommended for modded servers)

### 1. Clone and Setup
```bash
git clone <your-repo-url>
cd Minecraft-Server
```

### 2. Add Your Modrinth Modpack
**Method 1: .mrpack file (Recommended)**
```bash
# Copy your .mrpack file to modrinth-instance folder
cp /path/to/your/pack.mrpack ./modrinth-instance/
```

**Method 2: Manual mod files**
```bash
# Copy mods and configs manually
mkdir -p modrinth-instance/{mods,config}
cp -r /path/to/mods/* ./modrinth-instance/mods/
cp -r /path/to/configs/* ./modrinth-instance/config/
```

### 3. Start the Server
```bash
./manage.sh start
```

## Repository Structure

```
Minecraft-Server/
├── Dockerfile                 # Server container definition
├── docker-compose.yml         # Docker orchestration
├── start.sh                  # Server startup script
├── manage.sh                 # Management script (USE THIS!)
├── MANAGER.md               # Management guide
├── README.md                 # This file
├── .gitignore               # Git ignore rules
├── modrinth-instance/        # YOUR MODPACK GOES HERE
│   └── *.mrpack           # Your modrinth modpack files
├── server-data/              # World and data (auto-created)
│   ├── world/              # Main world
│   ├── world_nether/        # Nether dimension
│   ├── world_the_end/       # End dimension
│   ├── mods/                # Installed mods
│   ├── config/              # Mod configurations
│   ├── logs/                # Server logs
│   └── server.properties    # Server configuration
├── backups/                 # World backups (auto-created)
├── eula.txt.example         # Example EULA file
└── server.properties.example # Example server properties
```

## MAIN INTERFACE: Management Script

The `manage.sh` script is your primary interface for all server operations.

### Basic Operations
```bash
./manage.sh start        # Start server (keeps existing world)
./manage.sh stop         # Stop server gracefully
./manage.sh restart      # Quick restart
./manage.sh logs         # Follow server logs in real-time
./manage.sh help         # Show all available commands
```

### View Current Settings
```bash
./manage.sh properties
```
Output:
```
Current server.properties:
World Name: world
World Type: minecraft:normal
Difficulty: easy
Game Mode: survival
Seed: Random
Max Players: 20
Server Port: 25565
Online Mode: true
```

### Edit Server Configuration
```bash
./manage.sh edit
```
- Opens `server-data/server.properties` in your editor
- Common settings to change:
  ```properties
  difficulty=hard              # easy/normal/hard
  level-seed=8675309          # Specific world seed
  max-players=50              # More players
  motd=My Epic Server!        # Server message
  gamemode=creative            # creative/survival/adventure
  ```
- **Important**: Changes apply on next restart!

### World Backup and Reset

**Create Backup & Restart:**
```bash
./manage.sh backup
```
- Creates timestamped backup: `backups/world-backup-20240118-143022.tar.gz`
- Restarts server safely
- **Use when**: Before major changes, updates, or experiments

**Reset World Completely:**
```bash
./manage.sh reset
```
Interactive process:
```
WARNING: This will delete your current world!
Are you sure? (yes/no): yes
Resetting world and starting server...
```
- Deletes: `world/`, `world_nether/`, `world_the_end/`
- Generates fresh world using current server.properties
- **Use when**: Want completely new start with different settings

## Practical Workflows

### Scenario 1: First Time Setup
```bash
# 1. Add your modpack
cp your-pack.mrpack ./modrinth-instance/

# 2. Start server
./manage.sh start

# 3. Connect to Minecraft: localhost:25565
```

### Scenario 2: Change World Difficulty
```bash
# 1. Edit settings
./manage.sh edit
# Change: difficulty=easy → difficulty=hard

# 2. Restart to apply (keeps existing world)
./manage.sh restart
```

### Scenario 3: Try New World Seed
```bash
# 1. Set seed in properties
./manage.sh edit
# Add/change: level-seed=123456789

# 2. Reset world (generates new with seed)
./manage.sh reset
```

### Scenario 4: Backup Before Major Update
```bash
# 1. Backup current progress
./manage.sh backup

# 2. Add new mods/update modpack
# Place new .mrpack in modrinth-instance/

# 3. Restart with updates
./manage.sh restart
```

### Scenario 5: Server Won't Start?
```bash
# Check logs for errors
./manage.sh logs

# If mods are causing issues:
./manage.sh backup      # Save current world first
# Remove problematic mods from ./server-data/mods/
./manage.sh restart      # Try without problematic mods
```

## Server Connection

### Connecting to Your Server
1. Open Minecraft (same version as your modpack)
2. Go to `Multiplayer` → `Add Server`
3. **Server Address**: `localhost:25565`
4. **Server Name**: Whatever you want
5. Click `Done` and join!

### Finding Your Server IP
```bash
# For local network (friends on same WiFi)
ip addr show | grep inet

# For internet friends
curl ifconfig.me
```

Friends would connect to: `YOUR_IP:25565`

## Adding Mods and Modpacks

### Option 1: Modrinth .mrpack (Easiest)
1. Export your modpack from Modrinth App as `.mrpack`
2. Copy to `./modrinth-instance/your-pack.mrpack`
3. `./manage.sh reset` (for fresh install with new pack)

### Option 2: Individual Mods
```bash
# Copy mod files directly
cp *.jar ./mods/

# Copy config files (optional)
cp -r configs/* ./config/

./manage.sh restart
```

### Option 3: Manual Modrinth Instance
```bash
mkdir -p modrinth-instance/{mods,config}
# Copy mod files to modrinth-instance/mods/
# Copy config files to modrinth-instance/config/
```

## World Persistence and Backups

### How Persistence Works
- **Normal restart**: World automatically saves, no data loss
- **Server crash**: World data preserved in `./server-data/`
- **Docker restart**: All progress remains intact

### Backup System
```bash
# Automatic backup before risky operations
./manage.sh backup

# Manual backup anytime
docker-compose exec minecraft-server tar -czf /tmp/manual-backup.tar.gz /data/world

# List all backups
ls -la backups/
# Output: world-backup-20240118-143022.tar.gz
```

### Restore from Backup
```bash
# 1. Stop server
./manage.sh stop

# 2. Restore backup
tar -xzf backups/world-backup-20240118-143022.tar.gz -C server-data/

# 3. Start server
./manage.sh start
```

## Advanced Configuration

### Performance Tuning
Edit `docker-compose.yml` to adjust memory:
```yaml
environment:
  - MEMORY_SIZE=8G    # Increase for more mods/players
```

### Server Properties Reference
Edit `./server-data/server.properties`:
```properties
# Core Settings
level-name=world              # World folder name
level-type=minecraft:normal    # normal/flat/largebiomes
level-seed=                   # Empty = random, or specific number
gamemode=survival             # survival/creative/adventure
difficulty=hard               # easy/normal/hard

# Multiplayer
max-players=20               # Maximum concurrent players
online-mode=true              # Require authenticated Minecraft
white-list=false              # Only allow whitelisted players

# Performance
view-distance=10              # How far chunks render
simulation-distance=6         # How far entities update

# Features
generate-structures=true      # Villages, temples, etc.
allow-nether=true            # Enable Nether
pvp=true                    # Player vs Player combat
allow-flight=false            # Allow creative flying
```

## Troubleshooting

### Common Issues and Solutions

**Server won't start:**
```bash
# Check logs
./manage.sh logs

# Verify EULA
cat ./server-data/eula.txt  # Should contain: eula=true

# Check modpack placement
ls ./modrinth-instance/      # Should contain .mrpack files
```

**Can't connect to server:**
```bash
# Check if server is running
docker-compose ps

# Verify port
netstat -tulpn | grep 25565

# Check firewall
sudo ufw status
```

**Mods not loading:**
```bash
# Check mods directory
ls ./server-data/mods/

# Check logs for mod errors
./manage.sh logs | grep -i error
```

**Performance issues:**
```bash
# Increase memory allocation
./manage.sh edit
# In docker-compose.yml, change: MEMORY_SIZE=8G

# Check system resources
free -h
df -h
```

## Maintenance Commands

### Regular Maintenance
```bash
# Daily restart (good practice)
./manage.sh restart

# Weekly backup
./manage.sh backup

# Update modpack
cp new-pack.mrpack ./modrinth-instance/
./manage.sh backup    # Backup old world first
./manage.sh reset     # Fresh start with new pack
```

### Server Management
```bash
# Access server console directly
docker-compose exec minecraft-server bash

# Monitor resource usage
docker stats minecraft-server

# Clean old backups (keep last 5)
cd backups && ls -t | tail -n +6 | xargs rm -f
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Test thoroughly with different modpacks
4. Submit a pull request with detailed testing notes

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

- **Issues**: Report bugs via GitHub Issues with logs
- **Documentation**: Check MANAGER.md for detailed management guide
- **Community**: Join our Discord for live help

---

## Quick Reference Cheat Sheet

```bash
./manage.sh start       # Start server
./manage.sh properties  # View settings  
./manage.sh edit       # Change settings
./manage.sh backup      # Backup world
./manage.sh reset       # New world
./manage.sh logs        # Monitor server
./manage.sh stop        # Shut down
./manage.sh help        # All commands

# Connect: localhost:25565
# World data: ./server-data/
# Backups: ./backups/
# Modpacks: ./modrinth-instance/
```

**Happy Gaming!