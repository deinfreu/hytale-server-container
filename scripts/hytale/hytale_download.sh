#!/bin/sh
set -eu

# Load dependencies
. "$SCRIPTS_PATH/utils.sh"

log_section "Hytale Initial Download"

# Helper function to extract and finalize
extract_server() {
    local zip_file="$1"
    
    log_step "Extracting Game Content"
    
    if [ "${DEBUG:-FALSE}" = "TRUE" ]; then
        printf "      ${DIM}↳ Source:${NC} %s\n" "$(basename "$zip_file")"
        printf "      ${DIM}↳ Target:${NC} ${GREEN}%s${NC}\n" "$GAME_DIR"
    fi
    
    # SAFE EXTRACTION: Only overwrites files from the archive
    # Files not in the archive (user data, configs, mods) remain untouched
    if 7z x "$zip_file" -aoa -bsp1 -mmt=on -o"$GAME_DIR" >/dev/null 2>&1; then
        log_success
        if [ "${DEBUG:-FALSE}" = "TRUE" ]; then
            printf "      ${DIM}↳ Note:${NC} Server binaries updated. User data preserved.\n"
        fi
    else
        log_error "Extraction failed" "Check disk space or 7z compatibility."
        exit 1
    fi
    
    log_step "Post-Extraction Cleanup"
    rm -f "$zip_file"
    log_success
    
    chown -R container:container "$BASE_DIR" 2>/dev/null || true
    
    log_step "File Permissions"
    chmod -R 755 "$GAME_DIR" && log_success || log_warning "Chmod failed" "May need manual adjustment."
}

# Main logic - fresh install
log_warning "HytaleServer.jar not found." "Downloading fresh installation..."

log_step "Download Status"

# Determine user switching command
if [ "$(id -u)" = "0" ]; then
    if command -v gosu >/dev/null 2>&1; then
        SWITCH_USER="gosu container:container"
    elif command -v su-exec >/dev/null 2>&1; then
        SWITCH_USER="su-exec container:container"
    else
        SWITCH_USER=""
    fi
else
    SWITCH_USER=""
fi

# Run hytale-downloader as container user
$SWITCH_USER hytale-downloader

ZIP_FILE=$(ls "$BASE_DIR"/[0-9][0-9][0-9][0-9].[0-9][0-9].[0-9][0-9]*.zip 2>/dev/null | head -n 1)

if [ -z "$ZIP_FILE" ]; then
    log_error "Download failed." "Could not find valid YYYY.MM.DD*.zip after download."
    exit 1
fi
log_success

extract_server "$ZIP_FILE"
