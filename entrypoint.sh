#!/bin/sh
set -eu

# --- Hytale config default ---


# --- Configuration defaults ---
export SCRIPTS_PATH="/usr/local/bin/scripts"
export SERVER_PORT="${SERVER_PORT:-5520}"
export SERVER_IP="${SERVER_IP:-0.0.0.0}"
export DEBUG="${DEBUG:-FALSE}"
export PROD="${PROD:-FALSE}"
export BASE_DIR="/home/container"
export GAME_DIR="$BASE_DIR/game"
export SERVER_JAR_PATH="$GAME_DIR/Server/HytaleServer.jar"

export XMX="${XMX:-2048M}"
export XMS="${XMS:-128M}"
export DTERM_JLINE="${DTERM_JLINE:-false}"
export DTERM_ANSI="${DTERM_ANSI:-true}"

jvm_args = "-Xms$XMS -Xmx$XMX -Dterminal.jline=$DTERM_JLINE -Dterminal.ansi=$DTERM_ANSI"
export JVM_ARGS="${JVM_ARGS:-$jvm_args}"

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

# --- 2. Initialization ---
# This script handles its own log_section internally
sh "$SCRIPTS_PATH/hytale/hytale_downloader.sh"
sh "$SCRIPTS_PATH/hytale/hytale_config.sh"

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
exec gosu $USER java $JVM_ARGS \
-jar "$SERVER_JAR_PATH" \
--assets "$GAME_DIR/Assets.zip" \
--bind "$SERVER_IP:$SERVER_PORT"
