#!/bin/bash
set -e

echo "=================================="
echo "ARM64 Host Setup for Hytale Server"
echo "=================================="
echo ""

# Check if running on ARM64
ARCH=$(uname -m)
if [ "$ARCH" != "aarch64" ] && [ "$ARCH" != "arm64" ]; then
    echo "⚠️  Warning: This script is designed for ARM64/aarch64 systems."
    echo "   Detected architecture: $ARCH"
    echo ""
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo "❌ Error: Docker is not installed or not in PATH"
    echo "   Please install Docker first: https://docs.docker.com/engine/install/"
    exit 1
fi

echo "✓ Architecture: $ARCH"
echo "✓ Docker: $(docker --version)"
echo ""

# Check if running with sufficient privileges
if [ "$EUID" -eq 0 ]; then 
    DOCKER_CMD="docker"
else
    # Check if user can run docker without sudo
    if docker ps &> /dev/null; then
        DOCKER_CMD="docker"
    elif sudo -n docker ps &> /dev/null 2>&1; then
        DOCKER_CMD="sudo docker"
        echo "ℹ️  Using sudo for Docker commands"
    else
        echo "⚠️  This script requires Docker privileges."
        echo "   You may be prompted for your password."
        DOCKER_CMD="sudo docker"
    fi
fi

echo "Installing QEMU binfmt_misc support for x86_64 emulation..."
echo ""

# Install binfmt support using tonistiigi/binfmt
if $DOCKER_CMD run --privileged --rm tonistiigi/binfmt --install amd64; then
    echo ""
    echo "✅ Success! x86_64 emulation is now enabled."
    echo ""
    
    # Verify installation
    echo "Verifying installation..."
    if $DOCKER_CMD run --privileged --rm tonistiigi/binfmt | grep -q "qemu-x86_64"; then
        echo "✓ qemu-x86_64 emulator is active"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Setup Complete!"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "You can now run the Hytale server container:"
        echo "  docker compose up -d"
        echo ""
        echo "Note: This registration persists until reboot."
        echo "      Re-run this script after rebooting your system."
        echo ""
    else
        echo "⚠️  Warning: Installation completed but verification failed"
        echo "   The emulator may still work, try running the container"
    fi
else
    echo ""
    echo "❌ Error: Failed to install binfmt support"
    echo ""
    echo "Troubleshooting:"
    echo "  1. Ensure Docker is running: sudo systemctl status docker"
    echo "  2. Check Docker permissions: docker ps"
    echo "  3. Verify kernel support: ls /proc/sys/fs/binfmt_misc/"
    echo ""
    exit 1
fi
