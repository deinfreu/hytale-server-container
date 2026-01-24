#!/bin/sh
set -eu

# Load dependencies
. "$SCRIPTS_PATH/utils.sh"

log_section "Hytale Downloader"

# Version tracking file
VERSION_FILE="$BASE_DIR/.hytale_version"

# Get installed version info
get_installed_version() {
    if [ -f "$VERSION_FILE" ]; then
        cat "$VERSION_FILE"
    else
        echo "none|none"
    fi
}

# Save version info after install
save_version() {
    local version="$1"
    local patchline="$2"
    echo "${version}|${patchline}" > "$VERSION_FILE"
}

# Get available version from hytale-downloader
get_available_version() {
    hytale-downloader --patchline "$HYTALE_PATCHLINE" -print-version 2>/dev/null || echo "unknown"
}

# Helper function to extract and finalize
extract_server() {
    local zip_file="$1"
    local version="$2"
    
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
    
    # Save version info
    save_version "$version" "$HYTALE_PATCHLINE"
    
    chown -R container:container "$BASE_DIR" 2>/dev/null || true
    
    log_step "File Permissions"
    chmod -R 755 "$GAME_DIR" && log_success || log_warning "Chmod failed" "May need manual adjustment."
}

# Download and extract
download_and_install() {
    local reason="$1"
    
    log_warning "$reason"
    
    log_step "Checking Available Version"
    AVAILABLE_VERSION=$(get_available_version)
    if [ "${DEBUG:-FALSE}" = "TRUE" ]; then
        printf "      ${DIM}↳ Available:${NC} ${GREEN}%s${NC}\n" "$AVAILABLE_VERSION"
        printf "      ${DIM}↳ Patchline:${NC} ${GREEN}%s${NC}\n" "$HYTALE_PATCHLINE"
    fi
    
    log_step "Downloading"
    hytale-downloader --patchline "$HYTALE_PATCHLINE"
    
    ZIP_FILE=$(ls "$BASE_DIR"/[0-9][0-9][0-9][0-9].[0-9][0-9].[0-9][0-9]*.zip 2>/dev/null | head -n 1)
    
    if [ -z "$ZIP_FILE" ]; then
        log_error "Download failed." "Could not find valid YYYY.MM.DD*.zip after download."
        exit 1
    fi
    log_success
    
    # Extract version from filename (YYYY.MM.DD format)
    VERSION=$(basename "$ZIP_FILE" | grep -o '^[0-9]\{4\}\.[0-9]\{2\}\.[0-9]\{2\}')
    
    extract_server "$ZIP_FILE" "$VERSION"
}

# Clean existing installation for fresh download
# SAFE: Only removes server binaries ($GAME_DIR = /home/container/game/)
# PRESERVED: universe/ (worlds), mods/, config.json, .hytale-auth-tokens.json
clean_for_reinstall() {
    log_step "Cleaning for Reinstall"
    rm -rf "$GAME_DIR" 2>/dev/null || true
    rm -f "$VERSION_FILE" 2>/dev/null || true
    rm -f "$BASE_DIR"/*.zip 2>/dev/null || true
    log_success
}

# Main logic
log_step "Hytale Server Binary Check"

# Get current installed version and patchline
INSTALLED_INFO=$(get_installed_version)
INSTALLED_VERSION=$(echo "$INSTALLED_INFO" | cut -d'|' -f1)
INSTALLED_PATCHLINE=$(echo "$INSTALLED_INFO" | cut -d'|' -f2)

if [ "${DEBUG:-FALSE}" = "TRUE" ]; then
    printf "      ${DIM}↳ Installed:${NC} %s (%s)\n" "$INSTALLED_VERSION" "$INSTALLED_PATCHLINE"
    printf "      ${DIM}↳ Requested:${NC} %s\n" "$HYTALE_PATCHLINE"
fi

# Check for existing update package first (manual download)
ZIP_FILE=$(ls "$BASE_DIR"/[0-9][0-9][0-9][0-9].[0-9][0-9].[0-9][0-9]*.zip 2>/dev/null | head -n 1)

if [ -n "$ZIP_FILE" ]; then
    # Manual update package detected
    log_warning "Update package detected." "Applying server update..."
    VERSION=$(basename "$ZIP_FILE" | grep -o '^[0-9]\{4\}\.[0-9]\{2\}\.[0-9]\{2\}')
    if [ "${DEBUG:-FALSE}" = "TRUE" ]; then
        printf "      ${DIM}↳ Package:${NC} %s\n" "$(basename "$ZIP_FILE")"
    fi
    extract_server "$ZIP_FILE" "$VERSION"

elif [ ! -f "$SERVER_JAR_PATH" ]; then
    # No jar - fresh install required
    log_success
    download_and_install "HytaleServer.jar not found. Downloading fresh installation..."

elif [ "$INSTALLED_VERSION" = "none" ] || [ ! -f "$VERSION_FILE" ]; then
    # FAILSAFE: JAR exists but no version tracking - inconsistent state
    # Clean and re-download to ensure known-good state
    log_success
    log_warning "Version tracking missing." "Server exists but version unknown. Cleaning for fresh download..."
    clean_for_reinstall
    download_and_install "Reinstalling to establish version tracking..."

elif [ "$INSTALLED_PATCHLINE" != "$HYTALE_PATCHLINE" ]; then
    # Patchline changed - need to re-download
    log_success
    download_and_install "Patchline changed ($INSTALLED_PATCHLINE → $HYTALE_PATCHLINE). Re-downloading..."

else
    # Check for updates
    log_success
    AVAILABLE_VERSION=$(get_available_version)
    
    if [ "$AVAILABLE_VERSION" != "unknown" ] && [ "$AVAILABLE_VERSION" != "$INSTALLED_VERSION" ]; then
        download_and_install "Update available ($INSTALLED_VERSION → $AVAILABLE_VERSION). Downloading..."
    else
        printf "      ${DIM}↳ Info:${NC} Server up-to-date (v%s, %s)\n" "$INSTALLED_VERSION" "$INSTALLED_PATCHLINE"
        printf "      ${DIM}↳ Note:${NC} Place YYYY.MM.DD*.zip in %s to trigger manual update.\n" "$BASE_DIR"
    fi
fi