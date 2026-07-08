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

# Load dependencies
. "$SCRIPTS_PATH/utils.sh"

# ==========================================
# HELPER FUNCTIONS
# ==========================================

determine_install_state() {
    # Locate the downloaded ZIP file
    ZIP_FILE=""
    for f in "$BASE_DIR"/*.zip; do
        # Get just the filename
        filename=$(basename "$f")

        # Skip Assets.zip and only accept files matching semantic versioning
        # This pattern matches files like 0.5.6.zip, 1.0.0.zip, etc.
        case "$filename" in
            [0-9]*.[0-9]*.[0-9]*.zip)
                # Validate it's actually semantic versioning (digits.digits.digits.zip)
                base="${filename%.zip}"
                if echo "$base" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
                    ZIP_FILE="$f"
                    break
                fi
                ;;
        esac
    done

    # Decision logic based on detection
    if [ -n "$ZIP_FILE" ]; then
        log_success "Update package detected" "Running update script..."
        exec sh "$SCRIPTS_PATH/hytale/hytale_update.sh"
    elif [ ! -f "$SERVER_JAR_PATH" ]; then
        log_success "No installation found" "Running fresh download..."
        exec sh "$SCRIPTS_PATH/hytale/hytale_download.sh"
    else
        log_success "Server up-to-date" "Skipping extraction. Place *.zip in $BASE_DIR to trigger an update."
    fi
}

# ==========================================
# MAIN EXECUTION FLOW
# ==========================================

log_section "Hytale core initialization"
log_step "Evaluating installation status"

determine_install_state