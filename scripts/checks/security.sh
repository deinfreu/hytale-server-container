#!/bin/sh
set -eu

# Load dependencies
. "$SCRIPTS_PATH/utils.sh"
. "$SCRIPTS_PATH/checks/lib/security.sh"

# Execute
log "Starting security audit..." "$BLUE"

check_integrity
check_container_hardening
check_clock_sync

log "Security audit finished." "$GREEN"