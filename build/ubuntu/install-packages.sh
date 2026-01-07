#!/bin/sh
set -eu

# ==============================================================================
# INSTALL PACKAGES (Ubuntu/Debian)
# Installs runtime dependencies and cleans up cache
# ==============================================================================

# Colors
BLUE="\033[0;34m"
GREEN="\033[0;32m"
RESET="\033[0m"

log() {
    printf "%b[install-packages] %s%b\n" "${2:-$BLUE}" "$1" "$RESET"
}

# 1. Update APT
# ------------------------------------------------------------------------------
log "Updating package lists..."
apt-get update

# 2. Install Dependencies
# ------------------------------------------------------------------------------
log "Installing required packages..."
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    tini \
    dos2unix \
    jq \
    unzip \
    tzdata \
    iproute2 \
    ${EXTRA_DEB_PACKAGES:-}

# Note: 'iproute2' is required for the 'ss' command in Healthcheck
# Note: 'dos2unix' is required to fix script line endings in the Dockerfile

# 3. Configuration
# ------------------------------------------------------------------------------
# Set default timezone to UTC to prevent interactive prompts
ln -fs /usr/share/zoneinfo/UTC /etc/localtime
dpkg-reconfigure --frontend noninteractive tzdata

# 4. Cleanup
# ------------------------------------------------------------------------------
log "Cleaning up APT cache..."
apt-get clean
rm -rf /var/lib/apt/lists/*

log "Ubuntu package installation finished successfully!" "$GREEN"