#!/bin/sh

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
. "${SCRIPTS_PATH:-.}/utils.sh"

check_integrity() {
    log_step "File System Integrity"
    
    if [ -f "${SERVER_JAR_PATH:-}" ]; then
        local perms
        perms=$(stat -c "%a" "$SERVER_JAR_PATH")
        
        if [ "$perms" != "444" ]; then
            log_warning "Insecure JAR permissions ($perms)." "Fixing to Read-Only (444) for protection."
            chmod 444 "$SERVER_JAR_PATH"
        else
            log_success
        fi
    else
        log_error "Server JAR missing!" "Expected at: $SERVER_JAR_PATH"
        exit 1
    fi
}

check_container_hardening() {
    # 1. Privileges check
    log_step "Process Privileges"
    if grep -q "NoNewPrivs:.*1" /proc/self/status 2>/dev/null; then
        log_success
    else
        log_warning "NoNewPrivs disabled." "Container could allow privilege escalation. Use --security-opt=no-new-privileges."
    fi

    # 2. Kernel Capabilities
    log_step "Kernel Capabilities"
    local cap_eff
    cap_eff=$(grep "CapEff:" /proc/self/status | awk '{print $2}' || echo "unknown")
    if [ "$cap_eff" = "0000000000000000" ]; then
        log_success
    else
        log_warning "Extra capabilities found." "Process has kernel caps ($cap_eff). Consider 'cap_drop: ALL'."
    fi

    # 3. User Identity Check
    log_step "Non-Root Enforcement"
    if [ "$(id -u)" = "0" ]; then
        log_error "Running as ROOT!" "Game servers should never run as root. Set 'user: 1000:1000' in Docker Compose."
        # log_error will handle exit based on DEBUG mode
    else
        log_success
    fi
}

check_clock_sync() {
    log_step "Network Time Sync"
    
    # Extract date from header safely
    local http_date
    http_date=$(curl -sI --connect-timeout 3 https://google.com | grep -i '^date:' | cut -d' ' -f2- || echo "")
    
    if [ -n "$http_date" ]; then
        local container_now network_now diff abs_diff
        
        # Ensure we're comparing UTC times
        container_now=$(TZ=UTC date +%s)
        
        # BusyBox date doesn't support -d flag, try GNU date first, fallback to BusyBox format
        if network_now=$(TZ=UTC date -d "$http_date" +%s 2>/dev/null); then
            # GNU date succeeded
            :
        elif network_now=$(TZ=UTC date -D "%a, %d %b %Y %H:%M:%S" -d "$http_date" +%s 2>/dev/null); then
            # BusyBox date with explicit format
            :
        else
            # Fallback: skip the check if parsing fails
            log_warning "Time check skipped." "Could not parse network time format."
            return
        fi
        
        diff=$((container_now - network_now))
        abs_diff=${diff#-} # Absolute value
        
        if [ "$abs_diff" -gt 60 ]; then
            log_error "Clock drift detected!" "Container is off by ${abs_diff}s. This causes SSL and Auth failures."
            # log_error will handle exit based on DEBUG mode
        else
            log_success
            echo -e "      ${DIM}↳ Drift: ${abs_diff}s (within acceptable limits)${NC}"
        fi
    else
        log_warning "Time check skipped." "Could not reach Google to verify network time."
    fi
}