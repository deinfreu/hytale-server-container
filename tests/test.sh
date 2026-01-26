#!/bin/bash
#
# Hytale Server Container Test Runner
#
# These are SETUP-ONLY tests that verify the container structure and scripts
# WITHOUT requiring OAuth authentication or server download.
#
# Tests run quickly by:
#   - Overriding entrypoint to skip server startup
#   - Running scripts directly in the container
#   - Not waiting for hytale-downloader auth
#
# Usage:
#   ./tests/test.sh                    # Run all tests
#   IMAGE_TO_TEST=my-image ./test.sh   # Test specific image
#

set -euo pipefail
IFS=$'\n\t'

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Go to script root directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

# Default image to test (can be overridden by environment)
export IMAGE_TO_TEST="${IMAGE_TO_TEST:-shotah/hytale-server:test}"
export VARIANT="${VARIANT:-alpine}"

echo "========================================"
echo "Hytale Server Container Tests"
echo "========================================"
echo "Image: $IMAGE_TO_TEST"
echo "Variant: $VARIANT"
echo ""

# Find all test.sh files in subdirectories
readarray -t folders < <(find . -maxdepth 2 -mindepth 2 -name test.sh -printf '%h\n' | sort)

if [ ${#folders[@]} -eq 0 ]; then
    echo -e "${YELLOW}No tests found!${NC}"
    exit 0
fi

echo "Found ${#folders[@]} test(s):"
for folder in "${folders[@]}"; do
    echo "  - ${folder#./}"
done
echo ""

# Track results
PASSED=0
FAILED=0
FAILED_TESTS=""

# Run each test
for folder in "${folders[@]}"; do
    test_name="${folder#./}"
    echo "----------------------------------------"
    echo -e "Running: ${YELLOW}${test_name}${NC}"
    echo "----------------------------------------"
    
    cd "$folder"
    
    if bash ./test.sh; then
        echo -e "${GREEN}✓ PASSED${NC}: ${test_name}"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}✗ FAILED${NC}: ${test_name}"
        FAILED=$((FAILED + 1))
        FAILED_TESTS="${FAILED_TESTS}\n  - ${test_name}"
    fi
    
    cd "$SCRIPT_DIR"
    echo ""
done

# Summary
echo "========================================"
echo "Test Results"
echo "========================================"
echo -e "${GREEN}Passed${NC}: $PASSED"
echo -e "${RED}Failed${NC}: $FAILED"

if [ $FAILED -gt 0 ]; then
    echo -e "\nFailed tests:${FAILED_TESTS}"
    exit 1
fi

echo ""
echo -e "${GREEN}All tests passed!${NC}"
exit 0
