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

### Backup Current World
```bash
./manage.sh backup
```
- Stops the server (world saved), archives world + mods + config + server.properties
- Verifies the archive, prints `Backup OK`, restarts the server
- Writes a manifest `backups/backup-<date>.txt`: MC version, loader, modpack, mods, settings

### List / Inspect Backups
```bash
./manage.sh backups              # list (size, MC version, modpack)
./manage.sh backup-info <file>   # full manifest
./manage.sh verify <file>        # integrity check
```

### Restore a Backup
```bash
./manage.sh restore              # pick from the list
```
- Shows the manifest and which mods changed since, asks `yes`
- Current files are moved to `server-data/pre-restore-<date>/`, never deleted

### Delete World & Start Fresh
```bash
./manage.sh reset
```
- **⚠️ Destructive!** Asks for confirmation, **takes a backup first**
- Deletes world, mods, config; reinstalls the modpack
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

### Tune Performance
```bash
./manage.sh tune
./manage.sh restart
```
- Opens `server.env`: memory, GC flags, view/simulation distance, extra mods
- These values override `server.properties` on every boot

### Server Console
```bash
./manage.sh console
```
- Run commands such as `spark tps` or `chunky start`
- Detach with **Ctrl-P then Ctrl-Q**. Ctrl-C stops the server!

Or send a single command without attaching (server must be running):
```bash
./manage.sh cmd spark tps
./manage.sh cmd op Steve
```

### Whitelist
Enabled by default (`WHITELIST=true` in `server.env`): only listed players can join.
```bash
./manage.sh whitelist add Steve Alex   # Allow players (one or more)
./manage.sh whitelist remove Steve     # Remove (kicks them if online)
./manage.sh whitelist list             # Show who is allowed
./manage.sh whitelist off              # Open the server until next restart
./manage.sh whitelist reload           # After hand-editing server-data/whitelist.json
```
- The server must be running (commands go through an internal RCON, never exposed outside the container)
- To open the server permanently: set `WHITELIST=false` in `server.env`, then `./manage.sh restart`
- `whitelist.json` (and `ops.json`, ban lists) are included in backups

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

### Backup Before Major Update (or Chunky)
1. `./manage.sh backup` (must print `Backup OK`)
2. Add mods/updates
3. `./manage.sh restart`

### Start Fresh World with New Settings
1. `./manage.sh edit`
2. Adjust properties as needed
3. `./manage.sh reset`

Your world automatically persists between normal restarts! 🌍✨