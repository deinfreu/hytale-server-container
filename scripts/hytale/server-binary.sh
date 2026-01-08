#!/bin/bash

JAR_PATH="/usr/local/lib/hytale-server.jar"
AUTO_UPDATE=${AUTO_UPDATE:-false}

# 1. Check if file exists
if [ ! -f "$JAR_PATH" ]; then
    echo "Hytale server not found. Downloading for the first time..."
    hytale-downloader download --output "$JAR_PATH"
    chmod 444 "$JAR_PATH"
else
    # 2. Check for updates
    echo "Checking for updates..."
    UPDATE_AVAILABLE=$(hytale-downloader check-update)

    if [ "$UPDATE_AVAILABLE" = "true" ]; then
        if [ "$AUTO_UPDATE" = "true" ]; then
            echo "Auto-update enabled. Downloading new version..."
            chmod 644 "$JAR_PATH" # Temporarily allow writing
            hytale-downloader download --output "$JAR_PATH"
            chmod 444 "$JAR_PATH"
        else
            # 3. Interactive Prompt
            echo "****************************************************"
            echo "UPDATE AVAILABLE! Do you want to download it? (y/n)"
            echo "Note: You must be attached to the container terminal."
            echo "****************************************************"
            
            # Read from /dev/tty to ensure it captures user input even in Docker
            read -p "Update now? " -r < /dev/tty
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                chmod 644 "$JAR_PATH"
                hytale-downloader download --output "$JAR_PATH"
                chmod 444 "$JAR_PATH"
            else
                echo "Update skipped. Starting existing version..."
            fi
        fi
    fi
fi