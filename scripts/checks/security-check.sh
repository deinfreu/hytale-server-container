#!/bin/sh
set -eu

# Colors
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
RESET="\033[0m"

SERVER_PATH="/usr/local/lib/server.jar"

log() { echo "${2:-$RESET}[security-check] $1${RESET}"; }


# 1. Integrity & Permissions Check
if [ -f "$SERVER_PATH" ]; then
    # SHA256 Verification
    # Note: sha256sum -c requires EXACTLY two spaces between the hash and the path
    if [ -n "${SERVER_JAR_SHA256:-}" ]; then
        if echo "${SERVER_JAR_SHA256}  ${SERVER_PATH}" | sha256sum -c - >/dev/null 2>&1; then
            log "Security: SHA256 matches." "$GREEN"
        else
            log "CRITICAL: SHA256 mismatch! File may be corrupted or tampered with." "$RED"
            exit 1
        fi
    fi
    
    # Check if JAR is Read-Only (Safety from tampering)
    # Using string comparison '!=' instead of '-ne' for better compatibility
    PERMS=$(stat -c "%a" "$SERVER_PATH")
    if [ "$PERMS" != "444" ]; then
        log "Warning: JAR permissions are $PERMS (Expected 444)." "$YELLOW"
        # Since we are likely the owner or have gosu/root entry, we fix it
        chmod 444 "$SERVER_PATH" && log "Permissions fixed to 444." "$BLUE"
    else
        log "Security: Server JAR is read-only (444)." "$GREEN"
    fi
else
    log "CRITICAL: Server JAR missing at $SERVER_PATH!" "$RED"
    exit 1
fi

# 2. Check for 'no-new-privileges:true'
# In /proc/self/status, NoNewPrivs: 1 means it is enabled.
if grep -q "NoNewPrivs:.*1" /proc/self/status; then
    log "Security: 'no-new-privileges' is ENABLED." "$GREEN"
else
    log "WARNING: 'no-new-privileges' is NOT enabled in docker-compose!" "$YELLOW"
fi

# 3. Check for 'cap_drop: ALL'
# CapEff: 0000000000000000 means the process has zero kernel capabilities.
CAP_EFF=$(grep "CapEff:" /proc/self/status | awk '{print $2}')
if [ "$CAP_EFF" = "0000000000000000" ]; then
    log "Security: 'cap_drop: ALL' is ACTIVE." "$GREEN"
else
    log "WARNING: Process has kernel capabilities ($CAP_EFF). 'cap_drop: ALL' is missing!" "$YELLOW"
fi

# 4. Identity Check
if [ "$(id -u)" = "0" ]; then
    log "CRITICAL: Container is running as ROOT! Fix: 'user: 1000:1000' in compose." "$RED"
    exit 1
fi

# 12. Clock & Timezone Check
# Checks if container time is roughly synchronized with a web header.
# Essential for WSL2 users where the clock often "freezes" after Windows sleep.
HTTP_STR=$(curl -sI --connect-timeout 3 https://google.com | grep -i '^date:' | cut -d' ' -f2-7)

if [ -n "$HTTP_STR" ]; then
    # Convert both to Unix Timestamps
    CONTAINER_NOW=$(date +%s)
    NETWORK_NOW=$(date -d "$HTTP_STR" +%s)
    
    # Calculate absolute difference
    DIFF=$((CONTAINER_NOW - NETWORK_NOW))
    ABS_DIFF=${DIFF#-} # Remove negative sign if it exists
    
    if [ "$ABS_DIFF" -gt 60 ]; then
        log "CRITICAL: Clock drift detected! Container is off by $ABS_DIFF seconds." "$RED"
    else
        log "System Time: Synchronized with network (Drift: ${ABS_DIFF}s)." "$GREEN"
    fi
else
    log "System Time: Network verification skipped (Google unreachable)." "$BLUE"
fi

log "Security audit finished." "$GREEN"
exit 0