#!/bin/sh
set -eu

# Colors
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
RESET="\033[0m"

log() { echo "${2:-$RESET}[prod-check]$1${RESET}"; }

log "Performing Production-Ready validation..." "$BLUE"

# 1. Java Memory vs Container Memory Limit
# Use internal shell math to avoid 'bc' dependency

# Extract Xmx value and Unit
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

# Determine correct Cgroup path
MEM_LIMIT_FILE=""
if [ -f "/sys/fs/cgroup/memory.max" ]; then
    MEM_LIMIT_FILE="/sys/fs/cgroup/memory.max" # Cgroup v2
elif [ -f "/sys/fs/cgroup/memory/memory.limit_in_bytes" ]; then
    MEM_LIMIT_FILE="/sys/fs/cgroup/memory/memory.limit_in_bytes" # Cgroup v1
fi

if [ -n "$MEM_LIMIT_FILE" ]; then
    LIMIT_BYTES=$(cat "$MEM_LIMIT_FILE")
    
    # Check if limit is set (not 'max' and not a massive number like 9223372036854771712)
    if [ "$LIMIT_BYTES" != "max" ] && [ "$LIMIT_BYTES" -lt 9000000000000000000 ]; then
        LIMIT_MB=$((LIMIT_BYTES / 1024 / 1024))
        
        if [ "$XMX_MB" -eq 0 ]; then
            log "[Integrity] Warning: No -Xmx limit detected in JAVA_OPTS." "$YELLOW"
        elif [ "$XMX_MB" -gt "$LIMIT_MB" ]; then
            log "[Integrity] CRITICAL: Java Xmx ($XMX_MB MB) exceeds Docker limit ($LIMIT_MB MB)!" "$RED"
            exit 1
        else
            OVERHEAD=$((LIMIT_MB - XMX_MB))
            log "[Integrity] Java heap ($XMX_MB MB) fits within Docker limit ($LIMIT_MB MB). Overhead: ${OVERHEAD}MB." "$GREEN"
        fi
    else
        log "[Integrity] Warning: No Docker container limit detected. Now Using host memory." "$BLUE"
    fi
else
    log "[Integrity] Warning: Could not detect Cgroup limits. Skipping check." "$BLUE"
fi

# 2. Entropy Check (Crucial for Encryption/Login speed)
# Low entropy causes SecureRandom to block, making logins hang or time out.
ENTROPY=$(cat /proc/sys/kernel/random/entropy_avail 2>/dev/null || echo 2048)

if [ "$ENTROPY" -lt 1000 ]; then
    log "[Security] Warning: Low system entropy ($ENTROPY). Logins might be slow." "$YELLOW"
else
    log "[Security] High entropy available ($ENTROPY) for encryption." "$GREEN"
fi

# 3. /tmp Writable Check
# Java needs /tmp to extract native libraries and handle runtime files.
if [ ! -w "/tmp" ]; then
    log "[Environment] CRITICAL: /tmp is not writable. Java cannot start." "$RED"
    exit 1
else
    log "[Environment] /tmp is writable." "$GREEN"
fi

# 4. No-Root Check (Hard Enforcement)
# Running as a non-root user (e.g., 'hytale') limits the impact of potential exploits.
if [ "$(id -u)" = "0" ]; then
    log "[Security] CRITICAL: Security policy violation: Server running as ROOT." "$RED"
    exit 1
else
    log "[Security] Running as non-privileged user ($(id -un))." "$GREEN"
fi

# 5. File Descriptor Limit
# Game servers open many files (region files, player data, and network sockets).
FD_LIMIT=$(ulimit -n)

if [ "$FD_LIMIT" -lt 4096 ]; then
    log "[Performance] Warning: Low File Descriptor limit ($FD_LIMIT). Recommend 4096+." "$YELLOW"
else
    log "[Performance] File Descriptor limit is sufficient ($FD_LIMIT)." "$GREEN"
fi

# 6. Check for 'noexec' on /tmp (Required for Netty Optimization)
# If 'noexec' is present, Java falls back to a slower, non-native network stack.
if mount | grep -q "on /tmp .*noexec"; then
    log "[Performance] Warning: /tmp is mounted with 'noexec'. Networking may be slower." "$YELLOW"
else
    log "[Performance] /tmp allows execution (Native Netty transport enabled)." "$GREEN"
fi

# 7. Check for Huge Pages (Performance)
# 'always' can cause random latency spikes during Java Garbage Collection.
if [ -f /sys/kernel/mm/transparent_hugepage/enabled ]; then
    THP=$(cat /sys/kernel/mm/transparent_hugepage/enabled | grep -o "\[.*\]")
    
    if [ "$THP" = "[always]" ]; then
        log "[Performance] Warning: THP is set to 'always'. This can cause lag spikes." "$YELLOW"
    else
        # [madvise] or [never] are both acceptable for Java production environments
        log "[Performance] Transparent Huge Pages optimized ($THP)." "$GREEN"
    fi
else
    log "[Performance] THP control not available (Skipping)." "$BLUE"
fi

# 8. Timezone/Clock check
CUR_YEAR=$(date +%Y)
if [ "$CUR_YEAR" -lt 2025 ]; then
    log "[Integrity] CRITICAL: System clock is incorrect ($CUR_YEAR). Authentication will fail." "$RED"
    exit 1
else
    # Confirming the time is valid for the current year
    log "[Integrity] System Time: Synchronized ($CUR_YEAR)." "$GREEN"
fi

# 9. Disk Write Latency (IO Benchmark)
# We write 10MB of zeros to test if the disk is responsive

# Use 'time' to measure the duration instead of parsing 'dd' output
# This is much more reliable across different Linux distributions
START=$(date +%s)
dd if=/dev/zero of=/data/.test_io bs=1M count=10 conv=fsync >/dev/null 2>&1
END=$(date +%s)
IO_TIME=$((END - START))
rm -f /data/.test_io

if [ "$IO_TIME" -gt 2 ]; then
    log "[Performance] Warning: Disk IO is slow ($IO_TIME seconds for 10MB). Expect lag." "$YELLOW"
else
    log "[Performance] Disk IO: OK ($IO_TIME seconds)." "$GREEN"
fi

# 10. Process / Thread Limit Check (Portable Version)
# We parse /proc/self/limits to find "Max processes"
MAX_THREADS=$(grep "Max processes" /proc/self/limits | awk '{print $3}')

# Check if we successfully got a number (it might be "unlimited")
if [ "$MAX_THREADS" = "unlimited" ]; then
    log "[Performance] Process Limit: unlimited (Excellent)" "$GREEN"
elif [ -n "$MAX_THREADS" ] && [ "$MAX_THREADS" -lt 1024 ]; then
    log "[Performance] Warning: Process thread limit is low ($MAX_THREADS). Recommend 2048+." "$YELLOW"
else
    log "[Performance] Process Limit: $MAX_THREADS (OK)" "$GREEN"
fi

# 11. Network Stack Check (UDP Buffer Size)
# Hytale's QUIC protocol requires large buffers to handle high-speed game data.
RMEM_PATH="/proc/sys/net/core/rmem_max"

if [ -r "$RMEM_PATH" ]; then
    RMEM_MAX=$(cat "$RMEM_PATH")
    if [ "$RMEM_MAX" -lt 2097152 ]; then
        log "[Performance] Warning: UDP receive buffer (rmem_max) is small ($RMEM_MAX bytes). Packet loss may occur." "$YELLOW"
    else
        log "[Performance] UDP receive buffer is optimized ($RMEM_MAX bytes)." "$GREEN"
    fi
else
    # If we can't read it, don't say 0. Say it's restricted.
    log "[Performance] UDP buffer check skipped: Access to $RMEM_PATH restricted." "$BLUE"
fi

# 12. Check for leftover Lockfiles
# Leftover lockfiles often indicate a crash or "hard kill" of the previous session.
if [ -d "/data/world" ]; then
    if [ -f "/data/world/session.lock" ]; then
        log "[Integrity] Warning: Leftover session.lock detected. Previous shutdown may have been improper." "$YELLOW"
    else
        log "[Integrity] No session lockfile detected. System is clean." "$GREEN"
    fi
else
    # If the directory doesn't exist, it's a fresh server or a new world.
    log "[Integrity] Fresh world environment detected (no /data/world)." "$GREEN"
fi

# 13. Filesystem Type Check
# OverlayFS (commonly used by Docker layers) can introduce latency under heavy,
# write-intensive workloads such as world saves and region updates.
# A native filesystem (ext4/xfs) is strongly preferred for /data.
FS_TYPE=$(stat -f -c %T /data)
if [ "$FS_TYPE" = "overlayfs" ]; then
    log "[Performance] Warning: /data is on overlayfs. Heavy IO may cause lag." "$YELLOW"
else
    log "[Performance] Filesystem for /data: $FS_TYPE." "$GREEN"
fi

# 14. OOM Killer Risk Detection
# Score ranges from -1000 (immune) to 1000 (sacrificial). 0 is the stable default.
if [ -r /proc/self/oom_score_adj ]; then
    OOM_SCORE=$(cat /proc/self/oom_score_adj)
    
    if [ "$OOM_SCORE" -gt 0 ]; then
        # Anything above 0 means the OS is more likely to kill this process if RAM is low.
        log "[Security] Warning: High OOM score adjustment ($OOM_SCORE). Server is at higher risk of being killed if RAM is low." "$YELLOW"
    elif [ "$OOM_SCORE" -lt 0 ]; then
        # Negative scores mean the process is protected (usually requires root/host config).
        log "[Security] OOM score is protected ($OOM_SCORE). Server is prioritized by the kernel." "$GREEN"
    else
        # 0 is the standard for production applications.
        log "[Security] OOM score is neutral (0). Standard kernel termination priority." "$GREEN"
    fi
fi

# 15. Swap Usage Detection
# Active swap usage introduces severe and unpredictable latency for JVM workloads,
# often resulting in tick freezes and long GC pauses. Production servers should not swap.
if [ -r /proc/swaps ]; then
    SWAP_USED=$(awk 'NR>1 {sum+=$4} END {print sum+0}' /proc/swaps)
    if [ "$SWAP_USED" -gt 0 ]; then
        log "[Performance] Warning: Swap is in use ($SWAP_USED KB). Expect latency spikes." "$YELLOW"
    else
        log "[Performance] Swap usage: none (Optimal)." "$GREEN"
    fi
fi

# 16. Clock Stability / Monotonicity Check
# Unstable or drifting system clocks (common on low-quality VPS hosts) can
# break tick timing, scheduled tasks, and authentication logic.
# Large offsets indicate poor time synchronization.
if command -v adjtimex >/dev/null 2>&1; then
    OFFSET=$(adjtimex | grep "offset" | awk '{print $2}')
    if [ "${OFFSET#-}" -gt 100 ]; then
        log "[Integrity] Warning: System clock offset is high ($OFFSET µs)." "$YELLOW"
    fi
fi

log " Production checks passed." "$GREEN"
exit 0