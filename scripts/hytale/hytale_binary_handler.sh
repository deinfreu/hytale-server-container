#!/bin/sh
set -eu

# Load dependencies
. "$SCRIPTS_PATH/utils.sh"

log_section "Hytale Binary Handler"
log_step "Hytale Server Binary Check"

# Check for existing update package first (manual download or update)
ZIP_FILE=$(ls "$BASE_DIR"/[0-9][0-9][0-9][0-9].[0-9][0-9].[0-9][0-9]*.zip 2>/dev/null | head -n 1)

if [ -n "$ZIP_FILE" ]; then
    # Update available - run update script
    sh "$SCRIPTS_PATH/hytale/hytale_update.sh"
elif [ ! -f "$SERVER_JAR_PATH" ]; then
    # No jar and no zip - run fresh download script
    sh "$SCRIPTS_PATH/hytale/hytale_download.sh"
else
    # Server already installed, no updates
    log_success
    printf "      ${DIM}↳ Info:${NC} Server up-to-date. Skipping extraction.\n"
    printf "      ${DIM}↳ Note:${NC} Place YYYY.MM.DD*.zip in %s to trigger update.\n" "$BASE_DIR"
fi