#!/bin/sh
set -eu

# Configuration defaults
SCRIPTS_PATH="/usr/local/bin/scripts"
PROPERTIES_FILE="server.properties"
SERVER_PORT="${SERVER_PORT:-25565}"
SERVER_IP="${SERVER_IP:-0.0.0.0}"
AUTO_UPDATE="${AUTO_UPDATE:-false}"
MINECRAFT="${MINECRAFT:-FALSE}"

# Load utilities (like the 'log' function)
. "$SCRIPTS_PATH/utils.sh"

# Minecraft Fallback Logic
if [ "$MINECRAFT" = "TRUE" ]; then
    # Default name if we need to download a new one
    SERVER_JAR_PATH="/home/container/server.jar"
    
    echo "🎮 MINECRAFT=TRUE: Searching for any *server*.jar in root..."

    # Check if any file matching *server*.jar exists
    # We use a subshell to avoid errors if no file is found
    FOUND_JAR=$(ls /home/container/*server*.jar 2>/dev/null | head -n 1)

    if [ -z "$FOUND_JAR" ]; then
        echo "📥 No server JAR found. Downloading Minecraft Server..."
        
        curl -L -o "$SERVER_JAR_PATH" https://piston-data.mojang.com/v1/objects/84100236a2829286d11da9287c88019e34c919d7/server.jar
        
        # Set to Read-Only
        chmod 444 "$SERVER_JAR_PATH"
        echo "🔒 File protections enabled: Read-only (server.jar)"
    else
        echo "✅ Found existing JAR: $FOUND_JAR"
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