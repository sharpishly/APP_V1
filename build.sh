#!/bin/bash
# build.sh - Local environment reset + SSL bootstrap + stack rebuild
set -e
clear

# Detect current user and group dynamically
USER_NAME=$(whoami)
GROUP_NAME=$(id -gn)
echo ">>> Running as $USER_NAME:$GROUP_NAME"

# ------------------------------
# Install debugging tools if not present
# ------------------------------
echo ">>> Checking and installing debugging tools..."
TOOLS=("net-tools" "iproute2" "htop" "curl" "watch" "jq" "logrotate" "openssl" "doxygen")
for TOOL in "${TOOLS[@]}"; do
    if ! dpkg -s "$TOOL" >/dev/null 2>&1; then
        echo ">>> Installing $TOOL..."
        sudo apt-get update && sudo apt-get install -y "$TOOL"
    else
        echo ">>> $TOOL already installed"
    fi
done

# ------------------------------
# Create debug directory
# ------------------------------
DEBUG_DIR="debug"
mkdir -p "$DEBUG_DIR"
DEBUG_FILE="$DEBUG_DIR/index.html"

# Start HTML output
cat <<EOF > "$DEBUG_FILE"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Debug Report - sharpishly.dev</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #333; }
        h2 { color: #555; }
        pre { background: #f4f4f4; padding: 10px; border-radius: 5px; }
    </style>
</head>
<body>
    <h1>Debug Report - sharpishly.dev</h1>
    <h2>Generated: $(date)</h2>
EOF

# ------------------------------
# Setup local SSL for *.sharpishly.dev
# ------------------------------
echo ">>> Setting up local SSL for *.sharpishly.dev..."
CERT_DIR="./certs"
if [ ! -d "$CERT_DIR" ]; then
    echo ">>> Creating certs directory: $CERT_DIR"
    mkdir -p "$CERT_DIR"
fi
KEY_FILE="$CERT_DIR/sharpishly.dev.key"
CRT_FILE="$CERT_DIR/sharpishly.dev.crt"
if [ ! -f "$KEY_FILE" ] || [ ! -f "$CRT_FILE" ]; then
    echo ">>> Generating new wildcard SSL cert for *.sharpishly.dev..."
    openssl req -x509 -nodes -days 365 \
        -newkey rsa:2048 \
        -keyout "$KEY_FILE" \
        -out "$CRT_FILE" \
        -subj "/C=US/ST=Local/L=Local/O=Dev/CN=*.sharpishly.dev"
    echo ">>> Setting ownership and permissions..."
    chown "$USER_NAME:$GROUP_NAME" "$KEY_FILE" "$CRT_FILE"
    chmod 600 "$KEY_FILE"
    chmod 644 "$CRT_FILE"
else
    echo ">>> SSL certificate already exists at $CRT_FILE"
fi
echo "<h2>SSL Certificate Files</h2><pre>" >> "$DEBUG_FILE"
ls -l "$CERT_DIR" >> "$DEBUG_FILE"
echo "</pre>" >> "$DEBUG_FILE"

# ------------------------------
# Docker cleanup
# ------------------------------
echo ">>> Stopping containers and cleaning up..."
docker compose down -v --remove-orphans
echo ">>> Removing dangling images..."
docker images -f "dangling=true" -q | xargs -r docker rmi -f
echo ">>> Removing unused volumes..."
docker volume ls -q | xargs -r docker volume rm -f
echo ">>> Removing unused networks..."
docker network prune -f

# ------------------------------
# Check port usage
# ------------------------------
echo ">>> Checking port 80 and 443 usage..."
echo "<h2>Port Usage</h2><pre>" >> "$DEBUG_FILE"
if command -v ss &> /dev/null; then
    sudo ss -tulnp | grep -E ':80|:443' || echo "Ports 80 and 443 are free ✅" >> "$DEBUG_FILE"
else
    sudo netstat -tulnp | grep -E ':80|:443' || echo "Ports 80 and 443 are free ✅" >> "$DEBUG_FILE"
fi
echo "</pre>" >> "$DEBUG_FILE"

echo ">>> Stopping host Nginx if running..."
sudo systemctl stop nginx || true
sudo systemctl disable nginx || true

# ------------------------------
# Git updates
# ------------------------------
echo ">>> Updating repo..."
git checkout local
git pull
echo ">>> Updating submodules..."
git submodule update --init --recursive

# ------------------------------
# Config refresh
# ------------------------------
echo ">>> Creating Nginx from local resource..."
rm -rf nginx
mkdir -p nginx/conf.d
cp local-nginx/sharpishly.conf nginx/conf.d/sharpishly.conf
chown -R "$USER_NAME:$GROUP_NAME" nginx
echo "<h2>Nginx Config Verification</h2><pre>" >> "$DEBUG_FILE"
diff nginx/conf.d/sharpishly.conf local-nginx/sharpishly.conf || echo "Nginx config matches local-nginx/sharpishly.conf" >> "$DEBUG_FILE"
echo "</pre>" >> "$DEBUG_FILE"

echo ">>> Creating docker-compose.yml from local resource..."
rm -f docker-compose.yml
cp local-docker-compose.yml docker-compose.yml
chown "$USER_NAME:$GROUP_NAME" docker-compose.yml

# ------------------------------
# Generate Doxygen documentation
# ------------------------------
echo ">>> Generating Doxygen documentation..."
if [ -d "dev.sharpishly.com" ]; then
    doxygen -g - > Doxyfile
    echo "OUTPUT_DIRECTORY = $DEBUG_DIR/doxygen" >> Doxyfile
    echo "INPUT = dev.sharpishly.com" >> Doxyfile
    echo "RECURSIVE = YES" >> Doxyfile
    echo "GENERATE_HTML = YES" >> Doxyfile
    doxygen Doxyfile
    rm Doxyfile
    echo "<h2>Doxygen Documentation</h2><pre>" >> "$DEBUG_FILE"
    echo "Doxygen output generated at $DEBUG_DIR/doxygen" >> "$DEBUG_FILE"
    echo "</pre>" >> "$DEBUG_FILE"
else
    echo ">>> dev.sharpishly.com directory not found, skipping Doxygen"
    echo "<h2>Doxygen Documentation</h2><pre>dev.sharpishly.com directory not found</pre>" >> "$DEBUG_FILE"
fi

# ------------------------------
# Build & start full stack
# ------------------------------
echo ">>> Build & start full stack..."
docker compose build --no-cache
docker compose up -d

# ------------------------------
# Capture container status
# ------------------------------
echo "<h2>Container Status</h2><pre>" >> "$DEBUG_FILE"
docker ps -a >> "$DEBUG_FILE"
echo "</pre>" >> "$DEBUG_FILE"

# ------------------------------
# Capture Nginx logs
# ------------------------------
echo "<h2>Nginx Logs (Last 50 Lines)</h2><pre>" >> "$DEBUG_FILE"
docker logs nginx_proxy --tail 50 2>&1 >> "$DEBUG_FILE"
echo "</pre>" >> "$DEBUG_FILE"

# ------------------------------
# Capture PHP-FPM logs
# ------------------------------
echo "<h2>PHP-FPM Logs (Last 50 Lines)</h2><pre>" >> "$DEBUG_FILE"
docker logs php_fpm --tail 50 2>&1 >> "$DEBUG_FILE"
echo "</pre>" >> "$DEBUG_FILE"

# ------------------------------
# Test Nginx configuration
# ------------------------------
echo "<h2>Nginx Config Test</h2><pre>" >> "$DEBUG_FILE"
docker exec nginx_proxy nginx -t 2>&1 >> "$DEBUG_FILE"
echo "</pre>" >> "$DEBUG_FILE"

# ------------------------------
# Test PHP-FPM connectivity
# ------------------------------
echo "<h2>PHP-FPM Connectivity Test</h2><pre>" >> "$DEBUG_FILE"
docker exec nginx_proxy curl -v http://php:9000 2>&1 >> "$DEBUG_FILE"
echo "</pre>" >> "$DEBUG_FILE"

# ------------------------------
# Firewall setup (idempotent)
# ------------------------------
echo ">>> Configure firewall rules..."
sudo ufw status | grep -q "80/tcp" || sudo ufw allow 80
sudo ufw status | grep -q "443/tcp" || sudo ufw allow 443
sudo ufw reload
echo "<h2>Firewall Status</h2><pre>" >> "$DEBUG_FILE"
sudo ufw status >> "$DEBUG_FILE"
echo "</pre>" >> "$DEBUG_FILE"

# ------------------------------
# File & folder permissions
# ------------------------------
echo ">>> Set folder permissions..."
chown -R "$USER_NAME:www-data" dev.sharpishly.com
find dev.sharpishly.com -type d -exec chmod 755 {} \;
find dev.sharpishly.com -type f -exec chmod 644 {} \;
chmod 755 dev.sharpishly.com/website/public/index.php
chmod 660 dev.sharpishly.com/website/env.php

# ------------------------------
# Docker status
# ------------------------------
echo ">>> Docker status ..."
docker ps -a

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
# Testing HTTPS
# ------------------------------
echo ">>> Testing sharpishly.dev..."
echo "<h2>HTTPS Test (sharpishly.dev)</h2><pre>" >> "$DEBUG_FILE"
curl -vk https://sharpishly.dev 2>&1 >> "$DEBUG_FILE"
echo "</pre>" >> "$DEBUG_FILE"

# Close HTML
echo "</body></html>" >> "$DEBUG_FILE"
echo ">>> Debug report generated at $DEBUG_FILE"