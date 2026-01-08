#!/bin/bash
set -e

# ------------------------------
# TERRARIA + MINECRAFT + PLAYIT.GG SETUP
# ------------------------------

echo "Updating system..."
sudo apt update && sudo apt upgrade -y

echo "Installing required packages..."
sudo apt install -y docker.io docker-compose wget unzip openjdk-17-jre-headless curl nano

# Enable Docker for current user
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER

# ------------------------------
# CREATE SERVER DIRECTORIES
# ------------------------------
mkdir -p ~/game-servers/minecraft-paper
mkdir -p ~/game-servers/terraria
mkdir -p ~/game-servers/playit

# ------------------------------
# TERRARIA SETUP
# ------------------------------
echo "Setting up Terraria server..."
cat > ~/game-servers/terraria/Dockerfile << 'EOF'
FROM rheller/terraria:latest
WORKDIR /config
EOF

# ------------------------------
# MINECRAFT SETUP (Paper + Multiverse)
# ------------------------------
echo "Setting up Minecraft Paper server..."
mkdir -p ~/game-servers/minecraft-paper/plugins

# Download Multiverse-Core plugin
wget -O ~/game-servers/minecraft-paper/plugins/Multiverse-Core.jar \
"https://cdn.modrinth.com/data/NrjtZ5ye/versions/5.4.0/multiverse-core-5.4.0.jar"

# ------------------------------
# PLAYIT.GG SETUP
# ------------------------------
echo "Setting up Playit.gg..."
wget https://github.com/playit-cloud/playit-agent/releases/latest/download/playit-agent-linux-aarch64.zip -O ~/game-servers/playit/playit-agent.zip
unzip ~/game-servers/playit/playit-agent.zip -d ~/game-servers/playit/
chmod +x ~/game-servers/playit/playit-agent

# Create systemd service to run Playit.gg on boot
sudo tee /etc/systemd/system/playit.service > /dev/null << 'EOF'
[Unit]
Description=Playit.gg Tunnel Agent
After=network.target

[Service]
ExecStart=/home/pi/game-servers/playit/playit-agent
Restart=always
User=pi
WorkingDirectory=/home/pi/game-servers/playit

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable playit
sudo systemctl start playit

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
      MEMORY: 4G
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
echo "Playit.gg service started and will run on boot"
echo "Attach to Minecraft console: docker compose attach mc-paper"
echo "Attach to Terraria console: docker compose attach terraria"
