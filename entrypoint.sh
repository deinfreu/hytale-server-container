#!/bin/sh
set -eu

# Force line buffering for TrueNAS Scale log compatibility
export PYTHONUNBUFFERED=1
stdbuf -oL -eL true 2>/dev/null && USE_STDBUF=true || USE_STDBUF=false

# Bootstrap SCRIPTS_PATH for environment loading
export SCRIPTS_PATH="/usr/local/bin/scripts"

# Load all environment variables and configuration defaults
. "$SCRIPTS_PATH/environment.sh"

# Load utility functions for logging
. "$SCRIPTS_PATH/utils.sh"

# Check CPU architecture compatibility
sh "$SCRIPTS_PATH/checks/arch_check.sh"

# --- Initialization Phase ---
# CRITICAL ORDER: Binary handler must run BEFORE config management

# Manage Hytale server binary (download/update)
sh "$SCRIPTS_PATH/hytale/hytale_binary_handler.sh"

# Manage server configuration files
sh "$SCRIPTS_PATH/hytale/hytale_config.sh"

# Convert environment variables to CLI options
. "$SCRIPTS_PATH/hytale/hytale_options.sh"

# Run system audit checks
. "$SCRIPTS_PATH/checks/audit_suite.sh"

# --- Execution Phase ---
log_section "Launching Hytale Server"

# Determine user switching mechanism (gosu/su-exec)
. "$SCRIPTS_PATH/checks/user_switch.sh"

# Configure authentication and auto-login
. "$SCRIPTS_PATH/hytale/hytale_auth.sh"

# Launch Java server process with all configured options
exec $RUNTIME sh -c "( tail -f \"$AUTH_PIPE\" & cat ) | exec stdbuf -oL -eL java $JAVA_ARGS \
    $HYTALE_CACHE_OPT \
    $HYTALE_CACHE_LOG_OPT \
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
