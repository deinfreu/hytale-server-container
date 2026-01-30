#!/bin/sh
set -eu

# Load dependencies
. "$SCRIPTS_PATH/utils.sh"

log_section "Hytale Server Update"

# Helper function to extract to staging and apply
extract_and_stage_server() {
    local zip_file="$1"
    
    log_step "Extracting to staging area"
    
    # Create staging directory
    mkdir -p "$GAME_DIR/updater/staging"
    
    if [ "${DEBUG:-FALSE}" = "TRUE" ]; then
        printf "      ${DIM}↳ Source:${NC} %s\n" "$(basename "$zip_file")"
        printf "      ${DIM}↳ Staging:${NC} ${GREEN}%s${NC}\n" "$GAME_DIR/updater/staging"
    fi
    
    # Extract to staging area
    if 7z x "$zip_file" -aoa -bsp1 -mmt=on -o"$GAME_DIR/updater/staging" >/dev/null 2>&1; then
        log_success
    else
        log_error "Extraction failed" "Check disk space or 7z compatibility."
        exit 1
    fi
    
    log_step "Applying staged update"
    
    # Apply staged files - only replace server binaries, preserve config/saves/mods
    cd "$GAME_DIR"
    
    if [ -f "updater/staging/Server/HytaleServer.jar" ]; then
        cp -f updater/staging/Server/HytaleServer.jar Server/
        [ -f "updater/staging/Server/HytaleServer.aot" ] && cp -f updater/staging/Server/HytaleServer.aot Server/
        [ -d "updater/staging/Server/Licenses" ] && rm -rf Server/Licenses && cp -r updater/staging/Server/Licenses Server/
        [ -f "updater/staging/Assets.zip" ] && cp -f updater/staging/Assets.zip ./
        [ -f "updater/staging/start.sh" ] && cp -f updater/staging/start.sh ./
        [ -f "updater/staging/start.bat" ] && cp -f updater/staging/start.bat ./
        
        log_success
        
        if [ "${DEBUG:-FALSE}" = "TRUE" ]; then
            printf "      ${DIM}↳ Note:${NC} Server binaries updated. User data preserved.\n"
        fi
    else
        log_error "Invalid update package" "Missing Server/HytaleServer.jar"
        rm -rf updater/staging
        exit 1
    fi
    
    log_step "Cleaning up"
    rm -f "$zip_file"
    rm -rf updater/staging
    log_success
    
    chown -R container:container "$BASE_DIR" 2>/dev/null || true
    
    log_step "File Permissions"
    chmod -R 755 "$GAME_DIR" && log_success || log_warning "Chmod failed" "May need manual adjustment."
}

# Main logic - update existing installation
log_warning "Update package detected." "Applying server update..."

# Check for update package
ZIP_FILE=$(ls "$BASE_DIR"/[0-9][0-9][0-9][0-9].[0-9][0-9].[0-9][0-9]*.zip 2>/dev/null | head -n 1)

if [ -z "$ZIP_FILE" ]; then
    log_error "No update package found." "Expected YYYY.MM.DD*.zip in $BASE_DIR"
    exit 1
fi

if [ "${DEBUG:-FALSE}" = "TRUE" ]; then
    printf "      ${DIM}↳ Package:${NC} %s\n" "$(basename "$ZIP_FILE")"
fi

extract_and_stage_server "$ZIP_FILE"
