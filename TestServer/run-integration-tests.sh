#!/bin/bash
# Starts a fresh Grocy test server, runs the Grocy MobileTests target (unit + integration tests)
# against it and stops it again. New integration suites are picked up automatically.
#
# Usage: TestServer/run-integration-tests.sh [xcodebuild destination]
#   default destination: the first available iPhone simulator
#   e.g. TestServer/run-integration-tests.sh "platform=macOS"
#
# Set KEEP_SERVER=1 to leave the server running afterwards.
# Accepts the same environment variables as grocy-test-server.sh.
set -euo pipefail

HARNESS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$HARNESS_DIR")"

export GROCY_TEST_PORT="${GROCY_TEST_PORT:-9290}"
export GROCY_TEST_API_KEY="${GROCY_TEST_API_KEY:-grocy-mobile-integration-tests}"

DESTINATION="${1:-}"
if [[ -z "$DESTINATION" ]]; then
    SIMULATOR_ID=$(xcrun simctl list devices available | grep -m1 -E '^\s+iPhone' | grep -oE '[0-9A-F-]{36}')
    DESTINATION="platform=iOS Simulator,id=$SIMULATOR_ID"
fi

"$HARNESS_DIR/grocy-test-server.sh" start
if [[ "${KEEP_SERVER:-0}" != "1" ]]; then
    trap '"$HARNESS_DIR/grocy-test-server.sh" stop' EXIT
fi

# xcodebuild forwards TEST_RUNNER_-prefixed variables (without the prefix) to the test process.
TEST_RUNNER_GROCY_TEST_SERVER_URL="http://localhost:${GROCY_TEST_PORT}" \
TEST_RUNNER_GROCY_TEST_API_KEY="$GROCY_TEST_API_KEY" \
xcodebuild test \
    -project "$REPO_DIR/Grocy Mobile.xcodeproj" \
    -scheme "Grocy MobileTests" \
    -destination "$DESTINATION" \
    -only-testing "Grocy MobileTests"
