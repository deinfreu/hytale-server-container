#!/bin/sh
set -eu

# Load dependencies (Ensuring SCRIPTS_PATH is available from the parent)
. "$SCRIPTS_PATH/utils.sh"

log_section "Server Options Management"

# ==========================================
# HELPER FUNCTIONS
# ==========================================

set_flag() {
    local var_name="$1"
    local flag_val="$2"
    export "$var_name"="$flag_val"
}

print_enabled()     { printf "${GREEN}enabled${NC}\n"; }
print_disabled()    { printf "${DIM}disabled${NC}\n"; }
print_not_set()     { printf "${DIM}not set${NC}\n"; }
print_default()     { printf "${DIM}default${NC}\n"; }

check_bool() {
    local label="$1"
    local env_var="${2:-}"
    local inverted="${3:-false}"

    log_step "$label"
    if [ "$env_var" = "TRUE" ]; then
        if [ "$inverted" = "true" ]; then print_disabled; else print_enabled; fi
    else
        if [ "$inverted" = "true" ]; then print_enabled; else print_disabled; fi
    fi
}

check_string() {
    local label="$1"
    local env_var="${2:-}"
    local default_msg="${3:-not set}"

    log_step "$label"
    if [ -n "$env_var" ]; then
        printf "${GREEN}%s${NC}\n" "$env_var"
    else
        print_not_set
    fi
}

check_string_default() {
    local label="$1"
    local env_var="${2:-}"
    local default_val="${3:-default}"

    log_step "$label"
    if [ -n "$env_var" ]; then
        printf "${GREEN}%s${NC}\n" "$env_var"
    else
        printf "${DIM}default (%s)${NC}\n" "$default_val"
    fi
}

# ==========================================
# MAIN EXECUTION FLOW
# ==========================================

# Initialize options to ensure they are empty if not set
export HYTALE_CACHE_OPT=""
export HYTALE_CACHE_LOG_OPT=""
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

# --- Boolean flags ---
check_bool "Enable help option"          "${HYTALE_HELP:-}"
[ "${HYTALE_HELP:-}" = "TRUE" ] && set_flag HYTALE_HELP_OPT "--help"

check_bool "Accept Early Plugins"        "${HYTALE_ACCEPT_EARLY_PLUGINS:-}"
[ "${HYTALE_ACCEPT_EARLY_PLUGINS:-}" = "TRUE" ] && set_flag HYTALE_ACCEPT_EARLY_PLUGINS_OPT "--accept-early-plugins"

check_bool "Allow OP"                    "${HYTALE_ALLOW_OP:-}"
[ "${HYTALE_ALLOW_OP:-}" = "TRUE" ] && set_flag HYTALE_ALLOW_OP_OPT "--allow-op"

check_bool "Bare Mode"                   "${HYTALE_BARE:-}"
[ "${HYTALE_BARE:-}" = "TRUE" ] && set_flag HYTALE_BARE_OPT "--bare"

check_bool "Disable Asset Compare"       "${HYTALE_DISABLE_ASSET_COMPARE:-}" "true"
[ "${HYTALE_DISABLE_ASSET_COMPARE:-}" = "TRUE" ] && set_flag HYTALE_DISABLE_ASSET_COMPARE_OPT "--disable-asset-compare"

check_bool "Disable CPB Build"           "${HYTALE_DISABLE_CPB_BUILD:-}" "true"
[ "${HYTALE_DISABLE_CPB_BUILD:-}" = "TRUE" ] && set_flag HYTALE_DISABLE_CPB_BUILD_OPT "--disable-cpb-build"

check_bool "Disable File Watcher"        "${HYTALE_DISABLE_FILE_WATCHER:-}" "true"
[ "${HYTALE_DISABLE_FILE_WATCHER:-}" = "TRUE" ] && set_flag HYTALE_DISABLE_FILE_WATCHER_OPT "--disable-file-watcher"

check_bool "Disable Sentry"              "${HYTALE_DISABLE_SENTRY:-}" "true"
[ "${HYTALE_DISABLE_SENTRY:-}" = "TRUE" ] && set_flag HYTALE_DISABLE_SENTRY_OPT "--disable-sentry"

check_bool "Event Debug"                 "${HYTALE_EVENT_DEBUG:-}"
[ "${HYTALE_EVENT_DEBUG:-}" = "TRUE" ] && set_flag HYTALE_EVENT_DEBUG_OPT "--event-debug"

check_bool "Generate Schema"             "${HYTALE_GENERATE_SCHEMA:-}"
[ "${HYTALE_GENERATE_SCHEMA:-}" = "TRUE" ] && set_flag HYTALE_GENERATE_SCHEMA_OPT "--generate-schema"

check_bool "Shutdown After Validate"     "${HYTALE_SHUTDOWN_AFTER_VALIDATE:-}"
[ "${HYTALE_SHUTDOWN_AFTER_VALIDATE:-}" = "TRUE" ] && set_flag HYTALE_SHUTDOWN_AFTER_VALIDATE_OPT "--shutdown-after-validate"

check_bool "Singleplayer"                "${HYTALE_SINGLEPLAYER:-}"
[ "${HYTALE_SINGLEPLAYER:-}" = "TRUE" ] && set_flag HYTALE_SINGLEPLAYER_OPT "--singleplayer"

check_bool "Validate Assets"             "${HYTALE_VALIDATE_ASSETS:-}"
[ "${HYTALE_VALIDATE_ASSETS:-}" = "TRUE" ] && set_flag HYTALE_VALIDATE_ASSETS_OPT "--validate-assets"

check_bool "Validate World Gen"          "${HYTALE_VALIDATE_WORLD_GEN:-}"
[ "${HYTALE_VALIDATE_WORLD_GEN:-}" = "TRUE" ] && set_flag HYTALE_VALIDATE_WORLD_GEN_OPT "--validate-world-gen"

check_bool "AOT Cache Log"               "${HYTALE_CACHE_LOG:-}"
if [ "${HYTALE_CACHE_LOG:-}" = "TRUE" ]; then set_flag HYTALE_CACHE_LOG_OPT "-Xlog:aot"; fi

# --- String/Value options ---
log_step "Authentication Mode"
case "$HYTALE_AUTH_MODE" in
    authenticated|insecure|offline)
        set_flag HYTALE_AUTH_MODE_OPT "--auth-mode=$HYTALE_AUTH_MODE"
        printf "${GREEN}$HYTALE_AUTH_MODE${NC}\n" ;;
    *) [ -n "${HYTALE_AUTH_MODE:-}" ] && printf "${RED}invalid: $HYTALE_AUTH_MODE${NC} (use 'authenticated', 'insecure' or 'offline')${NC}" ;;
esac
[ -z "${HYTALE_AUTH_MODE:-}" ] && print_default

log_step "Backup Configuration"
if [ -n "${HYTALE_BACKUP_DIR:-}" ]; then
    set_flag HYTALE_BACKUP_DIR_OPT "--backup-dir=$HYTALE_BACKUP_DIR"
    printf "${GREEN}enabled${NC} (dir: ${CYAN}${HYTALE_BACKUP_DIR}${NC}"
    [ "${HYTALE_BACKUP:-}" = "TRUE" ] && { set_flag HYTALE_BACKUP_OPT "--backup"; printf ", startup backup: ${GREEN}yes${NC}"; } || printf ", startup backup: ${DIM}no${NC}"
    [ -n "${HYTALE_BACKUP_FREQUENCY:-}" ] && { set_flag HYTALE_BACKUP_FREQUENCY_OPT "--backup-frequency=$HYTALE_BACKUP_FREQUENCY"; printf ", freq: ${CYAN}${HYTALE_BACKUP_FREQUENCY}${NC}"; }
    [ -n "${HYTALE_BACKUP_MAX_COUNT:-}" ]   && { set_flag HYTALE_BACKUP_MAX_COUNT_OPT   "--backup-max-count=$HYTALE_BACKUP_MAX_COUNT";   printf ", max: ${CYAN}${HYTALE_BACKUP_MAX_COUNT}${NC}"; }
    printf ")\n"
elif [ "${HYTALE_BACKUP:-}" = "TRUE" ]; then
    printf "${YELLOW}warning: HYTALE_BACKUP=TRUE requires HYTALE_BACKUP_DIR${NC}\n"
else
    print_not_set
fi

check_string  "Boot Command"        "${HYTALE_BOOT_COMMAND:-}"
[ -n "${HYTALE_BOOT_COMMAND:-}" ] && set_flag HYTALE_BOOT_COMMAND_OPT "--boot-command=$HYTALE_BOOT_COMMAND"

check_string  "Client PID"          "${HYTALE_CLIENT_PID:-}"
[ -n "${HYTALE_CLIENT_PID:-}" ]   && set_flag HYTALE_CLIENT_PID_OPT "--client-pid=$HYTALE_CLIENT_PID"

check_string  "Early Plugins Path"  "${HYTALE_EARLY_PLUGINS:-}"
[ -n "${HYTALE_EARLY_PLUGINS:-}" ] && set_flag HYTALE_EARLY_PLUGINS_OPT "--early-plugins=$HYTALE_EARLY_PLUGINS"

log_step "Force Network Flush"
if [ -n "${HYTALE_FORCE_NETWORK_FLUSH:-}" ]; then
    set_flag HYTALE_FORCE_NETWORK_FLUSH_OPT "--force-network-flush=$HYTALE_FORCE_NETWORK_FLUSH"
    printf "${GREEN}$HYTALE_FORCE_NETWORK_FLUSH${NC}\n"
else
    print_default
fi

check_string  "Identity Token"      "${HYTALE_IDENTITY_TOKEN:-}"
[ -n "${HYTALE_IDENTITY_TOKEN:-}" ] && set_flag HYTALE_IDENTITY_TOKEN_OPT "--identity-token=$HYTALE_IDENTITY_TOKEN"

log_step "Log Level"
if [ -n "${HYTALE_LOG:-}" ]; then
    set_flag HYTALE_LOG_OPT "--log=$HYTALE_LOG"
    printf "${GREEN}$HYTALE_LOG${NC}\n"
else
    print_default
fi

check_string  "Migrate Worlds"      "${HYTALE_MIGRATE_WORLDS:-}"
[ -n "${HYTALE_MIGRATE_WORLDS:-}" ] && set_flag HYTALE_MIGRATE_WORLDS_OPT "--migrate-worlds=$HYTALE_MIGRATE_WORLDS"

check_string  "Migrations"          "${HYTALE_MIGRATIONS:-}"
[ -n "${HYTALE_MIGRATIONS:-}" ]     && set_flag HYTALE_MIGRATIONS_OPT "--migrations=$HYTALE_MIGRATIONS"

check_string  "Mods Path"           "${HYTALE_MODS:-}"
[ -n "${HYTALE_MODS:-}" ]          && set_flag HYTALE_MODS_OPT "--mods=$HYTALE_MODS"

check_string  "Owner Name"          "${HYTALE_OWNER_NAME:-}"
[ -n "${HYTALE_OWNER_NAME:-}" ]    && set_flag HYTALE_OWNER_NAME_OPT "--owner-name=$HYTALE_OWNER_NAME"

check_string  "Owner UUID"          "${HYTALE_OWNER_UUID:-}"
[ -n "${HYTALE_OWNER_UUID:-}" ]    && set_flag HYTALE_OWNER_UUID_OPT "--owner-uuid=$HYTALE_OWNER_UUID"

log_step "Prefab Cache"
if [ -n "${HYTALE_PREFAB_CACHE:-}" ]; then
    set_flag HYTALE_PREFAB_CACHE_OPT "--prefab-cache=$HYTALE_PREFAB_CACHE"
    printf "${GREEN}$HYTALE_PREFAB_CACHE${NC}\n"
else
    print_default
fi

check_string  "Session Token"       "${HYTALE_SESSION_TOKEN:-}"
[ -n "${HYTALE_SESSION_TOKEN:-}" ] && set_flag HYTALE_SESSION_TOKEN_OPT "--session-token=$HYTALE_SESSION_TOKEN"

log_step "Transport Type"
if [ -n "${HYTALE_TRANSPORT:-}" ]; then
    set_flag HYTALE_TRANSPORT_OPT "--transport=$HYTALE_TRANSPORT"
    printf "${GREEN}$HYTALE_TRANSPORT${NC}\n"
else
    print_default
fi

check_string  "Universe Path"       "${HYTALE_UNIVERSE:-}"
[ -n "${HYTALE_UNIVERSE:-}" ]      && set_flag HYTALE_UNIVERSE_OPT "--universe=$HYTALE_UNIVERSE"

log_step "Validate Prefabs"
if [ -n "${HYTALE_VALIDATE_PREFABS:-}" ]; then
    set_flag HYTALE_VALIDATE_PREFABS_OPT "--validate-prefabs=$HYTALE_VALIDATE_PREFABS"
    printf "${GREEN}$HYTALE_VALIDATE_PREFABS${NC}\n"
else
    print_disabled
fi

log_step "Version Info"
if [ "${HYTALE_VERSION:-}" = "TRUE" ]; then
    set_flag HYTALE_VERSION_OPT "--version"
    print_enabled
else
    print_disabled
fi

check_string  "World Gen Path"      "${HYTALE_WORLD_GEN:-}"
[ -n "${HYTALE_WORLD_GEN:-}" ]     && set_flag HYTALE_WORLD_GEN_OPT "--world-gen=$HYTALE_WORLD_GEN"

# --- AOT Cache (special handling) ---
log_step "AOT Cache"
if [ "${HYTALE_CACHE:-}" = "TRUE" ]; then
    set_flag HYTALE_CACHE_OPT "-XX:AOTCache=$HYTALE_CACHE_DIR"
    printf "${GREEN}enabled${NC} (file: ${CYAN}${HYTALE_CACHE_DIR}${NC})\n"
fi

printf "      ${DIM}↳ Server Options:${NC} ${GREEN}Ready${NC}\n"