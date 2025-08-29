#!/bin/bash

# ============================
# Script to generate a self-signed SSL certificate
# ============================

# --- Step 0: Define filenames and output directory ---
CERTS_DIR="certs"
CRT_FILE_NAME="sharpishly.dev.crt"
KEY_FILE_NAME="sharpishly.dev.key"

CRT_FILE="$CERTS_DIR/$CRT_FILE_NAME"
KEY_FILE="$CERTS_DIR/$KEY_FILE_NAME"

# Define the common name for the certificate
DOMAIN="sharpishly.dev"

# --- Step 1: Check for OpenSSL installation ---
echo "Checking for OpenSSL..."

if ! command -v openssl &> /dev/null; then
    echo "OpenSSL is not installed. Attempting to install it..."
    OS=$(uname -s)
    case "$OS" in
        Linux*)
            if command -v apt-get &> /dev/null; then
                sudo apt-get update && sudo apt-get install -y openssl
            elif command -v yum &> /dev/null; then
                sudo yum install -y openssl
            else
                echo "Could not determine Linux package manager. Please install OpenSSL manually."
                exit 1
            fi
            ;;
        Darwin*)
            if command -v brew &> /dev/null; then
                brew install openssl
            else
                echo "Homebrew is not installed. Please install it to install OpenSSL."
                exit 1
            fi
            ;;
        *)
            echo "Unsupported operating system. Please install OpenSSL manually."
            exit 1
            ;;
    esac
else
    echo "OpenSSL is already installed."
fi

# --- Step 2: Create the output directory if it doesn't exist ---
mkdir -p "$CERTS_DIR"

# --- Step 3: Generate the self-signed certificate and key if missing ---
if [[ -f "$CRT_FILE" && -f "$KEY_FILE" ]]; then
    echo "Certificate and key files already exist in '$CERTS_DIR/'. Skipping creation."
else
    echo "Generating new SSL certificate for $DOMAIN..."
    echo "Auto-completing fields: C=US, ST=California, L=Mountain View, O=Self-Signed, CN=$DOMAIN"

    openssl req -x509 -newkey rsa:4096 \
        -keyout "$KEY_FILE" \
        -out "$CRT_FILE" \
        -days 365 \
        -nodes \
        -subj "/C=US/ST=California/L=Mountain View/O=Self-Signed/CN=$DOMAIN"

    if [[ $? -eq 0 ]]; then
        echo ""
        echo "Successfully created:"
        echo "  - $CRT_FILE (certificate)"
        echo "  - $KEY_FILE (private key)"
        echo ""
        echo "You can move these files to a secure location (e.g., /etc/nginx/ssl/) and update your Nginx configuration."
    else
        echo "An error occurred during certificate generation."
        exit 1
    fi
fi


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
git stash
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
# Creating Nginx from local resourse
# ------------------------------
echo ">>> Creating Nginx from local resourse..."
sudo rm -R nginx
sudo cp -R local-nginx/ nginx 
sudo chown -R joe90:joe90 nginx


# ------------------------------
# Creating docker-compose.yml from local resource
# ------------------------------
echo ">>> Creating docker-compose.yml from local resource..."
sudo rm docker-compose.yml
sudo cp local-docker-compose.yml docker-compose.yml 
sudo chown joe90:joe90 docker-compose.yml


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
  "docs.sharpishly.dev"
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
# Testing http://sharpishly.dev
# ------------------------------
echo ">>> Testing sharpishly.dev..."
curl -k http://sharpishly.dev

# ------------------------------
# Testing https://sharpishly.dev
# ------------------------------
echo ">>> Testing sharpishly.dev..."
curl -k https://sharpishly.dev




