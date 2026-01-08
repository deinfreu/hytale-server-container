#!/bin/sh

validate_port_cfg() {
    if [ -n "$SERVER_PORT" ]; then
        if ! echo "$SERVER_PORT" | grep -Eq '^[0-9]+$' || [ "$SERVER_PORT" -lt 1 ] || [ "$SERVER_PORT" -gt 65535 ]; then
            log "Warning: SERVER_PORT '$SERVER_PORT' is invalid (1-65535)." "$YELLOW" "cfg"
        else
            log "Port $SERVER_PORT is a valid integer." "$GREEN" "cfg"
        fi
    fi
}

check_port_availability() {
    # Check if the port is already bound (prevents "Address already in use" crashes)
    if ss -ulpn | grep -q ":$SERVER_PORT "; then
        log "CRITICAL: Port $SERVER_PORT is ALREADY in use by another process!" "$RED" "net"
    else
        log "Port $SERVER_PORT is available for binding." "$GREEN" "net"
    fi
}

check_udp_stack() {
    log "Testing UDP socket responsiveness..." "$BLUE" "net"
    if (echo > /dev/udp/127.0.0.1/"$SERVER_PORT") 2>/dev/null; then
        log "QUIC: Local UDP loopback is reachable." "$GREEN" "net"
    else
        log "Warning: Shell /dev/udp redirection not supported or blocked." "$YELLOW" "net"
    fi

    # QUIC Buffer Checks
    RMEM_PATH="/proc/sys/net/core/rmem_max"
    WMEM_PATH="/proc/sys/net/core/wmem_max"

    if [ -r "$RMEM_PATH" ] && [ -r "$WMEM_PATH" ]; then
        RMEM_MAX=$(cat "$RMEM_PATH")
        WMEM_MAX=$(cat "$WMEM_PATH")
        if [ "$RMEM_MAX" -lt 2097152 ] || [ "$WMEM_MAX" -lt 2097152 ]; then
            log "Warning: UDP buffers are small (rmem=$RMEM_MAX). QUIC may drop packets." "$YELLOW" "net"
        else
            log "QUIC: UDP buffers are optimized." "$GREEN" "net"
        fi
    else
        log "Warning: Cannot read UDP buffer limits. Access restricted." "$YELLOW" "net"
    fi
}

check_connectivity() {
    if curl -s --connect-timeout 5 https://google.com > /dev/null; then
        log "Internet access verified." "$GREEN" "conn"
        PUBLIC_IP=$(curl -s --connect-timeout 5 https://api.ipify.org)
        log "Public IP: $PUBLIC_IP" "$GREEN" "conn"
    else
        log "Warning: No internet access. Auth & Updates will fail." "$YELLOW" "conn"
    fi
}