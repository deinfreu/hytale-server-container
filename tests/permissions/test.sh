#!/bin/bash
#
# Permissions Script Test (No Server JAR Required)
#
# Verifies:
#   - whitelist.json, permissions.json, bans.json are created
#   - HYTALE_WHITELIST_ENABLED works
#   - HYTALE_OPS adds operators
#   - HYTALE_WHITELIST adds players
#   - Existing values are preserved (non-destructive)
#

set -euo pipefail

CONTAINER_NAME="hytale-test-permissions-$$"
TIMEOUT=60

TEST_UUID_1="11111111-1111-1111-1111-111111111111"
TEST_UUID_2="22222222-2222-2222-2222-222222222222"
EXISTING_UUID="99999999-9999-9999-9999-999999999999"

cleanup() {
    echo "Cleaning up..."
    docker rm -f "$CONTAINER_NAME" 2>/dev/null || true
}
trap cleanup EXIT

echo "=== Permissions Script Test ==="
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
echo "--- Test 1: Default file creation ---"

docker exec "$CONTAINER_NAME" sh -c '
    . /usr/local/bin/scripts/utils.sh
    sh /usr/local/bin/scripts/hytale/hytale_permissions.sh
'

# Check files exist
docker exec "$CONTAINER_NAME" test -f /home/container/whitelist.json || { echo "FAIL: whitelist.json not created"; exit 1; }
docker exec "$CONTAINER_NAME" test -f /home/container/permissions.json || { echo "FAIL: permissions.json not created"; exit 1; }
docker exec "$CONTAINER_NAME" test -f /home/container/bans.json || { echo "FAIL: bans.json not created"; exit 1; }
echo "  ✓ All default files created"

# Verify default content
whitelist_enabled=$(docker exec "$CONTAINER_NAME" jq -r '.enabled' /home/container/whitelist.json)
if [ "$whitelist_enabled" != "false" ]; then
    echo "FAIL: whitelist should be disabled by default"
    exit 1
fi
echo "  ✓ Whitelist disabled by default"

echo ""
echo "--- Test 2: HYTALE_WHITELIST_ENABLED ---"

docker exec "$CONTAINER_NAME" sh -c '
    export HYTALE_WHITELIST_ENABLED=true
    . /usr/local/bin/scripts/utils.sh
    sh /usr/local/bin/scripts/hytale/hytale_permissions.sh
'

whitelist_enabled=$(docker exec "$CONTAINER_NAME" jq -r '.enabled' /home/container/whitelist.json)
if [ "$whitelist_enabled" != "true" ]; then
    echo "FAIL: whitelist should be enabled"
    exit 1
fi
echo "  ✓ Whitelist enabled via env var"

echo ""
echo "--- Test 3: HYTALE_OPS adds operators ---"

docker exec "$CONTAINER_NAME" sh -c '
    export HYTALE_OPS="'"$TEST_UUID_1"','"$TEST_UUID_2"'"
    . /usr/local/bin/scripts/utils.sh
    sh /usr/local/bin/scripts/hytale/hytale_permissions.sh
'

# Check both UUIDs are OPs
op1=$(docker exec "$CONTAINER_NAME" jq -r ".users[\"$TEST_UUID_1\"].groups | index(\"OP\")" /home/container/permissions.json)
op2=$(docker exec "$CONTAINER_NAME" jq -r ".users[\"$TEST_UUID_2\"].groups | index(\"OP\")" /home/container/permissions.json)

if [ "$op1" = "null" ]; then
    echo "FAIL: UUID 1 should be OP"
    exit 1
fi
if [ "$op2" = "null" ]; then
    echo "FAIL: UUID 2 should be OP"
    exit 1
fi
echo "  ✓ Both UUIDs added as operators"

echo ""
echo "--- Test 4: HYTALE_WHITELIST adds players ---"

docker exec "$CONTAINER_NAME" sh -c '
    export HYTALE_WHITELIST="'"$TEST_UUID_1"','"$TEST_UUID_2"'"
    . /usr/local/bin/scripts/utils.sh
    sh /usr/local/bin/scripts/hytale/hytale_permissions.sh
'

wl1=$(docker exec "$CONTAINER_NAME" jq -r ".list | index(\"$TEST_UUID_1\")" /home/container/whitelist.json)
wl2=$(docker exec "$CONTAINER_NAME" jq -r ".list | index(\"$TEST_UUID_2\")" /home/container/whitelist.json)

if [ "$wl1" = "null" ]; then
    echo "FAIL: UUID 1 should be whitelisted"
    exit 1
fi
if [ "$wl2" = "null" ]; then
    echo "FAIL: UUID 2 should be whitelisted"
    exit 1
fi
echo "  ✓ Both UUIDs added to whitelist"

echo ""
echo "--- Test 5: Existing values preserved ---"

# Add an existing user manually
docker exec "$CONTAINER_NAME" sh -c '
    jq ".users[\"'"$EXISTING_UUID"'\"] = {\"groups\": [\"Builder\"]}" /home/container/permissions.json > /tmp/p.json
    mv /tmp/p.json /home/container/permissions.json
'

# Run script again with different OPs
docker exec "$CONTAINER_NAME" sh -c '
    export HYTALE_OPS="'"$TEST_UUID_1"'"
    . /usr/local/bin/scripts/utils.sh
    sh /usr/local/bin/scripts/hytale/hytale_permissions.sh
'

# Check existing user still has their group
existing_groups=$(docker exec "$CONTAINER_NAME" jq -r ".users[\"$EXISTING_UUID\"].groups" /home/container/permissions.json)
if ! echo "$existing_groups" | grep -q "Builder"; then
    echo "FAIL: Existing user's Builder group was removed"
    exit 1
fi
echo "  ✓ Existing user groups preserved"

# Check previous OPs still exist
op2_still=$(docker exec "$CONTAINER_NAME" jq -r ".users[\"$TEST_UUID_2\"].groups | index(\"OP\")" /home/container/permissions.json)
if [ "$op2_still" = "null" ]; then
    echo "FAIL: Previous OP should still exist"
    exit 1
fi
echo "  ✓ Previous operators preserved"

echo ""
echo "--- Test 6: No duplicates on re-run ---"

# Run again with same values
docker exec "$CONTAINER_NAME" sh -c '
    export HYTALE_OPS="'"$TEST_UUID_1"'"
    export HYTALE_WHITELIST="'"$TEST_UUID_1"'"
    . /usr/local/bin/scripts/utils.sh
    sh /usr/local/bin/scripts/hytale/hytale_permissions.sh
'

# Check no duplicate OPs
op_count=$(docker exec "$CONTAINER_NAME" jq -r ".users[\"$TEST_UUID_1\"].groups | map(select(. == \"OP\")) | length" /home/container/permissions.json)
if [ "$op_count" != "1" ]; then
    echo "FAIL: Should have exactly 1 OP entry, got $op_count"
    exit 1
fi
echo "  ✓ No duplicate OP entries"

# Check no duplicate whitelist entries
wl_count=$(docker exec "$CONTAINER_NAME" jq -r ".list | map(select(. == \"$TEST_UUID_1\")) | length" /home/container/whitelist.json)
if [ "$wl_count" != "1" ]; then
    echo "FAIL: Should have exactly 1 whitelist entry, got $wl_count"
    exit 1
fi
echo "  ✓ No duplicate whitelist entries"

echo ""
echo "=== All permissions tests passed! ==="
exit 0
