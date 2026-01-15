#!/bin/sh

# --- Colors & Formatting ---
# Disable colors if NO_COLOR is set
if [ "${NO_COLOR:-FALSE}" = "TRUE" ]; then
    BOLD=''
    DIM=''
    GREEN=''
    RED=''
    YELLOW=''
    CYAN=''
    NC=''
    SYM_OK='OK'
    SYM_FAIL='FAIL'
    SYM_WARN='WARN'
else
    BOLD='\033[1m'
    DIM='\033[2m'
    GREEN='\033[0;32m'
    RED='\033[0;31m'
    YELLOW='\033[0;33m'
    CYAN='\033[0;36m'
    NC='\033[0m'
    SYM_OK="${GREEN}✔${NC}"
    SYM_FAIL="${RED}✘${NC}"
    SYM_WARN="${YELLOW}⚠${NC}"
fi

log_section() {
    # %b allows backslash escapes in the arguments
    printf "\n${BOLD}${CYAN}SECTION:${NC} ${BOLD}%s${NC}\n" "${1:-}"
}

log_step() {
    printf "  ${NC}%-35s" "${1:-}..."
}

log_success() {
    printf "[ ${GREEN}OK${NC} ] %b\n" "${SYM_OK}"
}

log_warning() {
    printf "[ ${YELLOW}WARN${NC} ] %b\n" "${SYM_WARN}"
    printf "      ${YELLOW}↳ Note:${NC}  %s\n" "${1:-}"
    if [ -n "${2:-}" ]; then
        printf "      ${DIM}↳ Suggestion: %s${NC}\n" "${2}"
    fi
}

log_error() {
    printf "[ ${RED}FAIL${NC} ] %b\n" "${SYM_FAIL}"
    printf "      ${RED}↳ Error:${NC} %s\n" "${1:-}"
    if [ -n "${2:-}" ]; then
        printf "      ${DIM}↳ Hint:   %s${NC}\n" "${2}"
    fi
}