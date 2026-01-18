FROM openjdk:21-jdk-slim

# Install required packages
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    unzip \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /minecraft

# Create directories for server and mods
RUN mkdir -p /minecraft/server /minecraft/mods /minecraft/config /minecraft/modrinth

# Download and install Modrinth App (CLI version)
RUN wget -O /usr/local/bin/modrinth https://github.com/modrinth/cli/releases/latest/download/modrinth-linux-amd64 \
    && chmod +x /usr/local/bin/modrinth

# Copy startup script
COPY start-server.sh /minecraft/start-server.sh
RUN chmod +x /minecraft/start-server.sh

# Expose Minecraft server port
EXPOSE 25565

# Set environment variables
ENV MINECRAFT_VERSION=latest
ENV MEMORY_SIZE=4G
ENV SERVER_JAR=server.jar

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:25565 || exit 1

# Start the server
CMD ["/minecraft/start-server.sh"]