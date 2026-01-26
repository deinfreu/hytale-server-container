#!/bin/sh
set -eu

# Hytale Server Permissions Manager - Manages whitelist.json, permissions.json, and bans.json

# Load dependencies
. "$SCRIPTS_PATH/utils.sh"

# Constants
readonly WHITELIST_FILE="${BASE_DIR:-/home/container}/whitelist.json"
readonly PERMISSIONS_FILE="${BASE_DIR:-/home/container}/permissions.json"
readonly BANS_FILE="${BASE_DIR:-/home/container}/bans.json"

# Create default whitelist template
create_default_whitelist() {
    cat <<'EOF' > "$WHITELIST_FILE"
{
    "enabled": false,
    "list": []
}
EOF
}

# Create default permissions template
create_default_permissions() {
    cat <<'EOF' > "$PERMISSIONS_FILE"
{
    "users": {},
    "groups": {
        "Default": [],
        "OP": ["*"]
    }
}
EOF
}

# Create default bans template
create_default_bans() {
    echo '[]' > "$BANS_FILE"
}

# Validate JSON file
validate_json() {
    local file="$1"
    jq empty "$file" >/dev/null 2>&1
}

# Add UUID to OP group in permissions.json
add_op() {
    local uuid="$1"
    local tmp_file="${PERMISSIONS_FILE}.tmp"
    
    # Check if user already exists
    if jq -e ".users[\"$uuid\"]" "$PERMISSIONS_FILE" >/dev/null 2>&1; then
        # User exists, add OP to their groups if not already present
        if ! jq -e ".users[\"$uuid\"].groups | index(\"OP\")" "$PERMISSIONS_FILE" >/dev/null 2>&1; then
            jq ".users[\"$uuid\"].groups += [\"OP\"]" "$PERMISSIONS_FILE" > "$tmp_file"
            mv -f "$tmp_file" "$PERMISSIONS_FILE"
        fi
    else
        # User doesn't exist, create with OP group
        jq ".users[\"$uuid\"] = {\"groups\": [\"OP\"]}" "$PERMISSIONS_FILE" > "$tmp_file"
        mv -f "$tmp_file" "$PERMISSIONS_FILE"
    fi
}

# Add UUID to whitelist
add_to_whitelist() {
    local uuid="$1"
    local tmp_file="${WHITELIST_FILE}.tmp"
    
    # Check if UUID already in list
    if ! jq -e ".list | index(\"$uuid\")" "$WHITELIST_FILE" >/dev/null 2>&1; then
        jq ".list += [\"$uuid\"]" "$WHITELIST_FILE" > "$tmp_file"
        mv -f "$tmp_file" "$WHITELIST_FILE"
    fi
}

# Main Permissions Logic
log_section "Server Access Management"

# --- Whitelist Management ---
log_step "Whitelist configuration"

if [ ! -f "$WHITELIST_FILE" ]; then
    create_default_whitelist
    printf "${DIM}created default${NC}\n"
elif ! validate_json "$WHITELIST_FILE"; then
    printf "${YELLOW}⚠ Invalid JSON, recreating${NC}\n"
    mv -f "$WHITELIST_FILE" "${WHITELIST_FILE}.invalid.bak"
    create_default_whitelist
else
    printf "${GREEN}exists${NC}\n"
fi

# Apply whitelist enabled setting
if [ -n "${HYTALE_WHITELIST_ENABLED:-}" ]; then
    log_step "  Whitelist enabled"
    tmp_file="${WHITELIST_FILE}.tmp"
    case "${HYTALE_WHITELIST_ENABLED}" in
        true|TRUE|1|yes|YES)
            jq '.enabled = true' "$WHITELIST_FILE" > "$tmp_file"
            mv -f "$tmp_file" "$WHITELIST_FILE"
            printf "${GREEN}true${NC}\n"
            ;;
        false|FALSE|0|no|NO)
            jq '.enabled = false' "$WHITELIST_FILE" > "$tmp_file"
            mv -f "$tmp_file" "$WHITELIST_FILE"
            printf "${DIM}false${NC}\n"
            ;;
        *)
            printf "${YELLOW}invalid value: %s${NC}\n" "$HYTALE_WHITELIST_ENABLED"
            ;;
    esac
fi

# Add UUIDs to whitelist from env var (comma-separated)
if [ -n "${HYTALE_WHITELIST:-}" ]; then
    log_step "  Adding to whitelist"
    count=0
    # Split by comma and process each UUID
    echo "$HYTALE_WHITELIST" | tr ',' '\n' | while read -r uuid; do
        uuid=$(echo "$uuid" | tr -d ' ')  # Trim whitespace
        if [ -n "$uuid" ]; then
            add_to_whitelist "$uuid"
            count=$((count + 1))
        fi
    done
    printf "${GREEN}%s UUID(s)${NC}\n" "$(echo "$HYTALE_WHITELIST" | tr ',' '\n' | grep -c .)"
fi

# --- Permissions Management ---
log_step "Permissions configuration"

if [ ! -f "$PERMISSIONS_FILE" ]; then
    create_default_permissions
    printf "${DIM}created default${NC}\n"
elif ! validate_json "$PERMISSIONS_FILE"; then
    printf "${YELLOW}⚠ Invalid JSON, recreating${NC}\n"
    mv -f "$PERMISSIONS_FILE" "${PERMISSIONS_FILE}.invalid.bak"
    create_default_permissions
else
    printf "${GREEN}exists${NC}\n"
fi

# Add OPs from env var (comma-separated UUIDs)
if [ -n "${HYTALE_OPS:-}" ]; then
    log_step "  Adding operators"
    count=0
    echo "$HYTALE_OPS" | tr ',' '\n' | while read -r uuid; do
        uuid=$(echo "$uuid" | tr -d ' ')  # Trim whitespace
        if [ -n "$uuid" ]; then
            add_op "$uuid"
            count=$((count + 1))
        fi
    done
    printf "${GREEN}%s UUID(s)${NC}\n" "$(echo "$HYTALE_OPS" | tr ',' '\n' | grep -c .)"
fi

# --- Bans Management ---
log_step "Bans configuration"

if [ ! -f "$BANS_FILE" ]; then
    create_default_bans
    printf "${DIM}created default${NC}\n"
elif ! validate_json "$BANS_FILE"; then
    printf "${YELLOW}⚠ Invalid JSON, recreating${NC}\n"
    mv -f "$BANS_FILE" "${BANS_FILE}.invalid.bak"
    create_default_bans
else
    printf "${GREEN}exists${NC}\n"
fi

# Display current status
printf "\n"
log_step "Whitelist status"
if [ -f "$WHITELIST_FILE" ]; then
    enabled=$(jq -r '.enabled' "$WHITELIST_FILE" 2>/dev/null || echo "false")
    count=$(jq -r '.list | length' "$WHITELIST_FILE" 2>/dev/null || echo "0")
    if [ "$enabled" = "true" ]; then
        printf "${GREEN}enabled${NC} (%s players)\n" "$count"
    else
        printf "${DIM}disabled${NC} (%s players)\n" "$count"
    fi
fi

log_step "Operators"
if [ -f "$PERMISSIONS_FILE" ]; then
    op_count=$(jq -r '[.users | to_entries[] | select(.value.groups | index("OP"))] | length' "$PERMISSIONS_FILE" 2>/dev/null || echo "0")
    printf "${GREEN}%s${NC} player(s)\n" "$op_count"
fi

log_step "Banned players"
if [ -f "$BANS_FILE" ]; then
    ban_count=$(jq -r 'length' "$BANS_FILE" 2>/dev/null || echo "0")
    printf "${GREEN}%s${NC}\n" "$ban_count"
fi
