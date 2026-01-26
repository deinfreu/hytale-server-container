#!/bin/sh
#
# Platform-agnostic script runner
# Detects the OS and runs the appropriate platform-specific script
#

set -e

# Detect distro from /etc/os-release
if [ -f /etc/os-release ]; then
    distro=$(grep -E "^ID=" /etc/os-release | cut -d= -f2 | sed -e 's/"//g')
else
    echo "ERROR: Cannot detect OS - /etc/os-release not found"
    exit 1
fi

script_name="$1"
script_dir="$(dirname "$0")"

# Map distro to our supported platforms
case "$distro" in
    alpine)
        platform="alpine"
        ;;
    ubuntu|debian)
        platform="ubuntu"
        ;;
    ol|oraclelinux)
        platform="ubuntu"  # Oracle Linux uses similar commands to Ubuntu/Debian
        ;;
    *)
        echo "WARNING: Unknown distro '$distro', trying ubuntu scripts..."
        platform="ubuntu"
        ;;
esac

script_path="${script_dir}/${platform}/${script_name}.sh"

if [ ! -f "$script_path" ]; then
    echo "ERROR: Script not found: $script_path"
    exit 1
fi

echo "Running: $script_path (detected: $distro -> $platform)"
exec "$script_path"
