# Minecraft Modded Server - Docker Environment

A complete Docker-based setup for hosting a Minecraft modded server with Modrinth integration. This repository provides everything you need to run a modded Minecraft server with easy deployment and management.

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose installed on your system
- At least 4GB of RAM available (8GB+ recommended for modded servers)

### 1. Clone and Setup
```bash
git clone <your-repo-url>
cd Minecraft-Server
```

### 2. Add Your Modrinth Instance
Place your Modrinth instance files in the `modrinth-instance/` directory:
```bash
# Copy your Modrinth instance here
cp -r /path/to/your/modrinth-instance/* ./modrinth-instance/
```

### 3. Configure Server Settings
Edit the server configuration:
```bash
# Edit server properties (optional)
nano server.properties

# Accept EULA (required)
echo "eula=true" > eula.txt
```

### 4. Deploy the Server
```bash
# Build and start the server
docker-compose up -d

# View server logs
docker-compose logs -f minecraft-server
```

## 📁 Repository Structure

```
Minecraft-Server/
├── Dockerfile                 # Server container definition
├── docker-compose.yml         # Multi-container orchestration
├── start-server.sh           # Server startup script with Modrinth integration
├── README.md                 # This file
├── .gitignore                # Git ignore rules
├── server.properties         # Server configuration (create this)
├── eula.txt                  # EULA acceptance (create this)
├── modrinth-instance/        # 📁 YOUR MODRINTH INSTANCE GOES HERE
├── server-data/              # Server world and data (auto-created)
├── mods/                     # Mods directory (auto-created)
└── config/                   # Config files (auto-created)
```

## 🎮 How to Add Your Modrinth Instance

### Method 1: Export from Modrinth App
1. Open your modpack in the Modrinth App
2. Go to `File` → `Export Instance`
3. Choose `Folder` format
4. Extract the contents to `./modrinth-instance/`

### Method 2: Manual Setup
1. Create the directory: `mkdir modrinth-instance`
2. Add your `modrinth.json` file (contains mod list)
3. Add your `mods/` folder with all mod files
4. Add your `config/` folder with mod configurations
5. Add any resource packs or shader packs

### Required Files in Modrinth Instance
- `modrinth.json` - Mod list and dependencies
- `mods/` - All mod JAR files
- `config/` - Mod configuration files (optional)

## 🌐 Server Address and Access

### Default Server Address
- **IP**: `localhost` (if running locally) or your server's public IP
- **Port**: `25565`
- **Full Address**: `localhost:25565` or `YOUR_IP:25565`

### Finding Your Server IP
```bash
# Local IP (for LAN play)
ip addr show | grep inet

# Public IP (for internet play)
curl ifconfig.me
```

### Web Management Interface (Optional)
If enabled in docker-compose.yml:
- **Web Interface**: `http://localhost:8080`
- **Server Status**: Real-time monitoring and management

## 🎯 How to Play

### 1. Install Required Mods
Players need the same mods as the server:
- Use the same Modrinth instance
- Or install mods individually from Modrinth

### 2. Connect to Server
1. Open Minecraft (same version as server)
2. Go to `Multiplayer` → `Add Server`
3. Enter server name and address: `YOUR_IP:25565`
4. Click `Done` and join!

### 3. Server Commands
Common server commands (type in server console):
```bash
list                    # Show online players
op <player>            # Make player admin
deop <player>          # Remove admin status
whitelist add <player>  # Add to whitelist
whitelist remove <player> # Remove from whitelist
stop                    # Stop server gracefully
```

## ⚙️ Configuration

### Server Properties
Edit `server.properties` for basic settings:
```properties
# Server name
motd=My Modded Server

# Max players
max-players=20

# Game mode
gamemode=survival

# Difficulty
difficulty=hard

# Enable whitelist (recommended)
white-list=true
```

### Docker Environment Variables
In `docker-compose.yml`:
```yaml
environment:
  - MINECRAFT_VERSION=latest    # Minecraft version
  - MEMORY_SIZE=4G             # Server RAM allocation
  - SERVER_JAR=server.jar      # Server JAR name
```

### Resource Allocation
For different server sizes:
```yaml
# Small server (1-4 players, light mods)
- MEMORY_SIZE=2G

# Medium server (5-10 players, moderate mods)
- MEMORY_SIZE=4G

# Large server (10+ players, heavy mods)
- MEMORY_SIZE=8G
```

## 🔧 Management Commands

### Docker Compose Commands
```bash
# Start server
docker-compose up -d

# Stop server
docker-compose down

# View logs
docker-compose logs -f minecraft-server

# Access server console
docker-compose exec minecraft-server bash

# Restart server
docker-compose restart minecraft-server

# Update server (pull latest changes)
docker-compose pull && docker-compose up -d --build
```

### Backup Your World
```bash
# Create backup
docker-compose exec minecraft-server tar -czf /tmp/world-backup-$(date +%Y%m%d).tar.gz /minecraft/server/world

# Copy backup to host
docker cp minecraft-server:/tmp/world-backup-$(date +%Y%m%d).tar.gz ./backups/
```

## 🛠️ Troubleshooting

### Common Issues

**Server won't start:**
- Check if `eula.txt` exists and contains `eula=true`
- Verify Modrinth instance is properly placed
- Check Docker logs: `docker-compose logs minecraft-server`

**Can't connect to server:**
- Verify port 25565 is open (check firewall)
- Use correct IP address
- Ensure server is fully started (wait 2-3 minutes)

**Mods not loading:**
- Check if mods are compatible with Minecraft version
- Verify `modrinth.json` exists in instance folder
- Check server logs for mod loading errors

**Out of memory errors:**
- Increase `MEMORY_SIZE` in docker-compose.yml
- Remove resource-intensive mods
- Check system available RAM

### Performance Optimization
```yaml
# Add to docker-compose.yml for better performance
environment:
  - JAVA_OPTS="-XX:+UseG1GC -XX:MaxGCPauseMillis=200"
```

## 📝 Advanced Setup

### Custom Startup Script
Replace `start-server.sh` for custom server setup:
```bash
#!/bin/bash
# Your custom startup logic
echo "Starting custom server setup..."
# Add your commands here
```

### Multiple Servers
Duplicate the service in `docker-compose.yml`:
```yaml
minecraft-server-2:
  build: .
  ports:
    - "25566:25565"  # Different port
  # ... other config
```

### Reverse Proxy
Add Nginx for web interface:
```yaml
nginx:
  image: nginx:alpine
  ports:
    - "80:80"
  volumes:
    - ./nginx.conf:/etc/nginx/nginx.conf
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

- **Issues**: Report bugs via GitHub Issues
- **Discord**: Join our community Discord
- **Documentation**: Check the Wiki for detailed guides

---

**Happy Gaming! 🎮**