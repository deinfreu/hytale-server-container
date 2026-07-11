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

extract_and_stage_server() {
    local ZIP_FILE="$1"
    local STAGING_DIR="$GAME_DIR/updater/staging"

    log_step "Extracting to staging area"
    rm -rf "$STAGING_DIR"
    mkdir -p "$STAGING_DIR"

    if [ "${DEBUG:-FALSE}" = "TRUE" ]; then
        printf "      ${DIM}↳ Source:${NC} %s\n" "$(basename "$ZIP_FILE")"
        printf "      ${DIM}↳ Target:${NC} ${GREEN}%s${NC}\n" "$STAGING_DIR"
    fi

    # Extract into the staging area (NOT $BASE_DIR): the apply step below copies
    # from updater/staging/ into the live server dirs. Extracting straight to
    # $BASE_DIR left staging empty, so the "Missing Server/HytaleServer.jar"
    # guard always tripped and no update was ever applied.
    if 7z x "$ZIP_FILE" -aoa -bsp1 -mmt=on -o"$STAGING_DIR" >/dev/null 2>&1; then
        log_success
    else
        log_error "Extraction failed" "Check disk space or 7z compatibility."
        exit 1
    fi

    # Apply staged files to server directories
    cd "$GAME_DIR"
    if [ -f "updater/staging/Server/HytaleServer.jar" ]; then
        cp -f updater/staging/Server/HytaleServer.jar Server/
        [ -f "updater/staging/Server/HytaleServer.aot" ]  && cp -f updater/staging/Server/HytaleServer.aot Server/
        [ -d "updater/staging/Server/Licenses" ]          && rm -rf Server/Licenses && cp -r updater/staging/Server/Licenses Server/
        [ -f "updater/staging/Assets.zip" ]               && cp -f updater/staging/Assets.zip ./
        [ -f "updater/staging/start.sh" ]                 && cp -f updater/staging/start.sh ./
        [ -f "updater/staging/start.bat" ]                && cp -f updater/staging/start.bat ./
        log_success
    else
        log_error "Invalid update package" "Missing Server/HytaleServer.jar"
        rm -rf updater/staging
        exit 1
    fi

    # Cleanup and permissions
    log_step "Cleaning up"
    rm -f "$ZIP_FILE"
    rm -rf updater/staging
    chown -R container:container "$BASE_DIR" 2>/dev/null || true
    chmod -R 755 "$BASE_DIR" && log_success || log_warning "Chmod failed" "May need manual adjustment."
}

# ==========================================
# MAIN EXECUTION FLOW
# ==========================================

log_section "Hytale Server Update"
log_warning "Update package detected." "Applying server update..."

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

if [ -z "$ZIP_FILE" ]; then
    log_error "No update package found." "Expected *.zip in $BASE_DIR"
    exit 1
fi

[ "${DEBUG:-FALSE}" = "TRUE" ] && printf "      ${DIM}↳ Package:${NC} %s\n" "$(basename "$ZIP_FILE")"

extract_and_stage_server "$ZIP_FILE"