#!/bin/sh
set -eu

# --- Configuration defaults ---
export SCRIPTS_PATH="/usr/local/bin/scripts"
export SERVER_PORT="${SERVER_PORT:-5520}"
export SERVER_IP="${SERVER_IP:-0.0.0.0}"
export DEBUG="${DEBUG:-FALSE}"
export PROD="${PROD:-FALSE}"
export JAVA_ARGS="${JAVA_ARGS:-}"
export BASE_DIR="/home/container"
export GAME_DIR="$BASE_DIR/game"
export SERVER_JAR_PATH="$GAME_DIR/Server/HytaleServer.jar"
export CACHE="${CACHE:-FALSE}"

# --- Hytale specific environment variables ---
export HYTALE_ACCEPT_EARLY_PLUGINS="${HYTALE_ACCEPT_EARLY_PLUGINS:-FALSE}"
export HYTALE_ALLOW_OP="${HYTALE_ALLOW_OP:-FALSE}"
export HYTALE_AUTH_MODE="${HYTALE_AUTH_MODE:-FALSE}"
export HYTALE_BACKUP="${HYTALE_BACKUP:-FALSE}"
export HYTALE_BACKUP_FREQUENCY="${HYTALE_BACKUP_FREQUENCY:-}"

# Initialize flags as empty strings
export HYTALE_CACHE_FLAG=""
export HYTALE_ACCEPT_EARLY_PLUGINS_FLAG=""
export HYTALE_ALLOW_OP_FLAG=""
export HYTALE_AUTH_MODE_FLAG=""
export HYTALE_BACKUP_FLAG=""
export HYTALE_BACKUP_FREQUENCY_FLAG=""
export HYTALE_QUIET_FLAGS=""

# Load utilities
. "$SCRIPTS_PATH/utils.sh"

# --- 1. Audit Suite ---
log_section "Audit Suite"

# Run Security and Network checks only if DEBUG is TRUE
if [ "${DEBUG:-FALSE}" = "TRUE" ]; then
    sh "$SCRIPTS_PATH/checks/security.sh"
    sh "$SCRIPTS_PATH/checks/network.sh"
else
    printf "${DIM}System debug skipped (DEBUG=FALSE)${NC}\n"
fi

# Run Production readiness check only if PROD is TRUE
if [ "${PROD:-FALSE}" = "TRUE" ]; then
    sh "$SCRIPTS_PATH/checks/prod.sh"
else
    printf "${DIM}Production audit skipped (PROD=FALSE)${NC}\n"
fi

# Check if the server is ARM64 if so then give a warning message.
# 1. Check for ARM64 Architecture
ARCH=$(uname -m)
if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    echo "############################################################"
    echo "  WARNING: UNSUPPORTED ARCHITECTURE DETECTED"
    echo "############################################################"
    echo " Architecture: $ARCH"
    echo ""
    echo " Hytale-Downloader only works for x86_64 at the moment."
    echo ""
    echo " Status: Waiting for Hytale to release the native ARM64"
    echo "         'hytale-downloader' binary. see the docs."
    echo "############################################################"
fi

# --- 2. Initialization ---
# This script handles its own log_section internally
sh "$SCRIPTS_PATH/hytale/hytale_downloader.sh"
sh "$SCRIPTS_PATH/hytale/hytale_config.sh"
sh "$SCRIPTS_PATH/hytale/hytale_flags.sh"

# --- 3. Startup Preparation ---
log_section "Process Execution"
log_step "Finalizing Environment"

# Ensure we are in the correct directory
cd "$BASE_DIR"
log_success

# --- 4. Execution ---
printf "\n${BOLD}${CYAN}🚀 Launching Hytale Server...${NC}\n\n"

# Execute the Java command.
# Using exec ensures Java becomes PID 1, allowing it to receive shutdown signals properly.
# Execute the Java command with the new flags added
exec gosu $USER java $JAVA_ARGS \
    -Dterminal.jline=false \
    -Dterminal.ansi=true \
    $HYTALE_CACHE_FLAG \
    $HYTALE_ACCEPT_EARLY_PLUGINS_FLAG \
    $HYTALE_ALLOW_OP_FLAG \
    $HYTALE_AUTH_MODE_FLAG \
    $HYTALE_BACKUP_FLAG \
    $HYTALE_BACKUP_FREQUENCY_FLAG \
    $HYTALE_QUIET_FLAGS \
    -jar "$SERVER_JAR_PATH" \
    --assets "$GAME_DIR/Assets.zip" \
    --bind "$SERVER_IP:$SERVER_PORT"