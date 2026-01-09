#!/bin/sh
set -eu

# Load dependencies
. "$SCRIPTS_PATH/utils.sh"
. "$SCRIPTS_PATH/checks/lib/network_logic.sh"

log "Starting network configuration audit..." "$BLUE" "network-check"

validate_port_cfg
validate_ip_syntax
check_port_availability
check_udp_stack
check_connectivity

log "Network audit finished." "$GREEN" "network-check"
exit 0