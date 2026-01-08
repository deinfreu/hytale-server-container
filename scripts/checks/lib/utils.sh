#!/bin/sh

# Colors
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
RESET="\033[0m"

# Centralized Log Function
# Usage: log "message" "$COLOR" "prefix"
log() {
    local msg="$1"
    local color="${2:-$RESET}"
    local prefix="${3:-security-check}"
    echo "${color}[${prefix}] ${msg}${RESET}"
}