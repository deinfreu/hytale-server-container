#!/bin/bash
#
# Ubuntu/Debian package installation
#

set -euo pipefail

echo "Installing Ubuntu/Debian packages..."

apt-get update

DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    tini \
    curl \
    iproute2 \
    ca-certificates \
    tzdata \
    jq \
    unzip \
    gosu

# Clean up APT cache
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "Ubuntu/Debian packages installed successfully"
