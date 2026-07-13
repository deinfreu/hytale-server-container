#!/bin/sh
set -eu

# Copyright (C) 2026 Daniel Freudenberg
#
# This file is part of github.com/deinfreu/hytale-server-container.
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

extract_server() {
    local ZIP_FILE="$1"

    if [ "${DEBUG:-FALSE}" = "TRUE" ]; then
        printf "      ${DIM}↳ Source:${NC} %s\n" "$(basename "$ZIP_FILE")"
        printf "      ${DIM}↳ Target:${NC} %s\n" "$BASE_DIR"
    fi

    if unzip -qo "$ZIP_FILE" -d "$BASE_DIR"; then
        log_success
    else
        log_error "Extraction failed" "Check disk space or zip file integrity."
        exit 1
    fi

    # Remove downloaded zip
    log_step "Post-extraction cleanup"
    rm -f "$ZIP_FILE"
    log_success

    # Set ownership and permissions
    log_step "Setting file permissions"
    chown -R container:container "$BASE_DIR" 2>/dev/null || true
    chmod -R 755 "$BASE_DIR" && log_success || log_warning "Chmod failed" "May need manual adjustment."
}

run_downloader() {
    log_step "Authenticating and fetching binaries"
    log_break 2

    # If HYTALE_PATCHLINE is defined, append the corresponding patchline flag to the download command.
    local DOWNLOAD_CMD="hytale-downloader"
    if [ -n "${HYTALE_PATCHLINE:-}" ]; then
        DOWNLOAD_CMD="$DOWNLOAD_CMD -patchline $HYTALE_PATCHLINE"
    fi

    if [ "$(id -u)" = "0" ]; then
        if command -v gosu >/dev/null 2>&1; then
            gosu container:container env HOME=/home/container sh -c "cd \$HOME && $DOWNLOAD_CMD"
        elif command -v su-exec >/dev/null 2>&1; then
            su-exec container:container env HOME=/home/container sh -c "cd \$HOME && $DOWNLOAD_CMD"
        else
            $DOWNLOAD_CMD
        fi
    else
        $DOWNLOAD_CMD
    fi
}

# ==========================================
# MAIN EXECUTION FLOW
# ==========================================

run_downloader

# Locate the downloaded ZIP file
ZIP_FILE=""
for f in "$BASE_DIR"/*.zip; do
    # Get just the filename
    filename=$(basename "$f")

    # Extract base name to validate against the pattern
    base="${filename%.zip}"

    # Regex breakdown:
    # ^[0-9]+\.[0-9]+\.[0-9]+  -> Matches the main version (e.g., 0.6.0)
    # (-[a-zA-Z0-9.-]+)?       -> Optionally matches a hyphen followed by pre-release info (e.g., -pre.7)
    # $                        -> End of string
    if echo "$base" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.-]+)?$'; then
        ZIP_FILE="$f"
        break
    fi
done

if [ -z "$ZIP_FILE" ]; then
    log_error "Download failed." "Could not find valid *.zip after download."
    exit 1
fi

log_break

# Extract and clean up
log_step "Extracting... (Please wait)"
extract_server "$ZIP_FILE"