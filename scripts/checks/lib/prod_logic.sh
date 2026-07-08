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

check_java_mem() {
    log_section "Memory Integrity"
    
    # Extract Xmx value safely
    local xmx_raw=$(echo "${JAVA_ARGS:-}" | grep -oE 'Xmx[0-9]+[gGmM]' | tr -d 'Xmx' || echo "")
    local xmx_num=$(echo "$xmx_raw" | grep -oE '[0-9]+' || echo "0")
    local xmx_unit=$(echo "$xmx_raw" | grep -oE '[gGmM]' || echo "m")

    local xmx_mb=0
    if [ "$xmx_num" -gt 0 ]; then
        [[ "$xmx_unit" =~ [gG] ]] && xmx_mb=$((xmx_num * 1024)) || xmx_mb=$xmx_num
    fi

    # Detect Docker/Cgroup Limits
    local mem_limit_file=""
    [ -f "/sys/fs/cgroup/memory.max" ] && mem_limit_file="/sys/fs/cgroup/memory.max"
    [ -z "$mem_limit_file" ] && [ -f "/sys/fs/cgroup/memory/memory.limit_in_bytes" ] && mem_limit_file="/sys/fs/cgroup/memory/memory.limit_in_bytes"

    log_step "Java Heap vs Docker Limit"
    if [ -n "$mem_limit_file" ]; then
        local limit_bytes=$(cat "$mem_limit_file")
        if [ "$limit_bytes" != "max" ] && [ "$limit_bytes" -lt 9000000000000000000 ]; then
            local limit_mb=$((limit_bytes / 1024 / 1024))
            
            if [ "$xmx_mb" -eq 0 ]; then
                log_warning "No -Xmx limit detected." "Java may grow until Docker kills the container. Add -Xmx to JAVA_ARGS."
            elif [ "$xmx_mb" -gt "$limit_mb" ]; then
                log_error "Heap ($xmx_mb MB) exceeds Docker limit ($limit_mb MB)!" "The container will OOM-kill immediately on load."
                # log_error will handle exit based on DEBUG mode
            else
                log_success
                echo -e "      ${DIM}↳ Java Heap: ${xmx_mb}MB | Container: ${limit_mb}MB${NC}"
            fi
        else
            log_warning "No Docker limit detected." "The container has access to all host memory. Be careful with -Xmx settings."
        fi
    fi
}

check_system_resources() {
    log_section "System Resources"

    # Entropy
    log_step "System Entropy"
    local entropy=$(cat /proc/sys/kernel/random/entropy_avail 2>/dev/null || echo 2048)
    if [ "$entropy" -lt 1000 ]; then
        log_warning "Low entropy ($entropy)." "Cryptographic operations (logins/SSL) might be slow. Consider installing haveged."
    else
        log_success
    fi

    # File Descriptors
    log_step "File Descriptors"
    local fd_limit=$(ulimit -n)
    if [ "$fd_limit" -lt 4096 ]; then
        log_warning "Low FD limit ($fd_limit)." "Hytale handle many concurrent files. Recommend 4096+."
    else
        log_success
    fi
}

check_filesystem() {
    log_section "Filesystem Performance"

    log_step "Writable /tmp"
    if [ ! -w "/tmp" ]; then
        log_error "/tmp is not writable." "Java requires /tmp to extract native libraries."
        # log_error will handle exit based on DEBUG mode
    else
        log_success
    fi

    log_step "IO Latency Check"
    # Use a temporary file and don't let a cleanup failure kill the script
    local test_file="${BASE_DIR:-/home/container}/.test_io_$(date +%s)"
    local start=$(date +%s)
    
    # We use '|| true' and silence errors to prevent strict mode from crashing 
    # if the dd or rm fails unexpectedly.
    if dd if=/dev/zero of="$test_file" bs=1M count=10 conv=fsync >/dev/null 2>&1; then
        local end=$(date +%s)
        local io_time=$((end - start))
        
        # Cleanup: use '|| true' so the script continues even if rm fails
        rm -f "$test_file" >/dev/null 2>&1 || true
        
        if [ "$io_time" -gt 2 ]; then
            log_warning "Slow Disk IO ($io_time seconds)." "Heavy world generation may cause lag."
        else
            log_success
        fi
    else
        log_warning "IO Test Failed." "Could not write to ${BASE_DIR:-/home/container}. Check volume permissions."
        # Ensure we try to clean up just in case
        rm -f "$test_file" >/dev/null 2>&1 || true
    fi
}

check_stability() {
    log_section "Stability & Kernel"

    # Swappiness
    log_step "Kernel Swappiness"
    if [ -r /proc/sys/vm/swappiness ]; then
        local swap_val=$(cat /proc/sys/vm/swappiness)
        if [ "$swap_val" -gt 10 ]; then
            log_warning "High Swappiness ($swap_val)." "Kernel may swap Java to disk, causing massive lag spikes. Recommended: 1-10."
        else
            log_success
        fi
    fi

    # OOM Score
    log_step "OOM Score Adjustment"
    if [ -r /proc/self/oom_score_adj ]; then
        local oom_score=$(cat /proc/self/oom_score_adj)
        if [ "$oom_score" -gt 0 ]; then
            log_warning "Process is prioritized for OOM-kill." "Docker or the Host may kill this process first if memory is low."
        else
            log_success
        fi
    fi
}