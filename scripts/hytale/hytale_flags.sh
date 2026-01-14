#!/bin/sh
set -eu

# Load dependencies (Ensuring SCRIPTS_PATH is available from the parent)
. "$SCRIPTS_PATH/utils.sh"

log_section "JVM Flag Management"

# Initialize flags to ensure they are empty if not set
export HYTALE_CACHE_FLAG=""
export HYTALE_ACCEPT_EARLY_PLUGINS_FLAG=""
export HYTALE_ALLOW_OP_FLAG=""
export HYTALE_AUTH_MODE_FLAG=""
export HYTALE_BACKUP_FLAG=""
export HYTALE_BACKUP_FREQUENCY_FLAG=""

# 1. Cache Configuration
log_step "AOT Cache"
if [ "${CACHE:-}" = "TRUE" ]; then
    export HYTALE_CACHE_FLAG="-XX:AOTCache=HytaleServer.aot"
    log_success
else
    printf "${DIM}skipped${NC}\n"
fi

# 2. Plugin Permissions
log_step "Early Plugins"
if [ "${HYTALE_ACCEPT_EARLY_PLUGINS:-}" = "TRUE" ]; then
    export HYTALE_ACCEPT_EARLY_PLUGINS_FLAG="-XX:+HytaleAcceptEarlyPlugins"
    log_success
else
    printf "${DIM}disabled${NC}\n"
fi

# 3. Operator Permissions
log_step "Allow OP"
if [ "${HYTALE_ALLOW_OP:-}" = "TRUE" ]; then
    export HYTALE_ALLOW_OP_FLAG="-XX:+HytaleAllowOp"
    log_success
else
    printf "${DIM}disabled${NC}\n"
fi

# 4. Authentication Mode
log_step "Auth Mode"
if [ "${HYTALE_AUTH_MODE:-}" = "TRUE" ]; then
    export HYTALE_AUTH_MODE_FLAG="-XX:+HytaleAuthMode"
    log_success
else
    printf "${DIM}disabled${NC}\n"
fi

# 5. Backup System
log_step "Server Backups"
if [ "${HYTALE_BACKUP:-}" = "TRUE" ]; then
    export HYTALE_BACKUP_FLAG="-XX:+HytaleBackup"
    
    # Check frequency only if backup is enabled
    if [ -n "${HYTALE_BACKUP_FREQUENCY:-}" ]; then
        export HYTALE_BACKUP_FREQUENCY_FLAG="-XX:+HytaleBackupFrequency=$HYTALE_BACKUP_FREQUENCY"
        printf "${GREEN}enabled${NC} (${CYAN}${HYTALE_BACKUP_FREQUENCY}${NC})\n"
    else
        log_success
    fi
else
    printf "${DIM}disabled${NC}\n"
fi

# 6. Debug & Quiet Mode Logic
log_step "Quiet Mode"
if [ "${DEBUG:-FALSE}" = "FALSE" ]; then
    # Disable OOM Dumps and suppress fatal error messages for a cleaner production environment
    export HYTALE_QUIET_FLAGS="-XX:-HeapDumpOnOutOfMemoryError -XX:+SuppressFatalErrorMessage"
    log_success
else
    printf "${DIM}disabled (Debug Active)${NC}\n"
fi

printf "      ${DIM}↳ JVM Arguments:${NC} ${GREEN}Injection Ready${NC}\n"