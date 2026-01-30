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

# --- ARM64: Check if x86_64 emulation is available ---
if [ "$(uname -m)" = "aarch64" ] || [ "$(uname -m)" = "arm64" ]; then
    log_step "ARM64 Emulation Check"
    # Test if we can execute x86_64 binaries
    if ! /usr/local/bin/hytale-downloader-bin --help >/dev/null 2>&1; then
        log_error "x86_64 emulation not available" "binfmt_misc not registered on host"
        printf "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
        printf "${YELLOW}ARM64 Setup Required${NC}\n"
        printf "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n\n"
        printf "This container requires x86_64 emulation support on ARM64 hosts.\n\n"
        printf "${GREEN}Solution:${NC} Run this command on your ${BOLD}host machine${NC} (not in the container):\n\n"
        printf "  ${CYAN}docker run --privileged --rm tonistiigi/binfmt --install amd64${NC}\n\n"
        printf "Or use the provided setup script:\n\n"
        printf "  ${CYAN}./scripts/setup_arm64.sh${NC}\n\n"
        printf "${DIM}Note: This registration persists until reboot. Re-run after rebooting.${NC}\n\n"
        printf "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
        exit 1
    fi
    log_success
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