#!/bin/sh
set -eu

# Preload auth commands into the server console after the server signals readiness
# Skip auto-auth if credentials are already persisted AND hardware ID matches
log_section "Authentication Management"

AUTH_PIPE="/tmp/hytale-console.in"
AUTH_OUTPUT_LOG="/tmp/hytale-server.log"
rm -f "$AUTH_PIPE" "$AUTH_OUTPUT_LOG"
mkfifo "$AUTH_PIPE"
touch "$AUTH_OUTPUT_LOG"

# Export for use in parent script
export AUTH_PIPE
export AUTH_OUTPUT_LOG

# First check if /etc/machine-id exists
log_step "Checking Hardware ID"
if [ ! -f "/etc/machine-id" ]; then
    log_warning "Hardware ID not found" "Mount /etc/machine-id:/etc/machine-id:ro to enable encrypted credential persistence"
    printf "      ${DIM}↳ Info:${NC} Auto-auth will run on every startup without it\n"
elif [ -z "$(cat /etc/machine-id 2>/dev/null | tr -d '\n' | tr -d '\r')" ]; then
    log_warning "Hardware ID file is empty" "Ensure /etc/machine-id contains a valid machine identifier"
elif [ -f "$BASE_DIR/auth.enc" ]; then
    log_success
    log_step "Credential Persistence"
    printf "${GREEN}enabled (auth.enc file found)${NC}\n"
    RUN_AUTO_AUTH=FALSE
else
    log_success
    log_step "Credential Persistence"
    printf "${YELLOW}not configured${NC}\n"
fi

if [ "$RUN_AUTO_AUTH" = "TRUE" ]; then
    (
        tail -n0 -F "$AUTH_OUTPUT_LOG" | while IFS= read -r line; do
            case "$line" in
                *"$HYTALE_AUTH_READY_PATTERN"*|*"$HYTALE_AUTH_READY_ALT_PATTERN"*)
                    {
                        printf "auth persistence Encrypted\n"
                        printf "auth login device\n"
                    } > "$AUTH_PIPE"
                    break
                    ;;
            esac
        done
    ) &
fi

printf "\n"
