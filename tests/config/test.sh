#!/bin/bash
#
# Config Script Test (No Server JAR Required)
#
# Verifies:
#   - config.json is created with defaults
#   - Environment variables override config values
#   - Existing config values are preserved
#

set -euo pipefail

CONTAINER_NAME="hytale-test-config-$$"

cleanup() {
    echo "Cleaning up..."
    docker rm -f "$CONTAINER_NAME" 2>/dev/null || true
}
trap cleanup EXIT

echo "=== Config Script Test ==="
echo "Image: $IMAGE_TO_TEST"

# Start container with shell
echo "Starting container..."
docker run -d \
    --name "$CONTAINER_NAME" \
    --entrypoint /bin/sh \
    -e SCRIPTS_PATH=/usr/local/bin/scripts \
    -e BASE_DIR=/home/container \
    "$IMAGE_TO_TEST" \
    -c "sleep 300"

sleep 2

# Verify container is running
status=$(docker inspect -f '{{.State.Status}}' "$CONTAINER_NAME" 2>/dev/null || echo "not found")
if [ "$status" != "running" ]; then
    echo "ERROR: Container failed to start"
    exit 1
fi

echo ""
echo "--- Test 1: Default config creation ---"

docker exec "$CONTAINER_NAME" sh -c '
    . /usr/local/bin/scripts/utils.sh
    sh /usr/local/bin/scripts/hytale/hytale_config.sh
'

docker exec "$CONTAINER_NAME" test -f /home/container/config.json || { echo "FAIL: config.json not created"; exit 1; }
echo "  ✓ config.json created"

# Verify defaults
server_name=$(docker exec "$CONTAINER_NAME" jq -r '.ServerName' /home/container/config.json)
if [ "$server_name" != "Hytale Server" ]; then
    echo "FAIL: Default ServerName should be 'Hytale Server'"
    exit 1
fi
echo "  ✓ Default values correct"

echo ""
echo "--- Test 2: Environment variable overrides ---"

docker exec "$CONTAINER_NAME" sh -c '
    export HYTALE_SERVER_NAME="Test Server"
    export HYTALE_PASSWORD="secret123"
    export HYTALE_MAX_PLAYERS="50"
    . /usr/local/bin/scripts/utils.sh
    sh /usr/local/bin/scripts/hytale/hytale_config.sh
'

server_name=$(docker exec "$CONTAINER_NAME" jq -r '.ServerName' /home/container/config.json)
password=$(docker exec "$CONTAINER_NAME" jq -r '.Password' /home/container/config.json)
max_players=$(docker exec "$CONTAINER_NAME" jq -r '.MaxPlayers' /home/container/config.json)

if [ "$server_name" != "Test Server" ]; then
    echo "FAIL: ServerName should be 'Test Server', got '$server_name'"
    exit 1
fi
echo "  ✓ HYTALE_SERVER_NAME applied"

if [ "$password" != "secret123" ]; then
    echo "FAIL: Password should be 'secret123'"
    exit 1
fi
echo "  ✓ HYTALE_PASSWORD applied"

if [ "$max_players" != "50" ]; then
    echo "FAIL: MaxPlayers should be 50, got $max_players"
    exit 1
fi
echo "  ✓ HYTALE_MAX_PLAYERS applied"

echo ""
echo "--- Test 3: Existing values preserved when env not set ---"

# Run again without env vars - values should persist
docker exec "$CONTAINER_NAME" sh -c '
    . /usr/local/bin/scripts/utils.sh
    sh /usr/local/bin/scripts/hytale/hytale_config.sh
'

server_name=$(docker exec "$CONTAINER_NAME" jq -r '.ServerName' /home/container/config.json)
if [ "$server_name" != "Test Server" ]; then
    echo "FAIL: ServerName should still be 'Test Server', got '$server_name'"
    exit 1
fi
echo "  ✓ Existing ServerName preserved"

password=$(docker exec "$CONTAINER_NAME" jq -r '.Password' /home/container/config.json)
if [ "$password" != "secret123" ]; then
    echo "FAIL: Password should still be 'secret123'"
    exit 1
fi
echo "  ✓ Existing Password preserved"

echo ""
echo "--- Test 4: MOTD and GameMode ---"

docker exec "$CONTAINER_NAME" sh -c '
    export HYTALE_MOTD="Welcome to my server!"
    export HYTALE_GAMEMODE="Creative"
    . /usr/local/bin/scripts/utils.sh
    sh /usr/local/bin/scripts/hytale/hytale_config.sh
'

motd=$(docker exec "$CONTAINER_NAME" jq -r '.MOTD' /home/container/config.json)
gamemode=$(docker exec "$CONTAINER_NAME" jq -r '.Defaults.GameMode' /home/container/config.json)

if [ "$motd" != "Welcome to my server!" ]; then
    echo "FAIL: MOTD not set correctly"
    exit 1
fi
echo "  ✓ HYTALE_MOTD applied"

if [ "$gamemode" != "Creative" ]; then
    echo "FAIL: GameMode should be Creative, got $gamemode"
    exit 1
fi
echo "  ✓ HYTALE_GAMEMODE applied"

echo ""
echo "=== All config tests passed! ==="
exit 0
