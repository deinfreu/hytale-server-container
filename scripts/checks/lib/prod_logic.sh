#!/bin/sh

check_java_mem() {
    XMX_RAW=$(echo "${JAVA_OPTS:-}" | grep -oE 'Xmx[0-9]+[gGmM]' | tr -d 'Xmx')
    XMX_NUM=$(echo "$XMX_RAW" | grep -oE '[0-9]+')
    XMX_UNIT=$(echo "$XMX_RAW" | grep -oE '[gGmM]')

    XMX_MB=0
    if [ -n "$XMX_NUM" ]; then
        if [ "$XMX_UNIT" = "g" ] || [ "$XMX_UNIT" = "G" ]; then
            XMX_MB=$((XMX_NUM * 1024))
        else
            XMX_MB=$XMX_NUM
        fi
    fi

    MEM_LIMIT_FILE=""
    if [ -f "/sys/fs/cgroup/memory.max" ]; then
        MEM_LIMIT_FILE="/sys/fs/cgroup/memory.max"
    elif [ -f "/sys/fs/cgroup/memory/memory.limit_in_bytes" ]; then
        MEM_LIMIT_FILE="/sys/fs/cgroup/memory/memory.limit_in_bytes"
    fi

    if [ -n "$MEM_LIMIT_FILE" ]; then
        LIMIT_BYTES=$(cat "$MEM_LIMIT_FILE")
        if [ "$LIMIT_BYTES" != "max" ] && [ "$LIMIT_BYTES" -lt 9000000000000000000 ]; then
            LIMIT_MB=$((LIMIT_BYTES / 1024 / 1024))
            if [ "$XMX_MB" -eq 0 ]; then
                log "Warning: No -Xmx limit detected in JAVA_OPTS." "$YELLOW" "Integrity"
            elif [ "$XMX_MB" -gt "$LIMIT_MB" ]; then
                log "CRITICAL: Java Xmx ($XMX_MB MB) exceeds Docker limit ($LIMIT_MB MB)!" "$RED" "Integrity"
                exit 1
            else
                OVERHEAD=$((LIMIT_MB - XMX_MB))
                log "Java heap ($XMX_MB MB) fits in Docker limit ($LIMIT_MB MB). Overhead: ${OVERHEAD}MB." "$GREEN" "Integrity"
            fi
        else
            log "Warning: No Docker container limit detected. Using host memory." "$BLUE" "Integrity"
        fi
    fi
}

check_system_resources() {
    # Entropy
    ENTROPY=$(cat /proc/sys/kernel/random/entropy_avail 2>/dev/null || echo 2048)
    if [ "$ENTROPY" -lt 1000 ]; then
        log "Warning: Low system entropy ($ENTROPY). Logins might be slow." "$YELLOW" "Security"
    else
        log "High entropy available ($ENTROPY) for encryption." "$GREEN" "Security"
    fi

    # File Descriptors
    FD_LIMIT=$(ulimit -n)
    if [ "$FD_LIMIT" -lt 4096 ]; then
        log "Warning: Low File Descriptor limit ($FD_LIMIT). Recommend 4096+." "$YELLOW" "Performance"
    else
        log "File Descriptor limit is sufficient ($FD_LIMIT)." "$GREEN" "Performance"
    fi

    # Threads
    MAX_THREADS=$(grep "Max processes" /proc/self/limits | awk '{print $3}')
    if [ "$MAX_THREADS" = "unlimited" ]; then
        log "Process Limit: unlimited (Excellent)" "$GREEN" "Performance"
    elif [ -n "$MAX_THREADS" ] && [ "$MAX_THREADS" -lt 1024 ]; then
        log "Warning: Process thread limit is low ($MAX_THREADS). Recommend 2048+." "$YELLOW" "Performance"
    else
        log "Process Limit: $MAX_THREADS (OK)" "$GREEN" "Performance"
    fi
}

check_filesystem() {
    # /tmp access
    if [ ! -w "/tmp" ]; then
        log "CRITICAL: /tmp is not writable. Java cannot start." "$RED" "Environment"
        exit 1
    fi

    # /tmp noexec
    if mount | grep -q "on /tmp .*noexec"; then
        log "Warning: /tmp is mounted with 'noexec'. Networking may be slower." "$YELLOW" "Performance"
    fi

    # IO Latency
    START=$(date +%s)
    dd if=/dev/zero of=/home/container/.test_io bs=1M count=10 conv=fsync >/dev/null 2>&1
    END=$(date +%s)
    IO_TIME=$((END - START))
    rm -f /home/container/.test_io
    if [ "$IO_TIME" -gt 2 ]; then
        log "Warning: Disk IO is slow ($IO_TIME seconds for 10MB)." "$YELLOW" "Performance"
    else
        log "Disk IO: OK ($IO_TIME seconds)." "$GREEN" "Performance"
    fi

    # OverlayFS check
    FS_TYPE=$(stat -f -c %T /home/container)
    if [ "$FS_TYPE" = "overlayfs" ]; then
        log "Warning: /home/container is on overlayfs. Heavy IO may cause lag." "$YELLOW" "Performance"
    else
        log "Filesystem for /home/container: $FS_TYPE." "$GREEN" "Performance"
    fi
}

check_kernel_optimizations() {
    # THP
    if [ -f /sys/kernel/mm/transparent_hugepage/enabled ]; then
        THP=$(cat /sys/kernel/mm/transparent_hugepage/enabled | grep -o "\[.*\]")
        if [ "$THP" = "[always]" ]; then
            log "Warning: THP is set to 'always'. This can cause lag spikes." "$YELLOW" "Performance"
        else
            log "Transparent Huge Pages optimized ($THP)." "$GREEN" "Performance"
        fi
    fi

    # UDP Buffers
    RMEM_PATH="/proc/sys/net/core/rmem_max"
    if [ -r "$RMEM_PATH" ]; then
        RMEM_MAX=$(cat "$RMEM_PATH")
        if [ "$RMEM_MAX" -lt 2097152 ]; then
            log "Warning: UDP receive buffer (rmem_max) is small ($RMEM_MAX bytes)." "$YELLOW" "Performance"
        else
            log "UDP receive buffer is optimized ($RMEM_MAX bytes)." "$GREEN" "Performance"
        fi
    fi
}

check_stability() {
    # 1. Swappiness Check
    # High swappiness (e.g. 60) makes the kernel move Java heap to disk, causing massive lag.
    # For game servers, we want this as low as possible (ideally 1-10).
    if [ -r /proc/sys/vm/swappiness ]; then
        SWAP_VAL=$(cat /proc/sys/vm/swappiness)
        if [ "$SWAP_VAL" -gt 10 ]; then
            log "Warning: System swappiness is high ($SWAP_VAL). Java GC may be slow." "$YELLOW" "Performance"
        else
            log "System swappiness is optimized ($SWAP_VAL)." "$GREEN" "Performance"
        fi
    fi

    # 2. Time check
    CUR_YEAR=$(date +%Y)
    if [ "$CUR_YEAR" -lt 2025 ]; then
        log "CRITICAL: System clock is incorrect ($CUR_YEAR)." "$RED" "Integrity"
        exit 1
    fi

    # 3. OOM Score
    if [ -r /proc/self/oom_score_adj ]; then
        OOM_SCORE=$(cat /proc/self/oom_score_adj)
        if [ "$OOM_SCORE" -gt 0 ]; then
            log "Warning: High OOM score adjustment ($OOM_SCORE). Risk of termination." "$YELLOW" "Security"
        fi
    fi

    # 4. Swap usage (Total Amount Used)
    if [ -r /proc/swaps ]; then
        SWAP_USED=$(awk 'NR>1 {sum+=$4} END {print sum+0}' /proc/swaps)
        if [ "$SWAP_USED" -gt 0 ]; then
            log "Warning: Active swap usage detected ($SWAP_USED KB). Expect lag spikes." "$YELLOW" "Performance"
        fi
    fi
}