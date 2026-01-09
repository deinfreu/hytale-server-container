#!/bin/sh
set -eu

# Load dependencies
. "$SCRIPTS_PATH/utils.sh"
. "$SCRIPTS_PATH/hytale/lib/network_logic.sh"

if [ -f "$SERVER_JAR_PATH" ]; then
    log "Checking for Hytale updates..." "$BLUE" "updater"
    
    if [ "$(hytale-downloader check-update)" = "true" ]; then
        if [ "$AUTO_UPDATE" = "true" ]; then
            perform_hytale_download "$SERVER_JAR_PATH"
        else
            log "UPDATE AVAILABLE! Run 'update.sh' manually to apply." "$YELLOW" "updater"
        fi
    else
        log "Server JAR is already the latest version." "$GREEN" "updater"
    fi
fi