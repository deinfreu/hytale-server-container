#!/bin/bash
set -e

# ==========================================
# HELPER FUNCTIONS
# ==========================================

check_arch() {
    local arch=$(uname -m)
    if [ "$arch" != "aarch64" ] && [ "$arch" != "arm64" ]; then
        echo "Warning: This script is designed for ARM64/aarch64 systems."
        echo "   Detected architecture: $arch"
        read -p "Continue anyway? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 0
        fi
    fi
}

check_docker() {
    if ! command -v docker &> /dev/null; then
        echo "Error: Docker is not installed or not in PATH"
        echo "   Please install Docker first: https://docs.docker.com/engine/install/"
        exit 1
    fi
}

get_docker_cmd() {
    if [ "$EUID" -eq 0 ]; then
        echo "docker"
    elif docker ps &> /dev/null; then
        echo "docker"
    elif sudo -n docker ps &> /dev/null 2>&1; then
        echo "sudo docker"
    else
        echo "sudo docker"
    fi
}

install_binfmt() {
    local cmd="$1"
    if $cmd run --privileged --rm tonistiigi/binfmt --install amd64; then
        return 0
    fi
    return 1
}

verify_installation() {
    local cmd="$1"
    $cmd run --privileged --rm tonistiigi/binfmt | grep -q "qemu-x86_64"
}

# ==========================================
# MAIN EXECUTION FLOW
# ==========================================

echo "=================================="
echo "ARM64 Host Setup for Hytale Server"
echo "=================================="
echo ""

check_arch
check_docker

echo "Architecture: $(uname -m)"
echo "Docker: $(docker --version)"
echo ""

DOCKER_CMD=$(get_docker_cmd)
if [ "$DOCKER_CMD" = "sudo docker" ] && [ "$EUID" != 0 ]; then
    echo "Using sudo for Docker commands"
fi

echo "Installing QEMU binfmt_misc support for x86_64 emulation..."
echo ""

if install_binfmt "$DOCKER_CMD"; then
    echo ""
    echo "Success! x86_64 emulation is now enabled."
    echo ""

    if verify_installation "$DOCKER_CMD"; then
        echo "qemu-x86_64 emulator is active"
        echo ""
        echo "=========================================="
        echo "Setup Complete!"
        echo "=========================================="
        echo ""
        echo "Run the Hytale server container:"
        echo "  docker compose up -d"
        echo ""
        echo "Note: Registration persists until reboot."
        echo "      Re-run this script after rebooting."
    else
        echo "Warning: Installation completed but verification failed"
        echo "   The emulator may still work, try running the container"
    fi
else
    echo ""
    echo "Error: Failed to install binfmt support"
    echo ""
    echo "Troubleshooting:"
    echo "  1. Ensure Docker is running: sudo systemctl status docker"
    echo "  2. Check Docker permissions: docker ps"
    echo "  3. Verify kernel support: ls /proc/sys/fs/binfmt_misc/"
    echo ""
    exit 1
fi