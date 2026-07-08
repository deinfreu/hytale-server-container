#!/bin/sh
set -eu

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

# --- Audit Suite ---
log_section "Audit Suite"

if [ "$DEBUG" = "TRUE" ]; then
    sh "$SCRIPTS_PATH/checks/audit_security.sh"
    sh "$SCRIPTS_PATH/checks/audit_network.sh"
else
    printf "${DIM}System debug skipped (DEBUG=FALSE)${NC}\n"
fi

if [ "$PROD" = "TRUE" ]; then
    sh "$SCRIPTS_PATH/checks/audit_prod.sh"
else
    printf "${DIM}Production audit skipped (PROD=FALSE)${NC}\n"
fi

# --- 3. Startup Preparation ---
log_section "Process Execution"
log_step "Finalizing Environment"
cd "$BASE_DIR"
log_success