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

# ==========================================
# LOAD DEPENDENCIES
# ==========================================

. "$SCRIPTS_PATH/utils.sh"

# ==========================================
# MAIN EXECUTION FLOW
# ==========================================

# --- Legacy Path Detection ---
LEGACY_ROOT="/home/container/game"
LEGACY_SERVER_DIR="$LEGACY_ROOT/Server"

log_section "Scanning for legacy folder structure"

if [ ! -d "$LEGACY_SERVER_DIR" ] || [ -z "$(ls -A "$LEGACY_SERVER_DIR" 2>/dev/null)" ]; then
    log_step "Legacy /game/Server path"
    printf "${DIM}Not found or empty (skip)${NC}\n"
    exit 0
fi

log_step "Legacy /game structure detected"
log_success

# --- Backup Before Migration ---
BACKUP_FILE="/home/container/.migrate_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
log_section "Creating backup of /home/container"

if tar -czf "$BACKUP_FILE" -C /home/container .; then
    log_success "Backup: $BACKUP_FILE ($(du -h "$BACKUP_FILE" | cut -f1))"
else
    log_error "Failed to create backup" "Check permissions on /home/container"
fi
