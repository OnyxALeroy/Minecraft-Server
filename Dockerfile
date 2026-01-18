FROM eclipse-temurin:21-jdk-jammy

# Install base tools
RUN apt-get update && apt-get install -y \
    curl wget unzip jq git \
    && rm -rf /var/lib/apt/lists/*

# Install mrpack-install (The gold standard for .mrpack files)
RUN curl -L -o /usr/local/bin/mrpack-install https://github.com/nothub/mrpack-install/releases/latest/download/mrpack-install-linux \
    && chmod +x /usr/local/bin/mrpack-install

WORKDIR /minecraft

# Copy the startup script into the image
COPY start.sh /minecraft/start.sh
RUN chmod +x /minecraft/start.sh

# Expose the standard port
EXPOSE 25565

# Run the script
CMD ["/minecraft/start.sh"]
