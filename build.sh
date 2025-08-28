#!/bin/bash
set -e

clear

echo ">>> Stopping containers and cleaning up..."

# Stop and remove everything (containers, volumes, networks)
docker compose down -v --remove-orphans

echo ">>> Stopping all running containers..."
docker ps -q | xargs -r docker stop

echo ">>> Removing all containers..."
docker ps -aq | xargs -r docker rm -f

echo ">>> Removing dangling images..."
docker images -f "dangling=true" -q | xargs -r docker rmi -f

echo ">>> Removing unused volumes..."
docker volume ls -q | xargs -r docker volume rm -f

echo ">>> Removing unused networks..."
docker network prune -f

echo ">>> Checking port 80 usage..."
if command -v ss &> /dev/null; then
  sudo ss -tulnp | grep ':80' || echo "Port 80 is free ✅"
else
  sudo lsof -i :80 || echo "Port 80 is free ✅"
fi

echo ">>> Stopping Nginx if running"

sudo systemctl stop nginx
sudo systemctl disable nginx
#sudo systemctl status nginx


echo ">>> Cleanup complete."

# ------------------------------
# Checkout local branch
# -----------------------------
echo ">>> Updating repo..."
git checkout local
git pull


# ------------------------------
# Stop any running containers
# -----------------------------
echo ">>> Updating submodules..."
git submodule update --init --recursive


# ------------------------------
# Stop any running containers
# ------------------------------
echo ">>> Stop existing containers..."
docker compose down


# ------------------------------
# Stop temporary containers
# ------------------------------
docker compose down

# ------------------------------
# Build & start full stack (including nginx with SSL)
# ------------------------------
echo ">>> Build & start full stack..."
docker compose down -v   # stop + remove volumes just in case
docker compose build --no-cache
docker compose up -d


# ------------------------------
# Allow port 80 access
# ------------------------------
echo ">>> Configure port access..."
sudo ufw status
sudo ufw allow 80
sudo ufw allow 443
sudo ufw reload

# ------------------------------
# File & folder permissions
# ------------------------------
echo ">>> Set folder permissions..."
sudo sudo chown -R joe90:www-data dev.sharpishly.com
sudo find dev.sharpishly.com -type d -exec chmod 755 {} \;
sudo find dev.sharpishly.com -type f -exec chmod 644 {} \;
sudo chmod 755 dev.sharpishly.com/website/public/index.php
sudo chmod 777 dev.sharpishly.com/website/env.php


# ------------------------------
# Docker Status
# ------------------------------
echo ">>> Docker status ..."
docker ps -a
#docker logs php_fpm


# ------------------------------
# Add host names
# ------------------------------
echo ">>> Add host names..."
HOSTS_FILE="/etc/hosts"
HOSTNAMES=(
  "sharpishly.dev"
  "dev.sharpishly.dev"
  "live.sharpishly.dev"
  "py.sharpishly.dev"
)

for HOST in "${HOSTNAMES[@]}"; do
    ENTRY="127.0.0.1 $HOST"
    if grep -qE "^[[:space:]]*127\.0\.0\.1[[:space:]]+$HOST(\s|$)" "$HOSTS_FILE"; then
        echo "Entry for $HOST already exists in $HOSTS_FILE"
    else
        echo "Adding entry for $HOST"
        echo "$ENTRY" | sudo tee -a "$HOSTS_FILE" > /dev/null
    fi
done

# ------------------------------
# Testing sharpishly.dev
# ------------------------------
echo ">>> Testing sharpishly.dev..."
curl -k http://sharpishly.dev




