#!/bin/sh
set -eu

# Load dependencies
. "$SCRIPTS_PATH/utils.sh"
. "$SCRIPTS_PATH/checks/lib/prod_logic.sh"
# Execute
log "Starting production readyiness checks..." "$BLUE"

check_java_mem
check_system_resources
check_filesystem
check_kernel_optimizations
check_stability

log "Production readyiness checks finished." "$GREEN"