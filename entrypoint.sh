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

# Force line buffering for TrueNAS Scale log compatibility
export PYTHONUNBUFFERED=1
stdbuf -oL -eL true 2>/dev/null && USE_STDBUF=true || USE_STDBUF=false

# Bootstrap SCRIPTS_PATH for environment loading
export SCRIPTS_PATH="/usr/local/bin/scripts"

# Fix host mount permissions while we are root at boot
if [ "$(id -u)" = "0" ]; then
    chown -R container:container /home/container
fi

# Load all environment variables and configuration defaults
. "$SCRIPTS_PATH/environment.sh"

# Load utility functions for logging
. "$SCRIPTS_PATH/utils.sh"

# Check if running old folder structure and migrate if necessary
sh "$SCRIPTS_PATH/hytale/hytale_legacy_backup.sh"

# --- Initialization Phase ---
# CRITICAL ORDER: Binary handler must run BEFORE config management

# Manage Hytale server binary (download/update)
sh "$SCRIPTS_PATH/hytale/hytale_binary_handler.sh"

# Manage server configuration files
sh "$SCRIPTS_PATH/hytale/hytale_config.sh"

# Set file permissions
. "$SCRIPTS_PATH/checks/permissions.sh"

# Convert environment variables to CLI options
. "$SCRIPTS_PATH/hytale/hytale_options.sh"

# Run system audit checks
. "$SCRIPTS_PATH/checks/audit_suite.sh"

# --- Execution Phase ---
log_section "Launching Hytale Server"

# Determine user switching mechanism (gosu/su-exec)
. "$SCRIPTS_PATH/checks/user_switch.sh"

# Configure authentication and auto-login
. "$SCRIPTS_PATH/hytale/hytale_auth.sh"

# Start server with update restart support
exec sh "$SCRIPTS_PATH/hytale/hytale_start.sh"
