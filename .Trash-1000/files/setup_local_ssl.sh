#!/bin/bash

# ------------------------------
# Setup Local SSL for *.sharpishly.dev
# ------------------------------

set -e

echo ">>> Setting up local SSL for *.sharpishly.dev..."

# Detect current user dynamically
USER_NAME=$(whoami)
GROUP_NAME=$(id -gn $USER_NAME)
echo ">>> Using user: $USER_NAME:$GROUP_NAME"

# Create certs folder
CERT_DIR="./certs"
if [ ! -d "$CERT_DIR" ]; then
    echo ">>> Creating certs directory: $CERT_DIR"
    mkdir -p "$CERT_DIR"
fi

# File paths
KEY_FILE="$CERT_DIR/sharpishly.dev.key"
CRT_FILE="$CERT_DIR/sharpishly.dev.crt"

# Generate wildcard SSL certificate if it doesn't exist
if [ ! -f "$KEY_FILE" ] || [ ! -f "$CRT_FILE" ]; then
    echo ">>> Generating new wildcard SSL cert for *.sharpishly.dev..."
    openssl req -x509 -nodes -days 365 \
        -newkey rsa:2048 \
        -keyout "$KEY_FILE" \
        -out "$CRT_FILE" \
        -subj "/C=US/ST=Local/L=Local/O=Dev/CN=*.sharpishly.dev"

    echo ">>> Setting ownership and permissions..."
    chown $USER_NAME:$GROUP_NAME "$KEY_FILE" "$CRT_FILE"
    chmod 600 "$KEY_FILE"
    chmod 644 "$CRT_FILE"
else
    echo ">>> SSL certificate already exists at $CRT_FILE"
fi

echo ">>> Local SSL setup complete."
