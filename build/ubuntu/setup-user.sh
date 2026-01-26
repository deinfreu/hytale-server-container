#!/bin/bash
#
# Ubuntu/Debian user setup
#

set -euo pipefail

USER="${USER:-container}"
HOME="${HOME:-/home/container}"
UID="${UID:-1000}"
GID="${GID:-1000}"

echo "Setting up user: $USER (UID=$UID, GID=$GID)"

# Handle UID/GID conflicts
if getent passwd "${UID}" > /dev/null 2>&1; then
    EXISTING_USER=$(getent passwd "${UID}" | cut -d: -f1)
    echo "UID ${UID} already exists as '${EXISTING_USER}', modifying..."
    usermod -l "${USER}" -d "${HOME}" -m "${EXISTING_USER}" 2>/dev/null || true
else
    # Create new group and user
    groupadd -g "${GID}" "${USER}" 2>/dev/null || true
    useradd -m -d "${HOME}" -u "${UID}" -g "${USER}" -s /bin/sh "${USER}"
fi

echo "User $USER created successfully"
