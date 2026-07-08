#!/bin/sh

# Note: set -eu removed — pipe components and FIFO operations return non-zero
# during normal lifecycle (e.g., FIFO read EOF, broken pipes). Using explicit
# error handling where needed instead.

# Copyright (C) 2026 Daniel Freudenberg
#
# This file is part of hytale-server-container.
#
# hytale-server-container is free software: you can redistribute it
# and/or modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
#
# hytale-server-container is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty
# of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with hytale-server-container. If not, see
# <https://www.gnu.org/licenses/>.

# Load dependencies
. "$SCRIPTS_PATH/utils.sh"

# ==========================================
# HELPER FUNCTIONS
# ==========================================

apply_staged_update() {
    [ ! -f "updater/staging/Server/HytaleServer.jar" ] && return

    log_step "Applying staged update"
    cp -f updater/staging/Server/HytaleServer.jar Server/
    [ -f "updater/staging/Server/HytaleServer.aot" ]   && cp -f updater/staging/Server/HytaleServer.aot Server/
    [ -d "updater/staging/Server/Licenses" ]           && rm -rf Server/Licenses && cp -r updater/staging/Server/Licenses Server/
    [ -f "updater/staging/Assets.zip" ]                && cp -f updater/staging/Assets.zip ./
    rm -rf updater/staging
    log_success
}

build_java_command() {
    cat <<JAVAEOF
stdbuf -oL -eL java $JAVA_ARGS \
    $HYTALE_CACHE_OPT \
    $HYTALE_CACHE_LOG_OPT \
    -Duser.timezone="$TZ" \
    -Dterminal.jline=false \
    -Dterminal.ansi=true \
    -jar "$SERVER_JAR_PATH" \
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
    --assets "$GAME_DIR/Assets.zip" \
    --bind "$SERVER_IP:$SERVER_PORT"
JAVAEOF
}

run_server() {
    local java_cmd="$1"
    RUNTIME_CMD="${RUNTIME:-}"

    if [ -n "$RUNTIME_CMD" ]; then
        $RUNTIME sh -c "( tail -f \"$AUTH_PIPE\" 2>/dev/null || true ) | $java_cmd 2>&1 | stdbuf -oL -eL sed 's/\r$//' | stdbuf -oL -eL tee \"$AUTH_OUTPUT_LOG\""
    else
        ( tail -f "$AUTH_PIPE" 2>/dev/null || true ) | $java_cmd 2>&1 | stdbuf -oL -eL sed 's/\r$//' | stdbuf -oL -eL tee "$AUTH_OUTPUT_LOG"
    fi
}

handle_exit_code() {
    local exit_code="$1"
    local elapsed="$2"
    local applied_update="$3"

    # Exit code 8 = restart to apply update from /update download command
    if [ $exit_code -eq 8 ]; then
        log_step "Server requesting restart (exit code 8) - triggering container restart"
        log_success
        exit 8
    fi

    # Warn on crash shortly after update
    if [ $exit_code -ne 0 ] && [ "$applied_update" = true ] && [ $elapsed -lt 30 ]; then
        log_error "Server crashed ${elapsed}s after update" "Exit code: $exit_code"
        printf "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
        printf "${YELLOW}Update Failed${NC}\n"
        printf "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n\n"
        printf "Server crashed within ${elapsed}s of applying the update.\n"
        printf "This may indicate the update is incompatible.\n\n"
        printf "${DIM}Check logs in: /home/container/Server/logs/${NC}\n\n"
        printf "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    fi

    exit $exit_code
}

# ==========================================
# MAIN EXECUTION FLOW
# ==========================================

cd "$GAME_DIR"

while true; do
    APPLIED_UPDATE=false

    # Apply staged update if present
    apply_staged_update && APPLIED_UPDATE=true

    cd Server
    START_TIME=$(date +%s)

    JAVA_CMD=$(build_java_command)
    run_server "$JAVA_CMD"
    EXIT_CODE=$?
    ELAPSED=$(($(date +%s) - START_TIME))

    cd "$GAME_DIR"
    handle_exit_code $EXIT_CODE $ELAPSED $APPLIED_UPDATE
done