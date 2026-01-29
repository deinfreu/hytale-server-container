#!/bin/sh
set -eu

# Load dependencies
. "$SCRIPTS_PATH/utils.sh"

# Architecture check for Hytale server compatibility
ARCH=$(uname -m)
if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    printf "\n${RED}############################################################${NC}\n"
    printf "${RED}  WARNING: UNSUPPORTED ARCHITECTURE DETECTED${NC}\n"
    printf "${RED}############################################################${NC}\n"
    printf "${RED} Architecture:${NC} %s\n" "$ARCH"
    printf "${RED} Status:${NC} Waiting for Hytale to release the native ARM64 binary.\n"
    printf "${RED}############################################################${NC}\n\n"
fi
