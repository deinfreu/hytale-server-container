#!/bin/bash
set -e

# ==========================================
# ARM64 HOST SETUP FOR HYTALE SERVER
# ==========================================

printf "==================================\n"
printf "ARM64 Host Setup for Hytale Server\n"
printf "==================================\n\n"

arch=$(uname -m)
if [ "$arch" != "aarch64" ] && [ "$arch" != "arm64" ]; then
    printf "Warning: This script is designed for ARM64/aarch64 systems.\n"
    printf "    Detected architecture: %s\n" "$arch"
    read -p "Continue anyway? (y/N) " -n 1 -r
    printf "\n"
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

printf "Architecture: %s\n\n" "$arch"

printf "==========================================\n"
printf "Setup Complete!\n"
printf "==========================================\n\n"
printf "Run the Hytale server container:\n"
printf "  docker compose up -d\n\n"