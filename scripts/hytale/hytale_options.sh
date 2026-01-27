#!/bin/sh
set -eu

# Load dependencies (Ensuring SCRIPTS_PATH is available from the parent)
. "$SCRIPTS_PATH/utils.sh"

log_section "Server Options Management"

# Initialize options to ensure they are empty if not set
export HYTALE_HELP_OPT=""
export HYTALE_ACCEPT_EARLY_PLUGINS_OPT=""
export HYTALE_ALLOW_OP_OPT=""
export HYTALE_AUTH_MODE_OPT=""
export HYTALE_BACKUP_OPT=""
export HYTALE_BACKUP_DIR_OPT=""
export HYTALE_BACKUP_FREQUENCY_OPT=""
export HYTALE_BACKUP_MAX_COUNT_OPT=""
export HYTALE_BARE_OPT=""
export HYTALE_BOOT_COMMAND_OPT=""
export HYTALE_CACHE_OPT=""
export HYTALE_CLIENT_PID_OPT=""
export HYTALE_DISABLE_ASSET_COMPARE_OPT=""
export HYTALE_DISABLE_CPB_BUILD_OPT=""
export HYTALE_DISABLE_FILE_WATCHER_OPT=""
export HYTALE_DISABLE_SENTRY_OPT=""
export HYTALE_EARLY_PLUGINS_OPT=""
export HYTALE_EVENT_DEBUG_OPT=""
export HYTALE_FORCE_NETWORK_FLUSH_OPT=""
export HYTALE_GENERATE_SCHEMA_OPT=""
export HYTALE_IDENTITY_TOKEN_OPT=""
export HYTALE_LOG_OPT=""
export HYTALE_MIGRATE_WORLDS_OPT=""
export HYTALE_MIGRATIONS_OPT=""
export HYTALE_MODS_OPT=""
export HYTALE_OWNER_NAME_OPT=""
export HYTALE_OWNER_UUID_OPT=""
export HYTALE_PREFAB_CACHE_OPT=""
export HYTALE_SESSION_TOKEN_OPT=""
export HYTALE_SHUTDOWN_AFTER_VALIDATE_OPT=""
export HYTALE_SINGLEPLAYER_OPT=""
export HYTALE_TRANSPORT_OPT=""
export HYTALE_UNIVERSE_OPT=""
export HYTALE_VALIDATE_ASSETS_OPT=""
export HYTALE_VALIDATE_PREFABS_OPT=""
export HYTALE_VALIDATE_WORLD_GEN_OPT=""
export HYTALE_VERSION_OPT=""
export HYTALE_WORLD_GEN_OPT=""

# Enable help option    
log_step "Enable help option"
if [ "${HYTALE_HELP:-}" = "TRUE" ]; then
    export HYTALE_HELP_OPT="--help"
    printf "${GREEN}enabled${NC}\n"
else
    printf "${DIM}disabled${NC}\n"
fi

# Accept Early Plugins
log_step "Accept Early Plugins"
if [ "${HYTALE_ACCEPT_EARLY_PLUGINS:-}" = "TRUE" ]; then
    export HYTALE_ACCEPT_EARLY_PLUGINS_OPT="--accept-early-plugins"
    printf "${GREEN}enabled${NC}\n"
else
    printf "${DIM}disabled${NC}\n"
fi

# Allow OP
log_step "Allow OP"
if [ "${HYTALE_ALLOW_OP:-}" = "TRUE" ]; then
    export HYTALE_ALLOW_OP_OPT="--allow-op"
    printf "${GREEN}enabled${NC}\n"
else
    printf "${DIM}disabled${NC}\n"
fi

# Authentication Mode
log_step "Authentication Mode"
if [ -n "${HYTALE_AUTH_MODE:-}" ]; then
    if [ "$HYTALE_AUTH_MODE" = "authenticated" ] || [ "$HYTALE_AUTH_MODE" = "insecure" ] || [ "$HYTALE_AUTH_MODE" = "offline" ]; then
        export HYTALE_AUTH_MODE_OPT="--auth-mode=$HYTALE_AUTH_MODE"
        printf "${GREEN}$HYTALE_AUTH_MODE${NC}\n"
    else
        printf "${RED}invalid: $HYTALE_AUTH_MODE${NC} (use 'authenticated', 'insecure' or 'offline')${NC}\n"
    fi
else
    printf "${DIM}default (authenticated)${NC}\n"
fi

# Backup Configuration
log_step "Backup Configuration"
if [ -n "${HYTALE_BACKUP_DIR:-}" ]; then
    export HYTALE_BACKUP_DIR_OPT="--backup-dir=$HYTALE_BACKUP_DIR"
    printf "${GREEN}enabled${NC} (dir: ${CYAN}${HYTALE_BACKUP_DIR}${NC}"

    # Check if backup on startup is enabled
    if [ "${HYTALE_BACKUP:-}" = "TRUE" ]; then
        export HYTALE_BACKUP_OPT="--backup"
        printf ", startup backup: ${GREEN}yes${NC}"
    else
        printf ", startup backup: ${DIM}no${NC}"
    fi

    # Optional backup settings
    if [ -n "${HYTALE_BACKUP_FREQUENCY:-}" ]; then
        export HYTALE_BACKUP_FREQUENCY_OPT="--backup-frequency=$HYTALE_BACKUP_FREQUENCY"
        printf ", freq: ${CYAN}${HYTALE_BACKUP_FREQUENCY}${NC}"
    fi

    if [ -n "${HYTALE_BACKUP_MAX_COUNT:-}" ]; then
        export HYTALE_BACKUP_MAX_COUNT_OPT="--backup-max-count=$HYTALE_BACKUP_MAX_COUNT"
        printf ", max: ${CYAN}${HYTALE_BACKUP_MAX_COUNT}${NC}"
    fi

    printf ")\n"
else
    if [ "${HYTALE_BACKUP:-}" = "TRUE" ]; then
        printf "${YELLOW}warning: HYTALE_BACKUP=TRUE requires HYTALE_BACKUP_DIR${NC}\n"
    else
        printf "${DIM}not configured${NC}\n"
    fi
fi

# Bare Mode
log_step "Bare Mode"
if [ "${HYTALE_BARE:-}" = "TRUE" ]; then
    export HYTALE_BARE_OPT="--bare"
    printf "${GREEN}enabled${NC}\n"
else
    printf "${DIM}disabled${NC}\n"
fi

# Boot Command
log_step "Boot Command"
if [ -n "${HYTALE_BOOT_COMMAND:-}" ]; then
    export HYTALE_BOOT_COMMAND_OPT="--boot-command=$HYTALE_BOOT_COMMAND"
    printf "${GREEN}set${NC}\n"
else
    printf "${DIM}not set${NC}\n"
fi

# Client PID
log_step "Client PID"
if [ -n "${HYTALE_CLIENT_PID:-}" ]; then
    export HYTALE_CLIENT_PID_OPT="--client-pid=$HYTALE_CLIENT_PID"
    printf "${GREEN}$HYTALE_CLIENT_PID${NC}\n"
else
    printf "${DIM}not set${NC}\n"
fi

# Disable Asset Compare
log_step "Asset Compare"
if [ "${HYTALE_DISABLE_ASSET_COMPARE:-}" = "TRUE" ]; then
    export HYTALE_DISABLE_ASSET_COMPARE_OPT="--disable-asset-compare"
    printf "${YELLOW}disabled${NC}\n"
else
    printf "${GREEN}enabled${NC}\n"
fi

# Disable CPB Build
log_step "CPB Build"
if [ "${HYTALE_DISABLE_CPB_BUILD:-}" = "TRUE" ]; then
    export HYTALE_DISABLE_CPB_BUILD_OPT="--disable-cpb-build"
    printf "${YELLOW}disabled${NC}\n"
else
    printf "${GREEN}enabled${NC}\n"
fi

# Disable File Watcher
log_step "File Watcher"
if [ "${HYTALE_DISABLE_FILE_WATCHER:-}" = "TRUE" ]; then
    export HYTALE_DISABLE_FILE_WATCHER_OPT="--disable-file-watcher"
    printf "${YELLOW}disabled${NC}\n"
else
    printf "${GREEN}enabled${NC}\n"
fi

# Disable Sentry
log_step "Sentry"
if [ "${HYTALE_DISABLE_SENTRY:-}" = "TRUE" ]; then
    export HYTALE_DISABLE_SENTRY_OPT="--disable-sentry"
    printf "${YELLOW}disabled${NC}\n"
else
    printf "${GREEN}enabled${NC}\n"
fi

# Early Plugins Path
log_step "Early Plugins Path"
if [ -n "${HYTALE_EARLY_PLUGINS:-}" ]; then
    export HYTALE_EARLY_PLUGINS_OPT="--early-plugins=$HYTALE_EARLY_PLUGINS"
    printf "${GREEN}$HYTALE_EARLY_PLUGINS${NC}\n"
else
    printf "${DIM}not set${NC}\n"
fi

# Event Debug
log_step "Event Debug"
if [ "${HYTALE_EVENT_DEBUG:-}" = "TRUE" ]; then
    export HYTALE_EVENT_DEBUG_OPT="--event-debug"
    printf "${GREEN}enabled${NC}\n"
else
    printf "${DIM}disabled${NC}\n"
fi

# Force Network Flush
log_step "Force Network Flush"
if [ -n "${HYTALE_FORCE_NETWORK_FLUSH:-}" ]; then
    export HYTALE_FORCE_NETWORK_FLUSH_OPT="--force-network-flush=$HYTALE_FORCE_NETWORK_FLUSH"
    printf "${GREEN}$HYTALE_FORCE_NETWORK_FLUSH${NC}\n"
else
    printf "${DIM}default (true)${NC}\n"
fi

# Generate Schema
log_step "Generate Schema"
if [ "${HYTALE_GENERATE_SCHEMA:-}" = "TRUE" ]; then
    export HYTALE_GENERATE_SCHEMA_OPT="--generate-schema"
    printf "${GREEN}enabled${NC}\n"
else
    printf "${DIM}disabled${NC}\n"
fi

# Identity Token
log_step "Identity Token"
if [ -n "${HYTALE_IDENTITY_TOKEN:-}" ]; then
    export HYTALE_IDENTITY_TOKEN_OPT="--identity-token=$HYTALE_IDENTITY_TOKEN"
    printf "${GREEN}set${NC}\n"
else
    printf "${DIM}not set${NC}\n"
fi

# Log Level
log_step "Log Level"
if [ -n "${HYTALE_LOG:-}" ]; then
    export HYTALE_LOG_OPT="--log=$HYTALE_LOG"
    printf "${GREEN}$HYTALE_LOG${NC}\n"
else
    printf "${DIM}default${NC}\n"
fi

# Migrate Worlds
log_step "Migrate Worlds"
if [ -n "${HYTALE_MIGRATE_WORLDS:-}" ]; then
    export HYTALE_MIGRATE_WORLDS_OPT="--migrate-worlds=$HYTALE_MIGRATE_WORLDS"
    printf "${GREEN}$HYTALE_MIGRATE_WORLDS${NC}\n"
else
    printf "${DIM}not set${NC}\n"
fi

# Migrations
log_step "Migrations"
if [ -n "${HYTALE_MIGRATIONS:-}" ]; then
    export HYTALE_MIGRATIONS_OPT="--migrations=$HYTALE_MIGRATIONS"
    printf "${GREEN}set${NC}\n"
else
    printf "${DIM}not set${NC}\n"
fi

# Mods Path
log_step "Mods Path"
if [ -n "${HYTALE_MODS:-}" ]; then
    export HYTALE_MODS_OPT="--mods=$HYTALE_MODS"
    printf "${GREEN}$HYTALE_MODS${NC}\n"
else
    printf "${DIM}not set${NC}\n"
fi

# Owner Name
log_step "Owner Name"
if [ -n "${HYTALE_OWNER_NAME:-}" ]; then
    export HYTALE_OWNER_NAME_OPT="--owner-name=$HYTALE_OWNER_NAME"
    printf "${GREEN}$HYTALE_OWNER_NAME${NC}\n"
else
    printf "${DIM}not set${NC}\n"
fi

# Owner UUID
log_step "Owner UUID"
if [ -n "${HYTALE_OWNER_UUID:-}" ]; then
    export HYTALE_OWNER_UUID_OPT="--owner-uuid=$HYTALE_OWNER_UUID"
    printf "${GREEN}$HYTALE_OWNER_UUID${NC}\n"
else
    printf "${DIM}not set${NC}\n"
fi

# Prefab Cache
log_step "Prefab Cache"
if [ -n "${HYTALE_PREFAB_CACHE:-}" ]; then
    export HYTALE_PREFAB_CACHE_OPT="--prefab-cache=$HYTALE_PREFAB_CACHE"
    printf "${GREEN}$HYTALE_PREFAB_CACHE${NC}\n"
else
    printf "${DIM}default${NC}\n"
fi

# Session Token
log_step "Session Token"
if [ -n "${HYTALE_SESSION_TOKEN:-}" ]; then
    export HYTALE_SESSION_TOKEN_OPT="--session-token=$HYTALE_SESSION_TOKEN"
    printf "${GREEN}set${NC}\n"
else
    printf "${DIM}not set${NC}\n"
fi

# Shutdown After Validate
log_step "Shutdown After Validate"
if [ "${HYTALE_SHUTDOWN_AFTER_VALIDATE:-}" = "TRUE" ]; then
    export HYTALE_SHUTDOWN_AFTER_VALIDATE_OPT="--shutdown-after-validate"
    printf "${GREEN}enabled${NC}\n"
else
    printf "${DIM}disabled${NC}\n"
fi

# Singleplayer
log_step "Singleplayer"
if [ "${HYTALE_SINGLEPLAYER:-}" = "TRUE" ]; then
    export HYTALE_SINGLEPLAYER_OPT="--singleplayer"
    printf "${GREEN}enabled${NC}\n"
else
    printf "${DIM}disabled${NC}\n"
fi

# Transport Type
log_step "Transport Type"
if [ -n "${HYTALE_TRANSPORT:-}" ]; then
    export HYTALE_TRANSPORT_OPT="--transport=$HYTALE_TRANSPORT"
    printf "${GREEN}$HYTALE_TRANSPORT${NC}\n"
else
    printf "${DIM}default (QUIC)${NC}\n"
fi

# Universe Path
log_step "Universe Path"
if [ -n "${HYTALE_UNIVERSE:-}" ]; then
    export HYTALE_UNIVERSE_OPT="--universe=$HYTALE_UNIVERSE"
    printf "${GREEN}$HYTALE_UNIVERSE${NC}\n"
else
    printf "${DIM}not set${NC}\n"
fi

# Validate Assets
log_step "Validate Assets"
if [ "${HYTALE_VALIDATE_ASSETS:-}" = "TRUE" ]; then
    export HYTALE_VALIDATE_ASSETS_OPT="--validate-assets"
    printf "${GREEN}enabled${NC}\n"
else
    printf "${DIM}disabled${NC}\n"
fi

# Validate Prefabs
log_step "Validate Prefabs"
if [ -n "${HYTALE_VALIDATE_PREFABS:-}" ]; then
    export HYTALE_VALIDATE_PREFABS_OPT="--validate-prefabs=$HYTALE_VALIDATE_PREFABS"
    printf "${GREEN}$HYTALE_VALIDATE_PREFABS${NC}\n"
else
    printf "${DIM}disabled${NC}\n"
fi

# Validate World Gen
log_step "Validate World Gen"
if [ "${HYTALE_VALIDATE_WORLD_GEN:-}" = "TRUE" ]; then
    export HYTALE_VALIDATE_WORLD_GEN_OPT="--validate-world-gen"
    printf "${GREEN}enabled${NC}\n"
else
    printf "${DIM}disabled${NC}\n"
fi

# Version Info
log_step "Version Info"
if [ "${HYTALE_VERSION:-}" = "TRUE" ]; then
    export HYTALE_VERSION_OPT="--version"
    printf "${GREEN}enabled${NC}\n"
else
    printf "${DIM}disabled${NC}\n"
fi

# World Gen Path
log_step "World Gen Path"
if [ -n "${HYTALE_WORLD_GEN:-}" ]; then
    export HYTALE_WORLD_GEN_OPT="--world-gen=$HYTALE_WORLD_GEN"
    printf "${GREEN}$HYTALE_WORLD_GEN${NC}\n"
else
    printf "${DIM}not set${NC}\n"
fi

# AOT Cache
log_step "AOT Cache"
if [ "${HYTALE_CACHE:-}" = "TRUE" ]; then
    export HYTALE_CACHE_OPT="-XX:AOTCache=$HYTALE_CACHE_DIR"
    printf "${GREEN}enabled${NC} (dir: ${CYAN}${HYTALE_CACHE_DIR}${NC})\n"
else
    printf "${DIM}disabled${NC}\n"
fi

printf "      ${DIM}↳ Server Options:${NC} ${GREEN}Ready${NC}\n"
