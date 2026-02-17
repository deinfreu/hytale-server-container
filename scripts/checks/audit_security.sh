#!/bin/sh
set -u

# Load dependencies
. "$SCRIPTS_PATH/utils.sh"
. "$SCRIPTS_PATH/checks/lib/security_logic.sh"

# Execute
log_section "Security & Integrity Audit"

# These functions (inside security_logic.sh) now use the log_step format
check_integrity
check_container_hardening
check_clock_sync

echo -e "\n${BOLD}${GREEN}✔ Security audit complete.${NC}"
exit 0