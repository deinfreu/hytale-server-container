#!/bin/sh
set -eu

# Force line buffering for TrueNAS Scale log compatibility
export PYTHONUNBUFFERED=1
stdbuf -oL -eL true 2>/dev/null && USE_STDBUF=true || USE_STDBUF=false

# --- Configuration defaults ---
export SCRIPTS_PATH="/usr/local/bin/scripts"
export SERVER_PORT="${SERVER_PORT:-5520}"
export SERVER_IP="${SERVER_IP:-0.0.0.0}"
export DEBUG="${DEBUG:-FALSE}"
export PROD="${PROD:-FALSE}"
export JAVA_ARGS="${JAVA_ARGS:-}"
export TZ="${TZ:-UTC}"
export BASE_DIR="/home/container"
export GAME_DIR="$BASE_DIR/game"
export SERVER_JAR_PATH="$GAME_DIR/Server/HytaleServer.jar"
export CACHE="${CACHE:-FALSE}"
export UID="${UID:-1000}"
export GID="${GID:-1000}"
export NO_COLOR="${NO_COLOR:-FALSE}"

# --- Hytale specific environment variables ---
export HYTALE_PATCHLINE="${HYTALE_PATCHLINE:-release}"
export HYTALE_CACHE="${HYTALE_CACHE:-false}"
export HYTALE_CACHE_DIR="${HYTALE_CACHE_DIR:-$GAME_DIR/Server/HytaleServer.aot}"
export HYTALE_ACCEPT_EARLY_PLUGINS="${HYTALE_ACCEPT_EARLY_PLUGINS:-FALSE}"
export HYTALE_ALLOW_OP="${HYTALE_ALLOW_OP:-FALSE}"
export HYTALE_AUTH_MODE="${HYTALE_AUTH_MODE:-}"
export HYTALE_BACKUP="${HYTALE_BACKUP:-FALSE}"
export HYTALE_BACKUP_DIR="${HYTALE_BACKUP_DIR:-./backups}"
export HYTALE_BACKUP_FREQUENCY="${HYTALE_BACKUP_FREQUENCY:-}"
export HYTALE_BACKUP_MAX_COUNT="${HYTALE_BACKUP_MAX_COUNT:-}"
export HYTALE_BARE="${HYTALE_BARE:-FALSE}"
export HYTALE_BOOT_COMMAND="${HYTALE_BOOT_COMMAND:-}"
export HYTALE_CLIENT_PID="${HYTALE_CLIENT_PID:-}"
export HYTALE_DISABLE_ASSET_COMPARE="${HYTALE_DISABLE_ASSET_COMPARE:-FALSE}"
export HYTALE_DISABLE_CPB_BUILD="${HYTALE_DISABLE_CPB_BUILD:-FALSE}"
export HYTALE_DISABLE_FILE_WATCHER="${HYTALE_DISABLE_FILE_WATCHER:-FALSE}"
export HYTALE_DISABLE_SENTRY="${HYTALE_DISABLE_SENTRY:-FALSE}"
export HYTALE_EARLY_PLUGINS="${HYTALE_EARLY_PLUGINS:-}"
export HYTALE_EVENT_DEBUG="${HYTALE_EVENT_DEBUG:-FALSE}"
export HYTALE_FORCE_NETWORK_FLUSH="${HYTALE_FORCE_NETWORK_FLUSH:-}"
export HYTALE_GENERATE_SCHEMA="${HYTALE_GENERATE_SCHEMA:-FALSE}"
export HYTALE_IDENTITY_TOKEN="${HYTALE_IDENTITY_TOKEN:-}"
export HYTALE_LOG="${HYTALE_LOG:-}"
export HYTALE_MIGRATE_WORLDS="${HYTALE_MIGRATE_WORLDS:-}"
export HYTALE_MIGRATIONS="${HYTALE_MIGRATIONS:-}"
export HYTALE_MODS="${HYTALE_MODS:-}"
export HYTALE_OWNER_NAME="${HYTALE_OWNER_NAME:-}"
export HYTALE_OWNER_UUID="${HYTALE_OWNER_UUID:-}"
export HYTALE_PREFAB_CACHE="${HYTALE_PREFAB_CACHE:-}"
export HYTALE_SESSION_TOKEN="${HYTALE_SESSION_TOKEN:-}"
export HYTALE_SHUTDOWN_AFTER_VALIDATE="${HYTALE_SHUTDOWN_AFTER_VALIDATE:-FALSE}"
export HYTALE_SINGLEPLAYER="${HYTALE_SINGLEPLAYER:-FALSE}"
export HYTALE_TRANSPORT="${HYTALE_TRANSPORT:-}"
export HYTALE_UNIVERSE="${HYTALE_UNIVERSE:-}"
export HYTALE_VALIDATE_ASSETS="${HYTALE_VALIDATE_ASSETS:-FALSE}"
export HYTALE_VALIDATE_PREFABS="${HYTALE_VALIDATE_PREFABS:-}"
export HYTALE_VALIDATE_WORLD_GEN="${HYTALE_VALIDATE_WORLD_GEN:-FALSE}"
export HYTALE_VERSION="${HYTALE_VERSION:-FALSE}"
export HYTALE_WORLD_GEN="${HYTALE_WORLD_GEN:-}"

# --- CurseForge Mod Downloader (no API key required!) ---
export CURSEFORGE_MOD_IDS="${CURSEFORGE_MOD_IDS:-}"
export HYTALE_MOD_DIR="${HYTALE_MOD_DIR:-$BASE_DIR/mods}"

# Load utilities
. "$SCRIPTS_PATH/utils.sh"

ARCH=$(uname -m)
if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    printf "############################################################\n"
    printf "  WARNING: UNSUPPORTED ARCHITECTURE DETECTED\n"
    printf "############################################################\n"
    printf " Architecture: %s\n\n" "$ARCH"
    printf " Hytale-Downloader only works for x86_64 at the moment.\n"
    printf " Status: Waiting for Hytale to release the native ARM64 binary.\n"
    printf "############################################################\n"
fi

# --- 1. Initialization ---
# CRITICAL ORDER: Downloader must run BEFORE config management. The audit suite must run AFTER this step.
sh "$SCRIPTS_PATH/hytale/hytale_downloader.sh"
sh "$SCRIPTS_PATH/hytale/curseforge_mods.sh"
sh "$SCRIPTS_PATH/hytale/hytale_config.sh"
. "$SCRIPTS_PATH/hytale/hytale_options.sh"

# --- 1. Audit Suite ---
log_section "Audit Suite"

if [ "$DEBUG" = "TRUE" ]; then
    sh "$SCRIPTS_PATH/checks/security.sh"
    sh "$SCRIPTS_PATH/checks/network.sh"
else
    echo -e "${DIM}System debug skipped (DEBUG=FALSE)${NC}"
fi

if [ "$PROD" = "TRUE" ]; then
    sh "$SCRIPTS_PATH/checks/prod.sh"
else
    echo -e "${DIM}Production audit skipped (PROD=FALSE)${NC}"
fi

# --- 3. Startup Preparation ---
log_section "Process Execution"
log_step "Finalizing Environment"
cd "$BASE_DIR"
log_success

# --- 4. Execution ---
printf "\n${BOLD}${CYAN}🚀 Launching Hytale Server...${NC}\n\n"

# Determine if we need to switch users
CURRENT_UID=$(id -u)
if [ "$CURRENT_UID" = "0" ]; then
    # Running as root, need to drop privileges
    if command -v gosu >/dev/null 2>&1; then
        RUNTIME="gosu $UID:$GID"
    elif command -v su-exec >/dev/null 2>&1; then
        RUNTIME="su-exec $UID:$GID"
    else
        RUNTIME=""
    fi
else
    # Already running as non-root, no need to switch
    RUNTIME=""
fi

# Execute Java server as non-root user
exec $RUNTIME java $JAVA_ARGS \
    -Duser.timezone="$TZ" \
    -Dterminal.jline=false \
    -Dterminal.ansi=true \
    -jar "$SERVER_JAR_PATH" \
    $HYTALE_ACCEPT_EARLY_PLUGINS_OPT \
    $HYTALE_ALLOW_OP_OPT \
    $HYTALE_AUTH_MODE_OPT \
    $HYTALE_BACKUP_OPT \
    $HYTALE_BACKUP_DIR_OPT \
    $HYTALE_BACKUP_FREQUENCY_OPT \
    $HYTALE_BACKUP_MAX_COUNT_OPT \
    $HYTALE_BARE_OPT \
    $HYTALE_BOOT_COMMAND_OPT \
    $HYTALE_CLIENT_PID_OPT \
    $HYTALE_DISABLE_ASSET_COMPARE_OPT \
    $HYTALE_DISABLE_CPB_BUILD_OPT \
    $HYTALE_DISABLE_FILE_WATCHER_OPT \
    $HYTALE_DISABLE_SENTRY_OPT \
    $HYTALE_EARLY_PLUGINS_OPT \
    $HYTALE_EVENT_DEBUG_OPT \
    $HYTALE_FORCE_NETWORK_FLUSH_OPT \
    $HYTALE_GENERATE_SCHEMA_OPT \
    $HYTALE_IDENTITY_TOKEN_OPT \
    $HYTALE_LOG_OPT \
    $HYTALE_MIGRATE_WORLDS_OPT \
    $HYTALE_MIGRATIONS_OPT \
    $HYTALE_MODS_OPT \
    $HYTALE_OWNER_NAME_OPT \
    $HYTALE_OWNER_UUID_OPT \
    $HYTALE_PREFAB_CACHE_OPT \
    $HYTALE_SESSION_TOKEN_OPT \
    $HYTALE_SHUTDOWN_AFTER_VALIDATE_OPT \
    $HYTALE_SINGLEPLAYER_OPT \
    $HYTALE_TRANSPORT_OPT \
    $HYTALE_UNIVERSE_OPT \
    $HYTALE_VALIDATE_ASSETS_OPT \
    $HYTALE_VALIDATE_PREFABS_OPT \
    $HYTALE_VALIDATE_WORLD_GEN_OPT \
    $HYTALE_VERSION_OPT \
    $HYTALE_WORLD_GEN_OPT \
    --assets "$GAME_DIR/Assets.zip" \
    --bind "$SERVER_IP:$SERVER_PORT"