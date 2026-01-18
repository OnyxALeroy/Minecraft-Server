# 🎮 Minecraft Modded Server - Manager

## 🚀 Quick Start

### Start Server
```bash
./manage.sh start
```

### View Current Server Properties
```bash
./manage.sh properties
```

## 🔄 World Management

### Backup Current World & Restart
```bash
./manage.sh backup
```
- Creates timestamped backup in `./backups/`
- Restarts server with new save

### Delete World & Start Fresh
```bash
./manage.sh reset
```
- **⚠️ Destructive!** Asks for confirmation
- Deletes world, nether, end dimensions
- Generates new world with current server.properties

## ⚙️ Configuration

### Edit Server Properties
```bash
./manage.sh edit
```
- Opens server.properties in your editor ($EDITOR or nano)
- Changes apply on next restart

### View Current Settings
```bash
./manage.sh properties
```
Shows:
- World name & type
- Difficulty & game mode  
- Seed (or "Random")
- Max players & port
- Online mode

## 📊 Server Management

```bash
./manage.sh logs        # Follow server logs
./manage.sh stop        # Stop server  
./manage.sh restart     # Restart server
./manage.sh help        # Show all commands
```

## 📁 Directory Structure

```
Minecraft-Server/
├── server-data/          # 🌍 World and server data
│   ├── world/          # Main world
│   ├── world_nether/    # Nether dimension  
│   ├── world_the_end/   # End dimension
│   └── server.properties # ⚙️ Server settings
├── backups/             # 💾 World backups
├── modrinth-instance/   # 📦 Your .mrpack files
└── manage.sh           # 🎮 Management script
```

## 🎯 Workflow Examples

### Change World Seed
1. `./manage.sh edit`
2. Change `level-seed=your_seed_here`
3. `./manage.sh reset`
4. Server starts with new seed

### Backup Before Major Update
1. `./manage.sh backup`
2. Add mods/updates
3. `./manage.sh restart`

### Start Fresh World with New Settings
1. `./manage.sh edit`
2. Adjust properties as needed
3. `./manage.sh reset`

Your world automatically persists between normal restarts! 🌍✨