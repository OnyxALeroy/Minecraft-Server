FROM eclipse-temurin:21-jdk-jammy

# Install base tools
RUN apt-get update && apt-get install -y \
    curl wget unzip jq git \
    && rm -rf /var/lib/apt/lists/*

# Install mrpack-install (The gold standard for .mrpack files)
RUN curl -L -o /usr/local/bin/mrpack-install https://github.com/nothub/mrpack-install/releases/latest/download/mrpack-install-linux \
    && chmod +x /usr/local/bin/mrpack-install

# Install rcon-cli (used by ./manage.sh to send console commands)
ARG RCON_CLI_VERSION=1.7.7
RUN ARCH=$(dpkg --print-architecture) \
    && curl -fsSL "https://github.com/itzg/rcon-cli/releases/download/${RCON_CLI_VERSION}/rcon-cli_${RCON_CLI_VERSION}_linux_${ARCH}.tar.gz" \
    | tar -xz -C /usr/local/bin rcon-cli

WORKDIR /minecraft

# Copy the startup script into the image
COPY start.sh /minecraft/start.sh
RUN chmod +x /minecraft/start.sh

# Expose the standard port
EXPOSE 25565

# Run the script
CMD ["/minecraft/start.sh"]
