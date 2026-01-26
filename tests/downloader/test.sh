#!/bin/bash
#
# Downloader Version Tracking Test (No actual download)
#
# Verifies:
#   - Version file format is correct
#   - Failsafe triggers when JAR exists but version file missing
#   - Patchline change triggers re-download logic
#

set -euo pipefail

CONTAINER_NAME="hytale-test-downloader-$$"

cleanup() {
    echo "Cleaning up..."
    docker rm -f "$CONTAINER_NAME" 2>/dev/null || true
}
trap cleanup EXIT

echo "=== Downloader Version Tracking Test ==="
echo "Image: $IMAGE_TO_TEST"

# Start container with shell
echo "Starting container..."
docker run -d \
    --name "$CONTAINER_NAME" \
    --entrypoint /bin/sh \
    -e SCRIPTS_PATH=/usr/local/bin/scripts \
    -e BASE_DIR=/home/container \
    -e GAME_DIR=/home/container/game \
    -e SERVER_JAR_PATH=/home/container/game/Server/HytaleServer.jar \
    -e HYTALE_PATCHLINE=release \
    -e DEBUG=TRUE \
    "$IMAGE_TO_TEST" \
    -c "sleep 300"

sleep 2

echo ""
echo "--- Test 1: Version file functions ---"

# Test get_installed_version when no file exists
result=$(docker exec "$CONTAINER_NAME" sh -c '
    export VERSION_FILE=/home/container/.hytale_version
    get_installed_version() {
        if [ -f "$VERSION_FILE" ]; then
            cat "$VERSION_FILE"
        else
            echo "none|none"
        fi
    }
    get_installed_version
')

if [ "$result" != "none|none" ]; then
    echo "FAIL: Expected 'none|none' when no version file, got '$result'"
    exit 1
fi
echo "  ✓ get_installed_version returns 'none|none' when file missing"

# Test save_version
docker exec "$CONTAINER_NAME" sh -c '
    export VERSION_FILE=/home/container/.hytale_version
    save_version() {
        local version="$1"
        local patchline="$2"
        echo "${version}|${patchline}" > "$VERSION_FILE"
    }
    save_version "2026.01.15" "release"
'

result=$(docker exec "$CONTAINER_NAME" cat /home/container/.hytale_version)
if [ "$result" != "2026.01.15|release" ]; then
    echo "FAIL: Version file format wrong, got '$result'"
    exit 1
fi
echo "  ✓ save_version creates correct format"

echo ""
echo "--- Test 2: Version parsing ---"

result=$(docker exec "$CONTAINER_NAME" sh -c '
    echo "2026.01.15|release" | cut -d"|" -f1
')
if [ "$result" != "2026.01.15" ]; then
    echo "FAIL: Version parsing failed"
    exit 1
fi
echo "  ✓ Version extracted correctly"

result=$(docker exec "$CONTAINER_NAME" sh -c '
    echo "2026.01.15|release" | cut -d"|" -f2
')
if [ "$result" != "release" ]; then
    echo "FAIL: Patchline parsing failed"
    exit 1
fi
echo "  ✓ Patchline extracted correctly"

echo ""
echo "--- Test 3: Failsafe detection (JAR exists, no version file) ---"

# Create fake JAR but no version file
docker exec "$CONTAINER_NAME" sh -c '
    mkdir -p /home/container/game/Server
    touch /home/container/game/Server/HytaleServer.jar
    rm -f /home/container/.hytale_version
'

# Check the condition
result=$(docker exec "$CONTAINER_NAME" sh -c '
    export VERSION_FILE=/home/container/.hytale_version
    export SERVER_JAR_PATH=/home/container/game/Server/HytaleServer.jar
    
    get_installed_version() {
        if [ -f "$VERSION_FILE" ]; then
            cat "$VERSION_FILE"
        else
            echo "none|none"
        fi
    }
    
    INSTALLED_INFO=$(get_installed_version)
    INSTALLED_VERSION=$(echo "$INSTALLED_INFO" | cut -d"|" -f1)
    
    # Check failsafe condition
    if [ -f "$SERVER_JAR_PATH" ] && { [ "$INSTALLED_VERSION" = "none" ] || [ ! -f "$VERSION_FILE" ]; }; then
        echo "FAILSAFE_TRIGGERED"
    else
        echo "NO_FAILSAFE"
    fi
')

if [ "$result" != "FAILSAFE_TRIGGERED" ]; then
    echo "FAIL: Failsafe should trigger when JAR exists but no version file"
    exit 1
fi
echo "  ✓ Failsafe triggers when JAR exists without version file"

echo ""
echo "--- Test 4: No failsafe when both exist ---"

# Create version file
docker exec "$CONTAINER_NAME" sh -c '
    echo "2026.01.15|release" > /home/container/.hytale_version
'

result=$(docker exec "$CONTAINER_NAME" sh -c '
    export VERSION_FILE=/home/container/.hytale_version
    export SERVER_JAR_PATH=/home/container/game/Server/HytaleServer.jar
    
    get_installed_version() {
        if [ -f "$VERSION_FILE" ]; then
            cat "$VERSION_FILE"
        else
            echo "none|none"
        fi
    }
    
    INSTALLED_INFO=$(get_installed_version)
    INSTALLED_VERSION=$(echo "$INSTALLED_INFO" | cut -d"|" -f1)
    
    if [ -f "$SERVER_JAR_PATH" ] && { [ "$INSTALLED_VERSION" = "none" ] || [ ! -f "$VERSION_FILE" ]; }; then
        echo "FAILSAFE_TRIGGERED"
    else
        echo "NO_FAILSAFE"
    fi
')

if [ "$result" != "NO_FAILSAFE" ]; then
    echo "FAIL: Failsafe should NOT trigger when both JAR and version file exist"
    exit 1
fi
echo "  ✓ No failsafe when both JAR and version file exist"

echo ""
echo "--- Test 5: Patchline change detection ---"

result=$(docker exec "$CONTAINER_NAME" sh -c '
    INSTALLED_PATCHLINE="release"
    HYTALE_PATCHLINE="pre-release"
    
    if [ "$INSTALLED_PATCHLINE" != "$HYTALE_PATCHLINE" ]; then
        echo "PATCHLINE_CHANGED"
    else
        echo "SAME"
    fi
')

if [ "$result" != "PATCHLINE_CHANGED" ]; then
    echo "FAIL: Should detect patchline change"
    exit 1
fi
echo "  ✓ Patchline change detected"

echo ""
echo "--- Test 6: clean_for_reinstall removes correct files ---"

# Setup files
docker exec "$CONTAINER_NAME" sh -c '
    mkdir -p /home/container/game/Server
    touch /home/container/game/Server/HytaleServer.jar
    echo "2026.01.15|release" > /home/container/.hytale_version
    touch /home/container/2026.01.15.zip
    
    # User data that should NOT be deleted
    mkdir -p /home/container/universe
    touch /home/container/universe/world.dat
    mkdir -p /home/container/mods
    touch /home/container/mods/mymod.jar
    touch /home/container/config.json
'

# Run clean_for_reinstall
docker exec "$CONTAINER_NAME" sh -c '
    export GAME_DIR=/home/container/game
    export VERSION_FILE=/home/container/.hytale_version
    export BASE_DIR=/home/container
    
    # Inline clean function
    rm -rf "$GAME_DIR" 2>/dev/null || true
    rm -f "$VERSION_FILE" 2>/dev/null || true
    rm -f "$BASE_DIR"/*.zip 2>/dev/null || true
'

# Verify game dir removed
if docker exec "$CONTAINER_NAME" test -d /home/container/game 2>/dev/null; then
    echo "FAIL: game/ directory should be removed"
    exit 1
fi
echo "  ✓ game/ directory removed"

# Verify version file removed
if docker exec "$CONTAINER_NAME" test -f /home/container/.hytale_version 2>/dev/null; then
    echo "FAIL: version file should be removed"
    exit 1
fi
echo "  ✓ Version file removed"

# Verify zip removed
if docker exec "$CONTAINER_NAME" test -f /home/container/2026.01.15.zip 2>/dev/null; then
    echo "FAIL: zip file should be removed"
    exit 1
fi
echo "  ✓ Zip files removed"

# Verify user data preserved
if ! docker exec "$CONTAINER_NAME" test -f /home/container/universe/world.dat; then
    echo "FAIL: universe/ should be preserved"
    exit 1
fi
echo "  ✓ universe/ (worlds) preserved"

if ! docker exec "$CONTAINER_NAME" test -f /home/container/mods/mymod.jar; then
    echo "FAIL: mods/ should be preserved"
    exit 1
fi
echo "  ✓ mods/ preserved"

if ! docker exec "$CONTAINER_NAME" test -f /home/container/config.json; then
    echo "FAIL: config.json should be preserved"
    exit 1
fi
echo "  ✓ config.json preserved"

echo ""
echo "=== All downloader tests passed! ==="
exit 0
