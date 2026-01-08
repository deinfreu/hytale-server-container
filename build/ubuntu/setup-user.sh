#!/bin/sh
set -eu

# ==============================================================================
# SETUP USER (Pterodactyl Compatible)
# Creates the user and group using Dockerfile ENV variables
# ==============================================================================

log() { echo "[setup-user] $*"; }

log "Starting setup-user script..."

# 1. Remove default user (if present)
# ------------------------------------------------------------------------------
if id ubuntu >/dev/null 2>&1; then
    log "Removing default user 'ubuntu'..."
    deluser ubuntu || log "Warning: failed to remove ubuntu user"
else
    log "No 'ubuntu' user to remove"
fi

# 2. Create Group
# ------------------------------------------------------------------------------
if ! getent group "$GID" >/dev/null 2>&1; then
    log "Creating group '$USER' with GID=$GID..."
    if command -v addgroup >/dev/null 2>&1; then
        addgroup --gid "$GID" "$USER"
    else
        groupadd -g "$GID" "$USER"
    fi
else
    log "Group with GID=$GID already exists"
fi

# 3. Create User with $HOME
# ------------------------------------------------------------------------------
if ! id "$USER" >/dev/null 2>&1; then
    log "Creating user '$USER' with UID=$UID and HOME=$HOME..."
    if command -v adduser >/dev/null 2>&1; then
        # Alpine/Debian adduser
        adduser --system --shell /bin/bash --uid "$UID" --ingroup "$USER" --home "$HOME" "$USER"
    else
        # Standard useradd
        useradd -u "$UID" -g "$GID" -m -d "$HOME" -s /bin/bash "$USER"
    fi
else
    log "User '$USER' already exists"
fi

# 4. Permissions
# ------------------------------------------------------------------------------
log "Ensuring $HOME directory exists and has correct ownership..."
mkdir -p "$HOME"
chown -R "$UID":"$GID" "$HOME"

log "setup-user script finished successfully!"