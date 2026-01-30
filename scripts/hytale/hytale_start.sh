#!/bin/sh
set -eu

# Load dependencies
. "$SCRIPTS_PATH/utils.sh"

# Hytale Server Launcher with Update Support
# Handles /update download command (exit code 8) and staged update application

# Change to game directory (where Assets.zip and Server/ subdirectory are)
cd "$GAME_DIR"

# Server restart loop - handles /update download command (exit code 8)
while true; do
    APPLIED_UPDATE=false
    
    # Apply staged update if present (from /update download command)
    if [ -f "updater/staging/Server/HytaleServer.jar" ]; then
        log_step "Applying staged update"
        # Only replace server binaries, preserve config/saves/mods
        cp -f updater/staging/Server/HytaleServer.jar Server/
        [ -f "updater/staging/Server/HytaleServer.aot" ] && cp -f updater/staging/Server/HytaleServer.aot Server/
        [ -d "updater/staging/Server/Licenses" ] && rm -rf Server/Licenses && cp -r updater/staging/Server/Licenses Server/
        [ -f "updater/staging/Assets.zip" ] && cp -f updater/staging/Assets.zip ./
        rm -rf updater/staging
        APPLIED_UPDATE=true
        log_success
    fi

    # Run server from inside Server/ folder (like start.sh does)
    cd Server

    # Track start time for crash detection
    START_TIME=$(date +%s)

    # Launch Java server process with all configured options
    $RUNTIME sh -c "( tail -f \"$AUTH_PIPE\" & cat ) | stdbuf -oL -eL rlwrap -a -N -c java $JAVA_ARGS \
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
    
    EXIT_CODE=$?
    ELAPSED=$(($(date +%s) - START_TIME))
    
    # Return to game directory for next iteration
    cd "$GAME_DIR"
    
    # Exit code 8 = restart to apply update from /update download command
    if [ $EXIT_CODE -eq 8 ]; then
        log_step "Restarting to apply update"
        log_success
        continue
    fi
    
    # Warn on crash shortly after update
    if [ $EXIT_CODE -ne 0 ] && [ "$APPLIED_UPDATE" = true ] && [ $ELAPSED -lt 30 ]; then
        log_error "Server crashed ${ELAPSED}s after update" "Exit code: $EXIT_CODE"
        printf "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
        printf "${YELLOW}Update Failed${NC}\n"
        printf "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n\n"
        printf "Server crashed within ${ELAPSED}s of applying the update.\n"
        printf "This may indicate the update is incompatible.\n\n"
        printf "${DIM}Check logs in: /home/container/Server/logs/${NC}\n\n"
        printf "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    fi
    
    # Any other exit code, stop the container
    exit $EXIT_CODE
done
