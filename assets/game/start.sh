#!/bin/bash
# Hytale Server Launcher
# This script handles staged updates and starts the server with default arguments.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

while true; do
    APPLIED_UPDATE=false

    # Apply staged update if present
    if [ -f "updater/staging/Server/HytaleServer.jar" ]; then
        echo "[Launcher] Applying staged update..."
        # Only replace update files, preserve config/saves/mods
        cp -f updater/staging/Server/HytaleServer.jar Server/
        [ -f "updater/staging/Server/HytaleServer.aot" ] && cp -f updater/staging/Server/HytaleServer.aot Server/
        [ -d "updater/staging/Server/Licenses" ] && rm -rf Server/Licenses && cp -r updater/staging/Server/Licenses Server/
        [ -f "updater/staging/Assets.zip" ] && cp -f updater/staging/Assets.zip ./
        [ -f "updater/staging/start.sh" ] && cp -f updater/staging/start.sh ./
        [ -f "updater/staging/start.bat" ] && cp -f updater/staging/start.bat ./
        rm -rf updater/staging
        APPLIED_UPDATE=true
    fi

    # Run server from inside Server/ folder so config/backups/etc. are generated there
    cd Server

    # JVM arguments for AOT cache (faster startup)
    JVM_ARGS=""
    if [ -f "HytaleServer.aot" ]; then
        echo "[Launcher] Using AOT cache for faster startup"
        JVM_ARGS="-XX:AOTCache=HytaleServer.aot"
    fi

    # Default server arguments
    # --assets: Assets.zip is in parent directory
    # --backup: Enable periodic backups like singleplayer
    DEFAULT_ARGS="--assets ../Assets.zip --backup --backup-dir backups --backup-frequency 30"

    # Start server and track time
    START_TIME=$(date +%s)
    java $JVM_ARGS -jar HytaleServer.jar $DEFAULT_ARGS "$@"
    EXIT_CODE=$?
    ELAPSED=$(( $(date +%s) - START_TIME ))

    # Return to script dir for next iteration
    cd "$SCRIPT_DIR"

    # Exit code 8 = restart for update
    if [ $EXIT_CODE -eq 8 ]; then
        echo "[Launcher] Restarting to apply update..."
        continue
    fi

    # Warn on crash shortly after update
    if [ $EXIT_CODE -ne 0 ] && [ "$APPLIED_UPDATE" = true ] && [ $ELAPSED -lt 30 ]; then
        echo ""
        echo "[Launcher] ERROR: Server exited with code $EXIT_CODE within ${ELAPSED}s of starting."
        echo "[Launcher] This may indicate the update failed to start correctly."
        echo "[Launcher]"
        echo "[Launcher] Your previous files are in the updater/backup/ folder."
        echo "[Launcher] To rollback: delete Server/ and Assets.zip, then move from updater/backup/"
        echo ""
        # Only prompt if running interactively (has terminal)
        if [ -t 0 ]; then
            read -p "Press Enter to exit..."
        fi
    fi

    exit $EXIT_CODE
done