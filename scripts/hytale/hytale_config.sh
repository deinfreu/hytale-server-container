#!/bin/sh
set -eu

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

# Constants
readonly CONFIG_FILE="${BASE_DIR:-/home/container}/config.json"
readonly CONFIG_BACKUP_SUFFIX=".invalid.bak"
readonly CONFIG_TMP_SUFFIX=".tmp"

# ==========================================
# HELPER FUNCTIONS
# ==========================================

create_default_config() {
    cat <<'EOF' > "$CONFIG_FILE"
{
    "Version": 3,
    "ServerName": "Hytale Server",
    "MOTD": "",
    "Password": "",
    "MaxPlayers": 100,
    "MaxViewRadius": 32,
    "LocalCompressionEnabled": false,
    "Defaults": { 
        "World": "default", 
        "GameMode": "Adventure" 
    },
    "ConnectionTimeouts": { 
        "JoinTimeouts": {} 
    },
    "RateLimit": {},
    "Modules": {},
    "LogLevels": {},
    "Mods": {},
    "DisplayTmpTagsInStrings": false,
    "PlayerStorage": { 
        "Type": "Hytale" 
    }
}
EOF
}

validate_config_json() {
    jq empty "$CONFIG_FILE" >/dev/null 2>&1
}

apply_env() {
    local path="$1"
    local value="$2"
    local value_type="${3:-auto}"
    local tmp_file="${CONFIG_FILE}${CONFIG_TMP_SUFFIX}"

    [ -z "$value" ] && return 0

    case "$value_type" in
        string)
            jq "$path = \"$value\"" "$CONFIG_FILE" > "$tmp_file" 2>/dev/null || {
                printf "      ${YELLOW}⚠ Failed to apply %s${NC}\n" "$path"; rm -f "$tmp_file"; return 1
            }
            ;;
        number)
            jq "$path = ($value | tonumber)" "$CONFIG_FILE" > "$tmp_file" 2>/dev/null || {
                printf "      ${YELLOW}⚠ Failed to apply %s (invalid number)${NC}\n" "$path"; rm -f "$tmp_file"; return 1
            }
            ;;
        boolean)
            case "$value" in
                true|TRUE|1|yes|YES) jq "$path = true" "$CONFIG_FILE" > "$tmp_file" 2>/dev/null || { printf "      ${YELLOW}⚠ Failed to apply %s${NC}\n" "$path"; rm -f "$tmp_file"; return 1; } ;;
                false|FALSE|0|no|NO)  jq "$path = false" "$CONFIG_FILE" > "$tmp_file" 2>/dev/null || { printf "      ${YELLOW}⚠ Failed to apply %s${NC}\n" "$path"; rm -f "$tmp_file"; return 1; } ;;
                *) printf "      ${YELLOW}⚠ Invalid boolean value for %s: %s${NC}\n" "$path" "$value"; return 1 ;;
            esac
            ;;
        auto)
            case "$value" in
                true|false) jq "$path = $value" "$CONFIG_FILE" > "$tmp_file" 2>/dev/null || { printf "      ${YELLOW}⚠ Failed to apply %s${NC}\n" "$path"; rm -f "$tmp_file"; return 1; } ;;
                *)          jq "$path = \"$value\"" "$CONFIG_FILE" > "$tmp_file" 2>/dev/null || { printf "      ${YELLOW}⚠ Failed to apply %s${NC}\n" "$path"; rm -f "$tmp_file"; return 1; } ;;
            esac
            ;;
    esac

    mv -f "$tmp_file" "$CONFIG_FILE"
}

display_config_value() {
    local label="$1"
    local jq_path="$2"
    local default_val="$3"
    local color="${4:-GREEN}"

    log_step "$label"
    local value=$(jq -r "$jq_path" "$CONFIG_FILE" 2>/dev/null || echo "$default_val")
    if [ -n "$value" ] && [ "$value" != "null" ]; then
        printf "${color}%s${NC}\n" "$value"
    else
        case "$label" in *"Password"*) printf "${DIM}disabled${NC}\n" ;; *) printf "${DIM}not set${NC}\n" ;; esac
    fi
}

# ==========================================
# MAIN EXECUTION FLOW
# ==========================================

log_section "Server Configuration Management"

# Step 1: Ensure configuration file exists
if [ ! -f "$CONFIG_FILE" ]; then
    log_step "Generating new config"; create_default_config; log_success
else
    log_step "Updating existing config"
    if ! validate_config_json; then
        printf "      ${YELLOW}⚠ Invalid JSON detected. Backing up and recreating...${NC}\n"
        mv -f "$CONFIG_FILE" "${CONFIG_FILE}${CONFIG_BACKUP_SUFFIX}"
        create_default_config
    fi
    log_success
fi

# Step 2: Apply environment variable overrides
log_step "Applying environment overrides"
apply_env ".ServerName"               "${HYTALE_SERVER_NAME:-}"       "string"
apply_env ".MOTD"                     "${HYTALE_MOTD:-}"              "string"
apply_env ".Password"                 "${HYTALE_PASSWORD:-}"          "string"
apply_env ".MaxPlayers"               "${HYTALE_MAX_PLAYERS:-}"       "number"
apply_env ".MaxViewRadius"            "${HYTALE_MAX_VIEW_RADIUS:-}"   "number"
apply_env ".LocalCompressionEnabled"  "${HYTALE_COMPRESSION:-}"       "boolean"
apply_env ".Defaults.World"           "${HYTALE_WORLD:-}"             "string"
apply_env ".Defaults.GameMode"        "${HYTALE_GAMEMODE:-}"          "string"
log_success

# Step 3: Display configuration summary
printf "\n"
display_config_value "Config Version"            ".Version"                            "3"       ""
display_config_value "Server Name"              ".ServerName"                         "Hytale Server"
display_config_value "MOTD"                     ".MOTD"                               ""
display_config_value "Password Protection"      ".Password"                           ""
display_config_value "Max Players"              ".MaxPlayers"                         "100"
display_config_value "Max View Radius"          ".MaxViewRadius"                      "12"

log_step "Local Compression"
COMPRESSION=$(jq -r '.LocalCompressionEnabled' "$CONFIG_FILE" 2>/dev/null || echo "false")
[ "$COMPRESSION" = "true" ] && printf "${GREEN}enabled${NC}\n" || printf "${DIM}disabled${NC}\n"

display_config_value "Default World"     ".Defaults.World"     "default"
display_config_value "Default Game Mode" ".Defaults.GameMode"  "Adventure"