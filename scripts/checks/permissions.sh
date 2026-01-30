#!/bin/sh
set -eu

# Load dependencies
. "$SCRIPTS_PATH/utils.sh"

log_section "File Permissions Check"

# Define the game directory
GAME_DIR="${GAME_DIR:-$HOME/game/Server}"

if [ ! -d "$GAME_DIR" ]; then
    log_warning "Game directory not found" "Skipping permissions check."
    return 0
fi

log_step "Setting Server Binary Permissions"
# Make server binaries executable (755)
find "$GAME_DIR" -maxdepth 1 -type f \( -name "*.jar" -o -name "*.aot" \) -exec chmod 755 {} \; 2>/dev/null || true
log_success

log_step "Setting Executable File Permissions"
# Make Assets.zip, start scripts executable (755)
[ -f "$GAME_DIR/Assets.zip" ] && chmod 755 "$GAME_DIR/Assets.zip" 2>/dev/null || true
[ -f "$GAME_DIR/start.sh" ] && chmod 755 "$GAME_DIR/start.sh" 2>/dev/null || true
[ -f "$GAME_DIR/start.bat" ] && chmod 755 "$GAME_DIR/start.bat" 2>/dev/null || true
log_success

log_step "Setting Config File Permissions"
# Set config files to read/write (644)
find "$GAME_DIR" -maxdepth 1 -type f \( -name "*.json" -o -name "*.enc" -o -name "*.bak" \) -exec chmod 644 {} \; 2>/dev/null || true
log_success

log_step "Setting Directory Permissions"
# Set directories to 755
find "$GAME_DIR" -type d -exec chmod 755 {} \; 2>/dev/null || true
log_success

log_step "Setting Ownership"
# Ensure all files are owned by the container user
chown -R container:container "$GAME_DIR" 2>/dev/null || true
log_success

if [ "${DEBUG:-FALSE}" = "TRUE" ]; then
    printf "      ${DIM}↳ Binaries (.jar, .aot):${NC} ${GREEN}755${NC} (rwxr-xr-x)\n"
    printf "      ${DIM}↳ Executables (Assets.zip, start.sh, start.bat):${NC} ${GREEN}755${NC} (rwxr-xr-x)\n"
    printf "      ${DIM}↳ Configs (.json, .enc):${NC} ${GREEN}644${NC} (rw-r--r--)\n"
    printf "      ${DIM}↳ Directories:${NC} ${GREEN}755${NC} (rwxr-xr-x)\n"
    printf "      ${DIM}↳ Owner:${NC} ${GREEN}container:container${NC}\n"
fi
