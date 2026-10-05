# 🚀 Starting the Server

## First time

1. **Add your modpack**: put your `.mrpack` file in `modrinth-instance/`:
   ```bash
   mkdir -p modrinth-instance
   cp /path/to/your-pack.mrpack modrinth-instance/
   ```
   (No pack? The server falls back to plain Fabric 1.20.1.)

2. **Check the settings** in `server.env` (memory, view/simulation distance, extra mods):
   ```bash
   ./manage.sh tune
   ```
   The defaults are fine for a small server. Keep `MEMORY_SIZE` at least 2G below your PC's RAM.

3. **Start it**:
   ```bash
   ./manage.sh start
   ```
   The first boot takes a few minutes while it downloads the modpack and generates the world.

4. **Watch it boot**:
   ```bash
   ./manage.sh logs
   ```
   It's ready when you see `Done (...)! For help, type "help"`. Press Ctrl-C to stop following the logs (the server keeps running).

5. **Connect**: in Minecraft, go to Multiplayer → Add Server → `localhost:25565`. Friends use your IP (see README → *Server Connection*).

6. **Take a first backup** and check it prints `Backup OK`:
   ```bash
   ./manage.sh backup
   ```
   Test it once: see README → *Test Your Backups*.

7. **Recommended**: pre-generate the world to avoid exploration lag:
   ```bash
   ./manage.sh console
   chunky radius 2000
   chunky start
   ```
   Detach with **Ctrl-P then Ctrl-Q**. Ctrl-C would stop the server!
   After a crash, run `chunky continue`. If the world got damaged, run `./manage.sh restore`.
   Full guide: README → *Safe Pre-generation with Chunky*.

## After a `git pull`

```bash
./manage.sh backup     # safety first
./manage.sh restart    # recreates the container with the new config
```

## Everyday

```bash
./manage.sh start      # start
./manage.sh stop       # stop
./manage.sh restart    # apply changes from server.env / server.properties
./manage.sh backup     # verified backup (world + mods + config + manifest)
./manage.sh restore    # roll back to a backup
```

See [MANAGER.md](MANAGER.md) for every command and [README.md](README.md) for details and troubleshooting.
