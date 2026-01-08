#!/bin/sh
set -eu

# Configuration
SERVER_PATH="/usr/local/lib/server.jar"
LIB_DIR="$(dirname "$0")/lib"

# Load dependencies
. "$LIB_DIR/utils.sh"
. "$LIB_DIR/security_logic.sh"

# Execute
log "Starting production readyiness checks..." "$BLUE"

check_java_mem
check_system_resources
check_filesystem
check_kernel_optimizations
check_stability

log "Production readyiness checks finished." "$GREEN"