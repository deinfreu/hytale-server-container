#!/bin/sh
set -eu

# Configuration
SERVER_PATH="/usr/local/lib/server.jar"
LIB_DIR="$(dirname "$0")/lib"

# Load dependencies
. "$LIB_DIR/utils.sh"
. "$LIB_DIR/security_logic.sh"

# Execute
log "Starting security audit..." "$BLUE"

check_integrity
check_container_hardening
check_clock_sync

log "Security audit finished." "$GREEN"