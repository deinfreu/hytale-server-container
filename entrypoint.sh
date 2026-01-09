#!/bin/sh
set -eu

# Configuration defaults
export SCRIPTS_PATH="/usr/local/bin/scripts"
export PROPERTIES_FILE="server.properties"
export SERVER_PORT="${SERVER_PORT:-25565}"
export SERVER_IP="${SERVER_IP:-0.0.0.0}"
export AUTO_UPDATE="${AUTO_UPDATE:-false}"
export MINECRAFT="${MINECRAFT:-FALSE}"
export SERVER_JAR_PATH="/home/container/server.jar"

# Load utilities (like the 'log' function)
. "$SCRIPTS_PATH/utils.sh"

# Minecraft Fallback Logic
if [ "$MINECRAFT" = "TRUE" ]; then    
    log "[system]" "MINECRAFT=TRUE: Searching for JAR..." "$YELLOW"

    # Check if any file matching *server*.jar exists
    # We use a subshell to avoid errors if no file is found
    FOUND_JAR=$(ls /home/container/*server*.jar 2>/dev/null | head -n 1)

    if [ -z "$FOUND_JAR" ]; then
        log "[download]" "No JAR found. Downloading Minecraft Server..." "$CYAN"
        
        curl -L -o "$SERVER_JAR_PATH" https://piston-data.mojang.com/v1/objects/84100236a2829286d11da9287c88019e34c919d7/server.jar
        
        # Set to Read-Only
        chmod 444 "$SERVER_JAR_PATH"
    else
        log "[system]" "Found existing JAR: $FOUND_JAR" "$GREEN"
        SERVER_JAR_PATH="$FOUND_JAR"
    fi
fi

# 1. Config & EULA
sh "$SCRIPTS_PATH/hytale/server-properties.sh"
sh "$SCRIPTS_PATH/hytale/eula.sh"

# 2. Audits
sh "$SCRIPTS_PATH/checks/network.sh"
sh "$SCRIPTS_PATH/checks/security.sh"

# 3. Pterodactyl Variable Parsing
DEFAULT_STARTUP="java ${JAVA_OPTS:- -Xms128M -Xmx2048M} -jar $SERVER_JAR_PATH"
STARTUP_CMD="${STARTUP:-$DEFAULT_STARTUP}"

# Convert Pterodactyl's {{VARIABLE}} to shell ${VARIABLE} and eval it
MODIFIED_STARTUP=$(eval echo $(echo "$STARTUP_CMD" | sed -e 's/{{/${/g' -e 's/}}/}/g'))

# 4. Execution
log "🚀 Starting Server..." "$GREEN" "status"
exec $MODIFIED_STARTUP