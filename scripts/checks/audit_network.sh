#!/bin/sh
set -u

# Copyright (C) 2026 Daniel Freudenberg
#
# This file is part of hytale-server-container.
#
# hytale-server-container is free software: you can redistribute it
# and/or modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
#
# hytale-server-container is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty
# of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with hytale-server-container. If not, see
# <https://www.gnu.org/licenses/>.

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