#!/bin/sh
set -eu

# ===============================
# start-hytale.sh start script for Hytale server
# Fully /bin/sh compatible
# ===============================

PROPERTIES_FILE="/data/server.properties"
SERVER_IP=${SERVER_IP:-0.0.0.0}
SERVER_PORT=${SERVER_PORT:-25565}

# Colors
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
CYAN="\033[0;36m"
RESET="\033[0m"

log() { 
    # Usage: log "MESSAGE" "COLOR"
    local script="$1"
    local msg="$2"
    local color="${3:-$RESET}"  # default color is RESET
    echo "${color}${script} ${msg}${RESET}"
}

log "Starting Hytale container" "$CYAN"

# 1. Check and set the eula.txt file
case "$EULA" in
    [Tt][Rr][Uu][Ee])
        echo "[start-hytale] EULA environment variable detected as 'true'. Writing eula.txt..."
        echo "eula=true" > /data/eula.txt
        ;;
    *)
        # If EULA isn't true in ENV, check if the file already exists and is true
        if [ ! -f "/data/eula.txt" ] || ! grep -q "eula=true" /data/eula.txt; then
            echo "[start-hytale] ERROR: You must accept the Hytale EULA to start the server." "$GREEN"
            echo "[start-hytale] Set the environment variable EULA=true" "$RED"
            exit 1
        fi
        ;;
esac

# 2. Configure server.properties
if [ ! -f "$PROPERTIES_FILE" ]; then
    echo "[start-hytale] Creating new server.properties..."
    {
        echo "server-ip=$SERVER_IP"
        echo "server-port=$SERVER_PORT"
        echo "query.port=$SERVER_PORT"
    } > "$PROPERTIES_FILE"
else
    echo "[start-hytale] Synchronizing server.properties (IP=$SERVER_IP, Port=$SERVER_PORT)..."
    
    # Update IP
    if grep -q "server-ip=" "$PROPERTIES_FILE"; then
        # Using double quotes so $SERVER_IP is expanded
        sed -i "s/^server-ip=.*/server-ip=$SERVER_IP/" "$PROPERTIES_FILE"
    else
        echo "server-ip=$SERVER_IP" >> "$PROPERTIES_FILE"
    fi

    # Update Port
    if grep -q "server-port=" "$PROPERTIES_FILE"; then
        sed -i "s/^server-port=.*/server-port=$SERVER_PORT/" "$PROPERTIES_FILE"
    else
        echo "server-port=$SERVER_PORT" >> "$PROPERTIES_FILE"
    fi
fi

# 3. Mandatory Security & Network Audit
# These are fast and catch 90% of boot failures (Time drift, Permissions)
log "[audit]" "Running essential pre-flight checks..." "$CYAN"
/usr/local/bin/security-check.sh
/usr/local/bin/network-check.sh

# 4. Production Deep Audit
if [ "${PROD:-false}" = "true" ]; then
    log "[audit]" "PRODUCTION mode: Running deep hardware/kernel audit..." "$CYAN"
    /usr/local/bin/prod-check.sh
fi

# 5. Start Hytale server - Exec ensures Java captures SIGTERM for graceful shutdown
log "Starting Hytale server..." "$GREEN"
exec java $JAVA_OPTS -jar /usr/local/lib/server.jar