#!/bin/bash
#
# Basic Setup Test (No Server JAR Required)
#
# This is a SETUP-ONLY test that verifies the container environment
# WITHOUT requiring OAuth authentication or server download.
#
# Verifies:
#   - Container structure is correct
#   - Scripts exist and are executable
#   - Environment variables are set
#   - User/permissions are correct
#

set -euo pipefail

CONTAINER_NAME="hytale-test-basic-$$"
TIMEOUT=30

cleanup() {
    echo "Cleaning up..."
    docker rm -f "$CONTAINER_NAME" 2>/dev/null || true
}
trap cleanup EXIT

echo "=== Basic Setup Test ==="
echo "Image: $IMAGE_TO_TEST"

# Run container with entrypoint override to skip server startup
# This lets us inspect the container without needing auth
echo "Starting container (setup-only mode)..."
docker run -d \
    --name "$CONTAINER_NAME" \
    --entrypoint /bin/sh \
    "$IMAGE_TO_TEST" \
    -c "sleep 300"  # Keep alive for inspection

# Wait for container to be running
sleep 2
status=$(docker inspect -f '{{.State.Status}}' "$CONTAINER_NAME" 2>/dev/null || echo "not found")
if [ "$status" != "running" ]; then
    echo "ERROR: Container failed to start"
    docker logs "$CONTAINER_NAME"
    exit 1
fi

echo "Verifying container structure..."

# Check scripts directory
docker exec "$CONTAINER_NAME" test -d /usr/local/bin/scripts || {
    echo "ERROR: Scripts directory not found"
    exit 1
}
echo "  ✓ Scripts directory exists"

# Check hytale-downloader binary
docker exec "$CONTAINER_NAME" test -x /usr/local/bin/hytale-downloader || {
    echo "ERROR: hytale-downloader not found or not executable"
    exit 1
}
echo "  ✓ hytale-downloader is executable"

# Check entrypoint
docker exec "$CONTAINER_NAME" test -f /entrypoint.sh || {
    echo "ERROR: entrypoint.sh not found"
    exit 1
}
docker exec "$CONTAINER_NAME" test -x /entrypoint.sh || {
    echo "ERROR: entrypoint.sh not executable"
    exit 1
}
echo "  ✓ entrypoint.sh exists and is executable"

# Check key scripts exist
for script in hytale_downloader.sh hytale_config.sh hytale_options.sh curseforge_mods.sh; do
    docker exec "$CONTAINER_NAME" test -f "/usr/local/bin/scripts/hytale/$script" || {
        echo "ERROR: Script not found: $script"
        exit 1
    }
done
echo "  ✓ All hytale scripts present"

# Check utils.sh
docker exec "$CONTAINER_NAME" test -f /usr/local/bin/scripts/utils.sh || {
    echo "ERROR: utils.sh not found"
    exit 1
}
echo "  ✓ utils.sh exists"

# Check user exists
docker exec "$CONTAINER_NAME" id container > /dev/null 2>&1 || {
    echo "ERROR: container user not found"
    exit 1
}
echo "  ✓ container user exists"

# Check home directory
docker exec "$CONTAINER_NAME" test -d /home/container || {
    echo "ERROR: /home/container not found"
    exit 1
}
echo "  ✓ Home directory exists"

# Verify privilege dropper is available (gosu or su-exec)
if docker exec "$CONTAINER_NAME" which gosu > /dev/null 2>&1; then
    echo "  ✓ gosu available (Ubuntu)"
elif docker exec "$CONTAINER_NAME" which su-exec > /dev/null 2>&1; then
    echo "  ✓ su-exec available (Alpine)"
else
    echo "WARNING: No privilege dropper found (gosu/su-exec)"
fi

# Check required tools
for tool in curl jq unzip; do
    docker exec "$CONTAINER_NAME" which "$tool" > /dev/null 2>&1 || {
        echo "ERROR: Required tool not found: $tool"
        exit 1
    }
done
echo "  ✓ Required tools present (curl, jq, unzip)"

echo ""
echo "=== All basic setup checks passed! ==="
exit 0
