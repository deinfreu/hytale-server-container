#!/bin/sh
# Note: Do NOT use set -eu — the background monitoring subshell must not exit on non-zero returns

# ==========================================
# HELPER FUNCTIONS
# ==========================================

init_auth_pipes() {
    AUTH_PIPE="/tmp/hytale-console.in"
    AUTH_OUTPUT_LOG="/tmp/hytale-server.log"
    rm -f "$AUTH_PIPE" "$AUTH_OUTPUT_LOG"
    mkfifo "$AUTH_PIPE"
    touch "$AUTH_OUTPUT_LOG"
    export AUTH_PIPE
    export AUTH_OUTPUT_LOG
}

check_hardware_id() {
    log_step "Hardware ID"
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
}

start_auth_monitor() {
    (
        sleep 5

        LOG_FILE=""
        for i in $(seq 1 30); do
            for f in /home/container/Server/logs/*_server.log; do
                if [ -f "$f" ]; then
                    LOG_FILE="$f"
                    break 2
                fi
            done
            sleep 2
        done

        if [ -n "$LOG_FILE" ] && [ -f "$LOG_FILE" ]; then
            tail -F "$LOG_FILE" 2>/dev/null | while IFS= read -r line || [ -n "$line" ]; do
                case "$line" in
                    *"Hytale Server Booted!"*)
                        sleep 2
                        echo "/auth login device" > "$AUTH_PIPE" 2>/dev/null || true
                        ;;
                esac

                case "$line" in
                    *"Multiple profiles available"*)
                        sleep 1
                        echo "/auth select $AUTH_SELECT_PROFILE" > "$AUTH_PIPE" 2>/dev/null || true
                        ;;
                esac

                case "$line" in
                    *"Authentication successful!"*|*"Server is already authenticated."*)
                        sleep 1
                        echo "/auth persistence Encrypted" > "$AUTH_PIPE" 2>/dev/null || true
                        break
                        ;;
                esac
            done
        fi
    ) &
    AUTH_PID=$!
}

# ==========================================
# MAIN EXECUTION FLOW
# ==========================================

log_section "Authentication Management"

RUN_AUTO_AUTH="TRUE"

init_auth_pipes
check_hardware_id

if [ "$RUN_AUTO_AUTH" = "TRUE" ]; then
    start_auth_monitor
fi

printf "\n"