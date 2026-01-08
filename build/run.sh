#!/bin/sh
set -eu

# ==============================================================================
# ENTRY RUNNER
# Detects the distro and runs the appropriate platform script
# ==============================================================================

log() { echo "[run.sh] $*"; }

log "Starting platform-specific script runner..."

# 1. Detect Linux distribution
# ------------------------------------------------------------------------------
log "Detecting Linux distribution..."
distro=$(grep -E "^ID=" /etc/os-release | cut -d= -f2 | sed -e 's/"//g')
log "Detected distro: $distro"

# 2. Determine target script
# ------------------------------------------------------------------------------
SCRIPT_PATH="$(dirname "$0")/${distro}/$1.sh"
log "Target script path: $SCRIPT_PATH"

# 3. Execute target script
# ------------------------------------------------------------------------------
if [ ! -f "$SCRIPT_PATH" ]; then
    log "ERROR: Script not found for distro '$distro': $SCRIPT_PATH"
    exit 1
fi

log "Executing $SCRIPT_PATH..."
sh "$SCRIPT_PATH"

log "Platform-specific script runner finished!"