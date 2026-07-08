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
. "$SCRIPTS_PATH/checks/lib/security_logic.sh"

# Execute
log_section "Security & Integrity Audit"

# These functions (inside security_logic.sh) now use the log_step format
check_integrity
check_container_hardening
check_clock_sync

echo -e "\n${BOLD}${GREEN}✔ Security audit complete.${NC}"
exit 0