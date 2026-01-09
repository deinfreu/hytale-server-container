#!/bin/sh

# Load dependencies
. "$SCRIPTS_PATH/utils.sh"

check_integrity() {
    if [ -f "$SERVER_JAR_PATH" ]; then
        
        PERMS=$(stat -c "%a" "$SERVER_JAR_PATH")
        if [ "$PERMS" != "444" ]; then
            log "Warning: JAR permissions are $PERMS (Expected 444)." "$YELLOW"
            chmod 444 "$SERVER_JAR_PATH" && log "Permissions fixed to 444." "$BLUE"
        else
            log "Security: Server JAR is read-only (444)." "$GREEN"
        fi
    else
        log "CRITICAL: Server JAR missing at $SERVER_JAR_PATH!" "$RED"
        exit 1
    fi
}

check_container_hardening() {
    # NoNewPrivs check
    if grep -q "NoNewPrivs:.*1" /proc/self/status; then
        log "Security: 'no-new-privileges' is ENABLED." "$GREEN"
    else
        log "WARNING: 'no-new-privileges' is NOT enabled!" "$YELLOW"
    fi

    # CapDrop check
    CAP_EFF=$(grep "CapEff:" /proc/self/status | awk '{print $2}')
    if [ "$CAP_EFF" = "0000000000000000" ]; then
        log "Security: 'cap_drop: ALL' is ACTIVE." "$GREEN"
    else
        log "WARNING: Process has kernel capabilities ($CAP_EFF)." "$YELLOW"
    fi

    # Root Check
    if [ "$(id -u)" = "0" ]; then
        log "CRITICAL: Container is running as ROOT!" "$RED"
        exit 1
    fi
}

check_clock_sync() {
    HTTP_STR=$(curl -sI --connect-timeout 3 https://google.com | grep -i '^date:' | cut -d' ' -f2-7)
    if [ -n "$HTTP_STR" ]; then
        CONTAINER_NOW=$(date +%s)
        NETWORK_NOW=$(date -d "$HTTP_STR" +%s)
        DIFF=$((CONTAINER_NOW - NETWORK_NOW))
        ABS_DIFF=${DIFF#-}
        
        if [ "$ABS_DIFF" -gt 60 ]; then
            log "CRITICAL: Clock drift detected! Container is off by $ABS_DIFF seconds." "$RED"
        else
            log "System Time: Synchronized (Drift: ${ABS_DIFF}s)." "$GREEN"
        fi
    else
        log "System Time: Network verification skipped." "$BLUE"
    fi
}