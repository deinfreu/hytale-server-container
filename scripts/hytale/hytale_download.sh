#!/bin/sh
set -eu

# Load dependencies
. "$SCRIPTS_PATH/utils.sh"

# ==========================================
# HELPER FUNCTIONS
# ==========================================

extract_server() {
    local zip_file="$1"

    if [ "${DEBUG:-FALSE}" = "TRUE" ]; then
        printf "      ${DIM}↳ Source:${NC} %s\n" "$(basename "$zip_file")"
        printf "      ${DIM}↳ Target:${NC} %s\n" "$BASE_DIR"
    fi

    if unzip -qo "$zip_file" -d "$BASE_DIR"; then
        log_success
    else
        log_error "Extraction failed" "Check disk space or zip file integrity."
        exit 1
    fi

    # Remove downloaded zip
    log_step "Post-extraction cleanup"
    rm -f "$zip_file"
    log_success

    # Set ownership and permissions
    log_step "Setting file permissions"
    chown -R container:container "$BASE_DIR" 2>/dev/null || true
    chmod -R 755 "$BASE_DIR" && log_success || log_warning "Chmod failed" "May need manual adjustment."
}

run_downloader() {
    log_step "Authenticating and fetching binaries"
    log_break 2

    if [ "$(id -u)" = "0" ]; then
        if command -v gosu >/dev/null 2>&1; then
            gosu container:container env HOME=/home/container sh -c 'cd $HOME && hytale-downloader'
        elif command -v su-exec >/dev/null 2>&1; then
            su-exec container:container env HOME=/home/container sh -c 'cd $HOME && hytale-downloader'
        else
            hytale-downloader
        fi
    else
        hytale-downloader
    fi
}

# ==========================================
# MAIN EXECUTION FLOW
# ==========================================

run_downloader

# Locate the downloaded ZIP file
ZIP_FILE=""
for f in "$BASE_DIR"/*.zip; do
    if [ -e "$f" ]; then
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