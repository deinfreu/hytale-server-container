#!/bin/sh
set -eu

# ==============================================================================
# This is the 
# ==============================================================================

PROPERTIES_FILE="${HOME}/server.properties"
SERVER_IP=${SERVER_IP:-0.0.0.0}
SERVER_PORT=${SERVER_PORT:-25565}

# Colors
CYAN="\033[0;36m"
GREEN="\033[0;32m"
RED="\033[0;31m"
RESET="\033[0m"

log() { echo "${3:-$RESET}[start-hytale] $2${RESET}"; }

log "[init]" "Starting Hytale container for user: $USER" "$CYAN"

# 1. EULA Check (Redirected to $HOME)
case "$EULA" in
    [Tt][Rr][Uu][Ee])
        log "[init]" "Accepting EULA..." "$GREEN"
        echo "eula=true" > "${HOME}/eula.txt"
        ;;
    *)
        if [ ! -f "${HOME}/eula.txt" ] || ! grep -q "eula=true" "${HOME}/eula.txt"; then
            log "[error]" "EULA=true environment variable required." "$RED"
            exit 1
        fi
        ;;
esac

# 2. Configure server.properties (Using $HOME)
if [ ! -f "$PROPERTIES_FILE" ]; then
    log "[init]" "Creating server.properties..." "$CYAN"
    printf "server-ip=%s\nserver-port=%s\nquery.port=%s\n" "$SERVER_IP" "$SERVER_PORT" "$SERVER_PORT" > "$PROPERTIES_FILE"
else
    log "[init]" "Syncing server.properties (Port: $SERVER_PORT)..." "$CYAN"
    sed -i "s/^server-ip=.*/server-ip=$SERVER_IP/" "$PROPERTIES_FILE"
    sed -i "s/^server-port=.*/server-port=$SERVER_PORT/" "$PROPERTIES_FILE"
fi

# 3. Audits
/usr/local/bin/security-check.sh
/usr/local/bin/network-check.sh

# 4. Pterodactyl Variable Parsing
# Converts {{SERVER_MEMORY}} etc. into usable bash values
MODIFIED_STARTUP=$(eval echo $(echo ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g'))

# 5. Execution
# We use 'exec' so Java receives the shutdown signals from Pterodactyl
log "[status]" "Running: $MODIFIED_STARTUP" "$GREEN"
exec ${MODIFIED_STARTUP}