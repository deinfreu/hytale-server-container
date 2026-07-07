#!/bin/sh
set -eu

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
    log_error "Download failed." "Could not find valid *.zip after download."
    exit 1
fi

log_break

# Extract and clean up
log_step "Extracting... (Please wait)"
extract_server "$ZIP_FILE"