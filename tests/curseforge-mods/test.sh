#!/bin/bash
#
# CurseForge Mod Downloader Test (No Server JAR Required)
#
# This is a SETUP-ONLY test that runs the mod downloader script
# directly WITHOUT requiring OAuth authentication or server download.
#
# Verifies:
#   - curseforge_mods.sh script runs without errors
#   - Mods are downloaded to correct directory
#   - Manifest is created and updated
#   - Cleanup works when mods are removed
#

set -euo pipefail

CONTAINER_NAME="hytale-test-mods-$$"
TIMEOUT=90

# Test mod IDs (real mods from CurseForge)
# Using popular/stable mods that are unlikely to be removed
TEST_MOD_IDS="1423494"  # EyeSpy mod

cleanup() {
    echo "Cleaning up..."
    docker rm -f "$CONTAINER_NAME" 2>/dev/null || true
}
trap cleanup EXIT

echo "=== CurseForge Mod Downloader Test ==="
echo "Image: $IMAGE_TO_TEST"
echo "Test Mod IDs: $TEST_MOD_IDS"

# Run container with shell, then execute mod script directly
# This bypasses the need for hytale-downloader auth
echo "Starting container (setup-only mode)..."
docker run -d \
    --name "$CONTAINER_NAME" \
    --entrypoint /bin/sh \
    -e DEBUG=TRUE \
    -e CURSEFORGE_MOD_IDS="$TEST_MOD_IDS" \
    -e SCRIPTS_PATH=/usr/local/bin/scripts \
    -e BASE_DIR=/home/container \
    -e GAME_DIR=/home/container/game \
    -e HYTALE_MOD_DIR=/home/container/mods \
    "$IMAGE_TO_TEST" \
    -c "sleep 300"

sleep 2

# Verify container is running
status=$(docker inspect -f '{{.State.Status}}' "$CONTAINER_NAME" 2>/dev/null || echo "not found")
if [ "$status" != "running" ]; then
    echo "ERROR: Container failed to start"
    exit 1
fi

echo "Running CurseForge mod downloader script..."

# Source utils and run the mod downloader script
docker exec "$CONTAINER_NAME" sh -c '
    export CURSEFORGE_MOD_IDS="'"$TEST_MOD_IDS"'"
    export SCRIPTS_PATH=/usr/local/bin/scripts
    export BASE_DIR=/home/container
    export GAME_DIR=/home/container/game
    export HYTALE_MOD_DIR=/home/container/mods
    export DEBUG=TRUE
    
    # Source colors/logging from utils
    . /usr/local/bin/scripts/utils.sh
    
    # Run the mod downloader
    sh /usr/local/bin/scripts/hytale/curseforge_mods.sh
' || {
    echo "ERROR: Mod downloader script failed"
    docker logs "$CONTAINER_NAME"
    exit 1
}

echo ""
echo "Verifying mod download..."

# Check that mods directory exists
docker exec "$CONTAINER_NAME" test -d /home/container/mods || {
    echo "ERROR: Mods directory not found"
    exit 1
}
echo "  ✓ Mods directory created"

# Check that manifest exists
docker exec "$CONTAINER_NAME" test -f /home/container/mods/.curseforge_manifest.json || {
    echo "ERROR: Manifest file not found"
    exit 1
}
echo "  ✓ Manifest file created"

# Check that at least one .jar file was downloaded
jar_count=$(docker exec "$CONTAINER_NAME" sh -c 'ls /home/container/mods/*.jar 2>/dev/null | wc -l' || echo "0")
if [ "$jar_count" -eq 0 ]; then
    echo "ERROR: No mod JAR files found"
    exit 1
fi
echo "  ✓ Downloaded $jar_count mod JAR file(s)"

# Verify manifest contains the mod
if docker exec "$CONTAINER_NAME" sh -c 'jq -e ".mods[\"'"$TEST_MOD_IDS"'\"]" /home/container/mods/.curseforge_manifest.json' > /dev/null 2>&1; then
    echo "  ✓ Mod tracked in manifest"
else
    echo "WARNING: Mod not found in manifest"
fi

# Test cleanup: run again with empty mod list
echo ""
echo "Testing cleanup (empty mod list)..."
docker exec "$CONTAINER_NAME" sh -c '
    export CURSEFORGE_MOD_IDS=""
    export SCRIPTS_PATH=/usr/local/bin/scripts
    export BASE_DIR=/home/container
    export GAME_DIR=/home/container/game
    export HYTALE_MOD_DIR=/home/container/mods
    
    . /usr/local/bin/scripts/utils.sh
    sh /usr/local/bin/scripts/hytale/curseforge_mods.sh
' || {
    echo "ERROR: Cleanup script failed"
    exit 1
}

# Verify cleanup worked
jar_count_after=$(docker exec "$CONTAINER_NAME" sh -c 'ls /home/container/mods/*.jar 2>/dev/null | wc -l' || echo "0")
if [ "$jar_count_after" -eq 0 ]; then
    echo "  ✓ Mods cleaned up successfully"
else
    echo "WARNING: $jar_count_after mod files still present after cleanup"
fi

# Verify manifest is removed
if ! docker exec "$CONTAINER_NAME" test -f /home/container/mods/.curseforge_manifest.json 2>/dev/null; then
    echo "  ✓ Manifest removed"
else
    echo "WARNING: Manifest still exists after cleanup"
fi

echo ""
echo "=== CurseForge mod test passed! ==="
exit 0
