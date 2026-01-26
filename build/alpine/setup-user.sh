#!/bin/sh
#
# Alpine Linux user setup
#

set -e

USER="${USER:-container}"
HOME="${HOME:-/home/container}"
UID="${UID:-1000}"
GID="${GID:-1000}"

echo "Setting up user: $USER (UID=$UID, GID=$GID)"

# Handle UID/GID conflicts
if getent passwd "${UID}" > /dev/null 2>&1; then
    EXISTING_USER=$(getent passwd "${UID}" | cut -d: -f1)
    echo "UID ${UID} already exists as '${EXISTING_USER}', removing..."
    deluser "${EXISTING_USER}" 2>/dev/null || true
fi

if getent group "${GID}" > /dev/null 2>&1; then
    EXISTING_GROUP=$(getent group "${GID}" | cut -d: -f1)
    if [ "$EXISTING_GROUP" != "$USER" ]; then
        echo "GID ${GID} already exists as '${EXISTING_GROUP}', removing..."
        delgroup "${EXISTING_GROUP}" 2>/dev/null || true
    fi
fi

# Create group and user
addgroup -S -g "${GID}" "${USER}" 2>/dev/null || true
adduser -S -D -h "${HOME}" -u "${UID}" -G "${USER}" "${USER}"

echo "User $USER created successfully"
