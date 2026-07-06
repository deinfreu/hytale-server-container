#!/bin/sh
set -eu

. "$SCRIPTS_PATH/utils.sh"

# ==========================================
# HELPER FUNCTIONS
# ==========================================

check_arch() {
    local arch=$(uname -m)
    if [ "$arch" = "aarch64" ] || [ "$arch" = "arm64" ]; then
        printf "\n${RED}############################################################${NC}\n"
        printf "${RED}  WARNING: UNSUPPORTED ARCHITECTURE DETECTED${NC}\n"
        printf "${RED}############################################################${NC}\n"
        printf "${RED} Architecture:${NC} %s\n" "$arch"
        printf "${RED} Status:${NC} Waiting for Hytale to release the native ARM64 binary.\n"
        printf "${RED}############################################################${NC}\n\n"
    fi
}

# ==========================================
# MAIN EXECUTION FLOW
# ==========================================

check_arch