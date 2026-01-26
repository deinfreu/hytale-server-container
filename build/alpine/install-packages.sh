#!/bin/sh
#
# Alpine Linux package installation
#

set -e

echo "Installing Alpine packages..."

apk add --no-cache \
    tini \
    su-exec \
    curl \
    iproute2 \
    ca-certificates \
    tzdata \
    jq \
    libc6-compat \
    libstdc++ \
    gcompat \
    unzip \
    shadow

echo "Alpine packages installed successfully"
