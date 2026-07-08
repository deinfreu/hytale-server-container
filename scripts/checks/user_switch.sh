#!/bin/sh
set -eu

# Copyright (C) 2026 Daniel Freudenberg
#
# This file is part of hytale-server-container.
#
# hytale-server-container is free software: you can redistribute it
# and/or modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
#
# hytale-server-container is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty
# of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with hytale-server-container. If not, see
# <https://www.gnu.org/licenses/>.

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
