#!/bin/sh
set -eu

# Load dependencies
. "$SCRIPTS_PATH/utils.sh"

# --- Legacy Path Migration ---
# Moves /home/container/game/* -> /home/container/ when game/Server exists with files
log_section "Migrate Check"

LEGACY_ROOT="/home/container/game"
LEGACY_SERVER_DIR="$LEGACY_ROOT/Server"
TARGET_ROOT="/home/container"

# Only run if game/Server exists and contains at least one file
if [ ! -d "$LEGACY_SERVER_DIR" ] || [ -z "$(ls -A "$LEGACY_SERVER_DIR" 2>/dev/null)" ]; then
    log_step "Legacy /game/Server path"
    printf "${DIM}not found or empty (skip)${NC}\n"
    exit 0
fi

log_step "Legacy /game structure detected"
log_success

# Ensure target Server directory exists
mkdir -p "$TARGET_ROOT/Server"

# Move Server contents
log_step "Move Server/"
if cp -r "$LEGACY_SERVER_DIR/." "$TARGET_ROOT/Server/"; then
    log_success
else
    log_error "Failed to move Server/ contents" "Check permissions on $TARGET_ROOT/Server"
    exit 1
fi

# Move remaining files in game/ root (Assets.zip, start.sh, start.bat, etc.) into Server/
for item in $(ls -A "$LEGACY_ROOT" 2>/dev/null); do
    if [ "$item" = "Server" ]; then
        continue
    fi
    log_step "Move $item"
    if mv "$LEGACY_ROOT/$item" "$TARGET_ROOT/Server/"; then
        log_success
    else
        log_error "Failed to move $item" "Check permissions on $TARGET_ROOT/Server"
        exit 1
    fi
done

# All moves succeeded — remove legacy /game folder
log_step "Remove legacy /game folder"
if rm -rf "$LEGACY_ROOT"; then
    log_success
else
    log_error "Failed to remove $LEGACY_ROOT" "Check permissions"
    exit 1
fi