#!/bin/sh
set -eu

# Load dependencies
. "$SCRIPTS_PATH/utils.sh"

# --- Legacy Path Migration ---
log_section "Migrate Check"

LEGACY_ROOT="/home/container/game"
LEGACY_SERVER_DIR="$LEGACY_ROOT/Server"
TARGET_SERVER_DIR="/home/container/Server"

if [ ! -d "$LEGACY_SERVER_DIR" ]; then
	log_step "Legacy server path"
	printf "${DIM}not found (skip)${NC}\n"
	exit 0
fi

log_step "Ensure target directory"
mkdir -p "$TARGET_SERVER_DIR"
log_success

MOVED_ANY=false

for item in "Licenses" "HytaleServer.aot" "HytaleServer.jar"; do
	if [ -e "$LEGACY_SERVER_DIR/$item" ]; then
		log_step "Move $item"
		mv "$LEGACY_SERVER_DIR/$item" "$TARGET_SERVER_DIR/"
		log_success
		MOVED_ANY=true
	else
		log_step "Move $item"
		printf "${DIM}not present (skip)${NC}\n"
	fi
done

if [ "$MOVED_ANY" = "true" ]; then
	log_step "Remove legacy /game folder"
	rm -rf "$LEGACY_ROOT"
	log_success
else
	log_step "Remove legacy /game folder"
	printf "${DIM}no migration performed (skip)${NC}\n"
fi