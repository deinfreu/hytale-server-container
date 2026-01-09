#!/bin/sh
set -eu

# Load dependencies
. "$SCRIPTS_PATH/utils.sh"

# Configure server.properties (Using $HOME)
if [ ! -f "$PROPERTIES_FILE" ]; then
    log "[init]" "Creating server.properties..." "$CYAN"
    printf "server-ip=%s\nserver-port=%s\nquery.port=%s\n" "$SERVER_IP" "$SERVER_PORT" "$SERVER_PORT" > "$PROPERTIES_FILE"
else
    log "[init]" "Syncing server.properties (Port: $SERVER_PORT)..." "$CYAN"
    sed -i "s/^server-ip=.*/server-ip=$SERVER_IP/" "$PROPERTIES_FILE"
    sed -i "s/^server-port=.*/server-port=$SERVER_PORT/" "$PROPERTIES_FILE"
fi