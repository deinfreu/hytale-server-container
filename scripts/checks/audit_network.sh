#!/bin/sh
set -u

# Load dependencies
. "$SCRIPTS_PATH/utils.sh"
. "$SCRIPTS_PATH/checks/lib/network_logic.sh"

# Execute
# We use log_section as the "Start" indicator
log_section "Network Configuration Audit"

# These functions (inside network_logic.sh) should now use log_step/log_success
check_connectivity
validate_port_cfg
check_port_availability
check_udp_stack

# A clean final confirmation
echo -e "\n${GREEN}${BOLD}✔ Network audit complete.${NC}"
exit 0