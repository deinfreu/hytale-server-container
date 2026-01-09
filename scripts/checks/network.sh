#!/bin/sh
set -eu

# Load dependencies
. "$SCRIPTS_PATH/utils.sh"
. "$SCRIPTS_PATH/checks/lib/network_logic.sh"

log "Starting network configuration audit..." "$BLUE" "network-check"

check_connectivity
validate_port_cfg
check_port_availability
check_udp_stack

log "Network audit finished." "$GREEN" "network-check"
exit 0