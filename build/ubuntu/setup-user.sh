#!/bin/sh
set -eu

# ==============================================================================
# SETUP USER (Ubuntu/Debian)
# Creates the hytale user and group with specific GID/UID
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
    log "Creating group 'hytale' with GID=$GID..."
    # Attempt 'addgroup' (Alpine/Debian) then fallback to 'groupadd' (RHEL)
    if command -v addgroup >/dev/null 2>&1; then
        addgroup --gid "$GID" hytale
    else
        groupadd -g "$GID" hytale
    fi
else
    log "Group with GID=$GID already exists"
fi

# 3. Create User
# ------------------------------------------------------------------------------
if ! id hytale >/dev/null 2>&1; then
    log "Creating user 'hytale' with UID=$UID..."
    if command -v adduser >/dev/null 2>&1; then
        adduser --system --shell /bin/false --uid "$UID" --ingroup hytale --home /data hytale
    else
        useradd -u "$UID" -g "$GID" -m -d /data -s /bin/false hytale
    fi
else
    log "User 'hytale' already exists"
fi

# 4. Permissions
# ------------------------------------------------------------------------------
log "Ensuring /data directory exists and has correct ownership..."
mkdir -p /data
chown -R "$UID":"$GID" /data

log "setup-user script finished successfully!"