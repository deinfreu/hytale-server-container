#!/bin/sh

# ==========================================
# COLORS & FORMATTING
# ==========================================

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

# ==========================================
# HELPER FUNCTIONS
# ==========================================

log_break() {
    local lines="${1:-1}"
    while [ "$lines" -gt 0 ]; do
        printf "\n"
        lines=$((lines - 1))
    done
}

log_section() {
    printf "\n${BOLD}${CYAN}SECTION:${NC} ${BOLD}%s${NC}\n" "${1:-}"
}

log_step() {
    printf "  ${NC}%-35s" "${1:-}..."
}

log_success() {
    if [ "${NO_COLOR:-FALSE}" = "TRUE" ]; then
        printf "[ OK ]\n"
    else
        printf "[ ${GREEN}OK${NC} ] %b\n" "${SYM_OK}"
    fi
}

log_warning() {
    if [ "${NO_COLOR:-FALSE}" = "TRUE" ]; then
        printf "[ WARN ]\n"
    else
        printf "[ ${YELLOW}WARN${NC} ] %b\n" "${SYM_WARN}"
    fi
    printf "      ${YELLOW}↳ Note:${NC}  %s\n" "${1:-}"
    if [ -n "${2:-}" ]; then
        printf "      ${DIM}↳ Suggestion: %s${NC}\n" "${2}"
    fi
}

log_error() {
    if [ "${NO_COLOR:-FALSE}" = "TRUE" ]; then
        printf "[ FAIL ]\n"
    else
        printf "[ ${RED}FAIL${NC} ] %b\n" "${SYM_FAIL}"
    fi
    printf "      ${RED}↳ Error:${NC} %s\n" "${1:-}"
    if [ -n "${2:-}" ]; then
        printf "      ${DIM}↳ Hint:   %s${NC}\n" "${2}"
    fi

    if [ "${DEBUG:-FALSE}" != "TRUE" ]; then
        exit 1
    fi
}

# ==========================================
# MAIN EXECUTION FLOW
# ==========================================