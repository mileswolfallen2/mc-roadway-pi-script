#!/bin/bash
set -e

# ------------------------------
# TERRARIA + MINECRAFT SERVER SETUP
# ------------------------------

echo "Updating system..."
sudo apt update && sudo apt upgrade -y

echo "Installing Docker & Docker Compose..."
sudo apt install -y docker.io docker-compose wget unzip openjdk-17-jre-headless

# Enable Docker for current user
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER

# Create server directories
mkdir -p ~/game-servers/minecraft-paper
mkdir -p ~/game-servers/terraria

# ------------------------------
# TERRARIA SETUP
# ------------------------------
echo "Setting up Terraria server..."
# Using official rheller/terraria image for ARM
cat > ~/game-servers/terraria/Dockerfile << 'EOF'
FROM rheller/terraria:latest
WORKDIR /config
EOF

# ------------------------------
# MINECRAFT SETUP (Paper + Multiverse)
# ------------------------------
echo "Setting up Minecraft Paper server..."
mkdir -p ~/game-servers/minecraft-paper/plugins

# Download Multiverse-Core plugin (via Modrinth)
wget -O ~/game-servers/minecraft-paper/plugins/Multiverse-Core.jar \
"https://cdn.modrinth.com/data/NrjtZ5ye/versions/5.4.0/multiverse-core-5.4.0.jar"

# ------------------------------
# DOCKER COMPOSE FILE
# ------------------------------
echo "Creating docker-compose.yml..."
cat > ~/game-servers/docker-compose.yml << 'EOF'
version: "3.9"
services:
  terraria:
    image: rheller/terraria:latest
    container_name: terraria
    ports:
      - "7777:7777/udp"
    volumes:
      - ./terraria:/config
    restart: unless-stopped

  mc-paper:
    image: itzg/minecraft-server:latest
    container_name: mc-paper
    environment:
      EULA: "TRUE"
      TYPE: PAPER
      VERSION: 1.21.11
      MEMORY: 4G   # <-- Give Minecraft 4 GB RAM
    ports:
      - "25565:25565"
      - "25575:25575"  # RCON
    volumes:
      - ./minecraft-paper:/data
    restart: unless-stopped
EOF

# ------------------------------
# START SERVERS
# ------------------------------
echo "Starting servers..."
cd ~/game-servers
docker compose up -d

echo "All done!"
echo "Terraria port: 7777 (UDP)"
echo "Minecraft Paper port: 25565 (4 GB RAM)"
echo "You can attach to Minecraft console: docker compose attach mc-paper"
echo "You can attach to Terraria console: docker compose attach terraria"
