#!/bin/sh
set -eu

# Load dependencies
. "$SCRIPTS_PATH/utils.sh"

# ==========================================
# HELPER FUNCTIONS
# ==========================================

extract_and_stage_server() {
    local zip_file="$1"

    log_step "Extracting to staging area"
    mkdir -p "$GAME_DIR/updater/staging"

    if [ "${DEBUG:-FALSE}" = "TRUE" ]; then
        printf "      ${DIM}↳ Source:${NC} %s\n" "$(basename "$zip_file")"
        printf "      ${DIM}↳ Target:${NC} ${GREEN}%s${NC}\n" "$BASE_DIR"
    fi

    # Overwrites only archived files; user data/configs/mods untouched
    if 7z x "$zip_file" -aoa -bsp1 -mmt=on -o"$BASE_DIR" >/dev/null 2>&1; then
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
    rm -f "$zip_file"
    rm -rf updater/staging
    chown -R container:container "$BASE_DIR" 2>/dev/null || true
    chmod -R 755 "$BASE_DIR" && log_success || log_warning "Chmod failed" "May need manual adjustment."
}

# ==========================================
# MAIN EXECUTION FLOW
# ==========================================

log_section "Hytale Server Update"
log_warning "Update package detected." "Applying server update..."

ZIP_FILE=""
for f in "$BASE_DIR"/*.zip; do
    if [ -e "$f" ]; then
        ZIP_FILE="$f"
        break
    fi
done

if [ -z "$ZIP_FILE" ]; then
    log_error "No update package found." "Expected *.zip in $BASE_DIR"
    exit 1
fi

[ "${DEBUG:-FALSE}" = "TRUE" ] && printf "      ${DIM}↳ Package:${NC} %s\n" "$(basename "$ZIP_FILE")"

extract_and_stage_server "$ZIP_FILE"