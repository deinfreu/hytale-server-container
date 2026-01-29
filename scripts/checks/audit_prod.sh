#!/bin/sh
set -u

# Load dependencies
. "$SCRIPTS_PATH/utils.sh"
. "$SCRIPTS_PATH/checks/lib/prod_logic.sh"

# Execute
log_section "Production Readiness Audit"

# These functions (from prod_logic.sh) now use the standardized log_step format
check_java_mem
check_system_resources
check_filesystem
check_stability

echo -e "\n${BOLD}${GREEN}✔ Production readiness audit complete.${NC}"
exit 0