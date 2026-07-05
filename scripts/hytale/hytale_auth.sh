#!/bin/sh
set -eu

# Preload auth commands into the server console after the server signals readiness
# Skip auto-auth if credentials are already persisted AND hardware ID matches
log_section "Authentication Management"

# Initialize variable default
RUN_AUTO_AUTH="TRUE"

AUTH_PIPE="/tmp/hytale-console.in"
AUTH_OUTPUT_LOG="/tmp/hytale-server.log"
rm -f "$AUTH_PIPE" "$AUTH_OUTPUT_LOG"
mkfifo "$AUTH_PIPE"
touch "$AUTH_OUTPUT_LOG"

# Export for use in parent script
export AUTH_PIPE
export AUTH_OUTPUT_LOG

# Verify if a user-defined hardware environment ID exists; required for authentication persistence.
log_step "Checking Hardware ID"
if [ ! -f "/etc/machine-id" ]; then
    log_warning "Hardware ID not found" "Mount /etc/machine-id:/etc/machine-id:ro to enable encrypted credential persistence"
    printf "    ${DIM}↳ Info:${NC} Auto-auth will run on every startup without it\n"
elif [ ! -s "/etc/machine-id" ]; then
    log_warning "Hardware ID file is empty" "Ensure /etc/machine-id contains a valid machine identifier"
elif [ -f "$BASE_DIR/auth.enc" ]; then
    log_success
    log_step "Credential Persistence"
    printf "${GREEN}enabled (auth.enc file found)${NC}\n"
    RUN_AUTO_AUTH="FALSE"
else
    log_success
    log_step "Credential Persistence"
    printf "${YELLOW}not configured${NC}\n"
fi

# If auto-authentication is enabled, automatically execute the login command.
if [ "$RUN_AUTO_AUTH" = "TRUE" ]; then
    # Monitor logs and send auth command when ready
    (
        # Wait for the server to start creating the log file
        sleep 5
        
        # Target the new log directory and grab the most recent *_server.log file
        LOG_FILE=$(ls -t /home/container/Server/logs/*_server.log 2>/dev/null | head -n 1)
        
        if [ -n "${LOG_FILE:-}" ]; then
            stdbuf -oL tail -f "$LOG_FILE" | while read -r line; do
                
                # 1. Look for the boot confirmation to send the login command
                if echo "$line" | grep -q "Hytale Server Booted!"; then
                    sleep 2
                    echo "/auth login device" > "$AUTH_PIPE"
                    printf "[%s] ✔ Sent auth command to server\n" "$(date '+%H:%M:%S')" >> /tmp/hytale_auth.log
                fi

                # 2. Handle profile selection if prompted
                if echo "$line" | grep -q "Multiple profiles available"; then
                    sleep 1
                    echo "/auth select $AUTH_SELECT_PROFILE" > "$AUTH_PIPE"
                    printf "[%s] ✔ Selected profile %s\n" "$(date '+%H:%M:%S')" "$AUTH_SELECT_PROFILE" >> /tmp/hytale_auth.log
                fi

                # 3. Check for successful auth, set persistence, and exit the loop
                if echo "$line" | grep -qE "Authentication successful!|Server is already authenticated."; then
                    sleep 1
                    echo "/auth persistence Encrypted" > "$AUTH_PIPE"
                    printf "[%s] ✔ Sent persistence command to server\n" "$(date '+%H:%M:%S')" >> /tmp/hytale_auth.log
                    break # Stops the tail process since auth is complete
                fi
                
            done
        fi
    ) &
    AUTH_PID=$!
fi

printf "\n"