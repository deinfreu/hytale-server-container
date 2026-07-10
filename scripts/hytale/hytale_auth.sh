#!/bin/sh
# Note: Do NOT use set -eu — the background monitoring subshell must not exit on non-zero returns

# Copyright (C) 2026 Daniel Freudenberg
#
# This file is part of github.com/deinfreu/hytale-server-container.
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

generate_hardware_id() {
    HARDWARE_ID_FILE="$BASE_DIR/.hardware-id"

    if [ ! -f "$HARDWARE_ID_FILE" ]; then
        # Generate deterministic UUID from container name + static salt
        CONTAINER_NAME="${HOSTNAME:-hytale-server}"
        SALT="hytale-server-container-hardware-id-v1"
        HASH=$(printf '%s-%s' "$CONTAINER_NAME" "$SALT" | sha256sum | cut -d' ' -f1)
        # RFC 4122 UUID v4: force version=4 at index 12, variant nibble at index 16
        UUID_PART1=$(printf '%s' "$HASH" | cut -c1-8)
        UUID_PART2=$(printf '%s' "$HASH" | cut -c9-12)
        UUID_PART3="4$(printf '%s' "$HASH" | cut -c14-16)"
        UUID_PART4="8$(printf '%s' "$HASH" | cut -c18-20)"
        UUID_PART5=$(printf '%s' "$HASH" | cut -c21-32)
        printf '%s-%s-%s-%s-%s\n' "$UUID_PART1" "$UUID_PART2" "$UUID_PART3" "$UUID_PART4" "$UUID_PART5" > "$HARDWARE_ID_FILE"
    fi

    HARDWARE_ID="$(cat "$HARDWARE_ID_FILE")"
}

check_hardware_id() {
    log_step "Hardware ID"

    if [ -f "/etc/machine-id" ] && [ -s "/etc/machine-id" ]; then
        HARDWARE_ID="$(cat /etc/machine-id)"
        printf "${GREEN}${HARDWARE_ID}${NC}\n"
        log_success

        if [ -f "$BASE_DIR/auth.enc" ]; then
            log_step "Credential Persistence"
            printf "${GREEN}enabled (auth.enc file found)${NC}\n"
            RUN_AUTO_AUTH="FALSE"
        else
            log_step "Credential Persistence"
            printf "${YELLOW}not configured${NC}\n"
        fi
    else
        generate_hardware_id
        printf "${CYAN}${HARDWARE_ID}${NC} (auto-generated)${NC}\n"
        log_success
        printf "    ${DIM}↳ Info:${NC} Stored in ${BASE_DIR}/.hardware-id\n"

        if [ -f "$BASE_DIR/auth.enc" ]; then
            log_step "Credential Persistence"
            printf "${GREEN}enabled (auth.enc file found)${NC}\n"
            RUN_AUTO_AUTH="FALSE"
        else
            log_step "Credential Persistence"
            printf "${YELLOW}not configured${NC}\n"
        fi
    fi
}

start_auth_monitor() {
    (
        # Increased initial wait for ARM64/QEMU emulation overhead
        sleep 10

        AUTH_SELECT_PROFILE="${AUTH_SELECT_PROFILE:-0}"
        LOG_FILE=""
        # Extended retry window for ARM64/QEMU (60 × 2s = 120s vs old 30 × 2s = 60s)
        for i in $(seq 1 60); do
            for f in /home/container/Server/logs/*_server.log; do
                if [ -f "$f" ]; then
                    LOG_FILE="$f"
                    break 2
                fi
            done
            sleep 2
        done

        # Wait for FIFO pipe to be consumed (hytale_start.sh opens it) before monitoring
        _fifo_ready=0
        while [ $_fifo_ready -eq 0 ]; do
            if [ -p "$AUTH_PIPE" ] && [ -f "${LOG_FILE:-/dev/null}" ]; then
                _fifo_ready=1
            else
                sleep 1
            fi
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