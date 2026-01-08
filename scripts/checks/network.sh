#!/bin/sh
set -eu

LIB_DIR="$(dirname "$0")/lib"

# Load dependencies
. "$LIB_DIR/utils.sh"
. "$LIB_DIR/network_logic.sh"

# Configuration defaults
SERVER_PORT="${SERVER_PORT:-25565}"
SERVER_IP="${SERVER_IP:-0.0.0.0}"

log "Starting network configuration audit..." "$BLUE" "network-check"

validate_port_cfg
validate_ip_syntax
check_port_availability
check_udp_stack
check_connectivity

log "Network audit finished." "$GREEN" "network-check"
exit 0