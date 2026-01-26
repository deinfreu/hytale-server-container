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
export HYTALE_HELP="${HYTALE_HELP:-FA}"
export HYTALE_CACHE="${HYTALE_CACHE:-FALSE}"
export HYTALE_CACHE_DIR="${HYTALE_CACHE_DIR:-$GAME_DIR/Server/HytaleServer.aot}"
export HYTALE_ACCEPT_EARLY_PLUGINS="${HYTALE_ACCEPT_EARLY_PLUGINS:-FALSE}"
export HYTALE_ALLOW_OP="${HYTALE_ALLOW_OP:-FALSE}"
export HYTALE_AUTH_MODE="${HYTALE_AUTH_MODE:-}"
export HYTALE_AUTH_READY_PATTERN="${HYTALE_AUTH_READY_PATTERN:-Hytale Server Booted}"
export HYTALE_AUTH_READY_ALT_PATTERN="${HYTALE_AUTH_READY_ALT_PATTERN:-No server tokens configured. Use /auth login to authenticate.}"
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
export RUN_AUTO_AUTH="${RUN_AUTO_AUTH:-TRUE}"

# Load utilities
. "$SCRIPTS_PATH/utils.sh"

ARCH=$(uname -m)
if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    printf "\n${RED}############################################################${NC}\n"
    printf "${RED}  WARNING: UNSUPPORTED ARCHITECTURE DETECTED${NC}\n"
    printf "${RED}############################################################${NC}\n"
    printf "${RED} Architecture:${NC} %s\n" "$ARCH"
    printf "${RED} Status:${NC} Waiting for Hytale to release the native ARM64 binary.\n"
    printf "${RED}############################################################${NC}\n\n"
fi

# --- 1. Initialization ---
# CRITICAL ORDER: Downloader must run BEFORE config management. The audit suite must run AFTER this step.
sh "$SCRIPTS_PATH/hytale/hytale_downloader.sh"
sh "$SCRIPTS_PATH/hytale/hytale_config.sh"
. "$SCRIPTS_PATH/hytale/hytale_options.sh"

# --- 1. Audit Suite ---
log_section "Audit Suite"

if [ "$DEBUG" = "TRUE" ]; then
    sh "$SCRIPTS_PATH/checks/security.sh"
    sh "$SCRIPTS_PATH/checks/network.sh"
else
    printf "${DIM}System debug skipped (DEBUG=FALSE)${NC}\n"
fi

if [ "$PROD" = "TRUE" ]; then
    sh "$SCRIPTS_PATH/checks/prod.sh"
else
    printf "${DIM}Production audit skipped (PROD=FALSE)${NC}\n"
fi

# --- 3. Startup Preparation ---
log_section "Process Execution"
log_step "Finalizing Environment"
cd "$BASE_DIR"
log_success

# --- 4. Execution ---
log_section "Launching Hytale Server"

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

# Preload auth commands into the server console after the server signals readiness
# Skip auto-auth if credentials are already persisted AND hardware ID matches
log_section "Authentication Management"

AUTH_PIPE="/tmp/hytale-console.in"
AUTH_OUTPUT_LOG="/tmp/hytale-server.log"
rm -f "$AUTH_PIPE" "$AUTH_OUTPUT_LOG"
mkfifo "$AUTH_PIPE"
touch "$AUTH_OUTPUT_LOG"

# First check if /etc/machine-id exists
log_step "Checking Hardware ID"
if [ ! -f "/etc/machine-id" ]; then
    log_warning "Hardware ID not found" "Mount /etc/machine-id:/etc/machine-id:ro to enable encrypted credential persistence"
    printf "      ${DIM}↳ Info:${NC} Auto-auth will run on every startup without it\n"
elif [ -z "$(cat /etc/machine-id 2>/dev/null | tr -d '\n' | tr -d '\r')" ]; then
    log_warning "Hardware ID file is empty" "Ensure /etc/machine-id contains a valid machine identifier"
elif [ -f "$BASE_DIR/auth.enc" ]; then
    log_success
    log_step "Credential Persistence"
    printf "${GREEN}enabled (auth.enc file found)${NC}\n"
    RUN_AUTO_AUTH=FALSE
else
    log_success
    log_step "Credential Persistence"
    printf "${YELLOW}not configured${NC}\n"
fi

if [ "$RUN_AUTO_AUTH" = "TRUE" ]; then
    (
        tail -n0 -F "$AUTH_OUTPUT_LOG" | while IFS= read -r line; do
            case "$line" in
                *"$HYTALE_AUTH_READY_PATTERN"*|*"$HYTALE_AUTH_READY_ALT_PATTERN"*)
                    {
                        printf "auth persistence Encrypted\n"
                        printf "auth login device\n"
                    } > "$AUTH_PIPE"
                    break
                    ;;
            esac
        done
    ) &
fi

printf "\n"


+# Execute Java server as non-root user
exec $RUNTIME sh -c "( tail -f \"$AUTH_PIPE\" & cat ) | exec stdbuf -oL -eL java $JAVA_ARGS \
    -Duser.timezone=\"$TZ\" \
    -Dterminal.jline=false \
    -Dterminal.ansi=true \
    -jar \"$SERVER_JAR_PATH\" \
    $HYTALE_HELP_OPT \
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
    --assets \"$GAME_DIR/Assets.zip\" \
    --bind \"$SERVER_IP:$SERVER_PORT\" 2>&1 | tee \"$AUTH_OUTPUT_LOG\""
