#!/bin/sh
set -eu

# Load dependencies
. "$SCRIPTS_PATH/utils.sh"

# EULA Check (Redirected to $HOME)
case "$EULA" in
    [Tt][Rr][Uu][Ee])
        log "[init]" "Accepting EULA..." "$GREEN"
        echo "eula=true" > "${HOME}/eula.txt"
        ;;
    *)
        if [ ! -f "${HOME}/eula.txt" ] || ! grep -q "eula=true" "${HOME}/eula.txt"; then
            log "[error]" "EULA=true environment variable required." "$RED"
            exit 1
        fi
        ;;
esac