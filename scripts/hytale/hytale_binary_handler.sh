#!/bin/sh
set -eu

# Load dependencies
. "$SCRIPTS_PATH/utils.sh"

# ==========================================
# HELPER FUNCTIONS
# ==========================================

determine_install_state() {
    # Search for staged update zip
    zip_file=""
    for f in "$BASE_DIR"/*.zip; do
        if [ -e "$f" ]; then
            zip_file="$f"
            break
        fi
    done

    # Decision logic based on detection
    if [ -n "$zip_file" ]; then
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