#!/bin/sh
set -eu

# Force line buffering for TrueNAS Scale log compatibility
export PYTHONUNBUFFERED=1
stdbuf -oL -eL true 2>/dev/null && USE_STDBUF=true || USE_STDBUF=false

# Bootstrap SCRIPTS_PATH for environment loading
export SCRIPTS_PATH="/usr/local/bin/scripts"

# Load all environment variables and configuration defaults
. "$SCRIPTS_PATH/environment.sh"

# Load utility functions for logging
. "$SCRIPTS_PATH/utils.sh"

# --- Ensure proper ownership of home directory (critical for file writes) ---
if [ "$(id -u)" = "0" ]; then
    # Running as root - ensure container user's home is properly owned
    chown -R container:container /home/container 2>/dev/null || true
    chmod 755 /home/container 2>/dev/null || true
fi

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