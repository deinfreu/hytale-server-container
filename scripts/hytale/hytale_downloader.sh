#!/bin/sh
set -eu

# Load dependencies
. "$SCRIPTS_PATH/utils.sh"

log_section "Hytale Downloader"

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

# Main logic
log_step "Hytale Server Binary Check"

# Check for existing update package first (manual download or update)
ZIP_FILE=$(ls "$BASE_DIR"/[0-9][0-9][0-9][0-9].[0-9][0-9].[0-9][0-9]*.zip 2>/dev/null | head -n 1)

if [ -n "$ZIP_FILE" ]; then
    # Update available - extract regardless of jar status
    log_warning "Update package detected." "Applying server update..."
    if [ "${DEBUG:-FALSE}" = "TRUE" ]; then
        printf "      ${DIM}↳ Package:${NC} %s\n" "$(basename "$ZIP_FILE")"
    fi
    extract_server "$ZIP_FILE"
elif [ ! -f "$SERVER_JAR_PATH" ]; then
    # No jar and no zip - fresh install required
    log_warning "HytaleServer.jar not found." "Downloading fresh installation..."
    
    log_step "Download Status"
    if [ "${DEBUG:-FALSE}" = "TRUE" ]; then
        printf "      ${DIM}↳ Patchline:${NC} ${GREEN}%s${NC}\n" "$HYTALE_PATCHLINE"
    fi
    hytale-downloader --patchline "$HYTALE_PATCHLINE"
    
    ZIP_FILE=$(ls "$BASE_DIR"/[0-9][0-9][0-9][0-9].[0-9][0-9].[0-9][0-9]*.zip 2>/dev/null | head -n 1)
    
    if [ -z "$ZIP_FILE" ]; then
        log_error "Download failed." "Could not find valid YYYY.MM.DD*.zip after download."
        exit 1
    fi
    log_success
    
    extract_server "$ZIP_FILE"
else
    # Server already installed, no updates
    log_success
    printf "      ${DIM}↳ Info:${NC} Server up-to-date. Skipping extraction.\n"
    printf "      ${DIM}↳ Note:${NC} Place YYYY.MM.DD*.zip in %s to trigger update.\n" "$BASE_DIR"
fi