#!/bin/sh
. "$SCRIPTS_PATH/utils.sh"

# ==========================================
# HELPER FUNCTIONS
# ==========================================

check_connectivity() {
    log_step "Internet Connectivity"
    if PUBLIC_IP=$(curl -s --connect-timeout 5 https://api.ipify.org); then
        log_success
        echo -e "      ${DIM}↳ Public IP:${NC} ${GREEN}${PUBLIC_IP}${NC}"
    else
        log_error "External connection failed." \
        "The container cannot reach api.ipify.org. Check your Docker DNS or host firewall."
    fi
}

validate_port_cfg() {
    log_step "Port Validity"
    local port="${SERVER_PORT:-23000}"

    if ! echo "$port" | grep -Eq '^[0-9]+$' || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
        log_error "Invalid port: $port" \
        "SERVER_PORT must be a number between 1 and 65535."
    else
        log_success
    fi
}

check_port_availability() {
    local port="${SERVER_PORT:-23000}"
    log_step "Port $port Availability"

    if ss -ulpn | grep -q ":$port "; then
        log_error "Port $port is ALREADY in use!" \
        "Another process is using this port. Change SERVER_PORT or stop the conflicting container."
    else
        log_success
    fi
}

check_udp_stack() {
    log_step "Local UDP Loopback"
    if (echo > /dev/udp/127.0.0.1/"${SERVER_PORT:-23000}") 2>/dev/null; then
        log_success
    else
        log_warning "Shell /dev/udp not supported." \
        "This is common in minimal Alpine shells and can usually be ignored."
    fi

    local RMEM_PATH="/proc/sys/net/core/rmem_max"

    log_step "UDP Socket Buffer Size"
    if [ -r "$RMEM_PATH" ]; then
        local RMEM_MAX=$(cat "$RMEM_PATH")

        if [ "$RMEM_MAX" -lt 2097152 ]; then
            log_warning "UDP buffers are low ($RMEM_MAX)." \
            "QUIC performance may suffer. Recommended: sysctl -w net.core.rmem_max=2097152"
        else
            log_success
        fi
    else
        log_error "Cannot read UDP limits." \
        "Access to /proc/sys/net is restricted. Container may lack NET_ADMIN capabilities."
    fi
}

# ==========================================
# MAIN EXECUTION FLOW
# ==========================================