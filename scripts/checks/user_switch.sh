#!/bin/sh
set -eu

# Determine if we need to switch users
CURRENT_UID=$(id -u)
if [ "$CURRENT_UID" = "0" ]; then
    # Running as root, need to drop privileges
    if command -v gosu >/dev/null 2>&1; then
        RUNTIME="gosu $UID:$GID"
    elif command -v su-exec >/dev/null 2>&1; then
        RUNTIME="su-exec $UID:$GID"
    else
        RUNTIME=""
    fi
else
    # Already running as non-root, no need to switch
    RUNTIME=""
fi

# Export RUNTIME for use in parent script
export RUNTIME
