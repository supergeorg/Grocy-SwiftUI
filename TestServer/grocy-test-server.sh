#!/bin/bash
# Manages a throwaway Grocy server, built from a local clone of
# https://github.com/grocy/grocy, for the Grocy Mobile integration tests.
#
# Usage: TestServer/grocy-test-server.sh start|stop|restart|status|logs
#
# Environment:
#   GROCY_SOURCE_DIR    Grocy clone to build from   (default: ../grocy next to this repo)
#   GROCY_TEST_PORT     Host port                    (default: 9290)
#   GROCY_TEST_API_KEY  API key seeded into the DB   (default: grocy-mobile-integration-tests)
#
# Every start creates a fresh, empty database.
set -euo pipefail

HARNESS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$HARNESS_DIR")"

GROCY_SOURCE_DIR="${GROCY_SOURCE_DIR:-$(dirname "$REPO_DIR")/grocy}"
GROCY_TEST_PORT="${GROCY_TEST_PORT:-9290}"
GROCY_TEST_API_KEY="${GROCY_TEST_API_KEY:-grocy-mobile-integration-tests}"

IMAGE="grocy-mobile-test-server"
CONTAINER="grocy-mobile-test-server"
BASE_URL="http://localhost:${GROCY_TEST_PORT}/api"

require_docker() {
    if ! docker info >/dev/null 2>&1; then
        echo "error: Docker is not running." >&2
        exit 1
    fi
}

start() {
    require_docker
    if [[ ! -f "$GROCY_SOURCE_DIR/version.json" ]]; then
        echo "error: no Grocy clone at $GROCY_SOURCE_DIR (set GROCY_SOURCE_DIR)." >&2
        exit 1
    fi

    echo "Building $IMAGE from $GROCY_SOURCE_DIR ($(git -C "$GROCY_SOURCE_DIR" log -1 --format='%h %s' 2>/dev/null || echo 'unknown revision'))"
    docker build --quiet \
        -f "$HARNESS_DIR/Dockerfile" \
        --build-context harness="$HARNESS_DIR" \
        -t "$IMAGE" \
        "$GROCY_SOURCE_DIR" >/dev/null

    docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
    docker run -d --rm \
        --name "$CONTAINER" \
        -p "127.0.0.1:${GROCY_TEST_PORT}:80" \
        -e GROCY_TEST_API_KEY="$GROCY_TEST_API_KEY" \
        "$IMAGE" >/dev/null

    echo -n "Waiting for Grocy on $BASE_URL "
    for _ in $(seq 1 90); do
        if curl -fsS -H "GROCY-API-KEY: $GROCY_TEST_API_KEY" "$BASE_URL/system/info" >/dev/null 2>&1; then
            echo
            curl -fsS -H "GROCY-API-KEY: $GROCY_TEST_API_KEY" "$BASE_URL/system/info"
            echo
            echo "GROCY_TEST_SERVER_URL=http://localhost:${GROCY_TEST_PORT}"
            echo "GROCY_TEST_API_KEY=$GROCY_TEST_API_KEY"
            return 0
        fi
        if ! docker ps -q -f name="^${CONTAINER}$" | grep -q .; then
            echo
            echo "error: container exited during startup." >&2
            exit 1
        fi
        echo -n "."
        sleep 1
    done
    echo
    echo "error: Grocy did not become ready. Container logs:" >&2
    docker logs "$CONTAINER" >&2 || true
    exit 1
}

stop() {
    require_docker
    docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
    echo "Stopped $CONTAINER"
}

status() {
    if curl -fsS -H "GROCY-API-KEY: $GROCY_TEST_API_KEY" "$BASE_URL/system/info" 2>/dev/null; then
        echo
    else
        echo "Not running on $BASE_URL"
        exit 1
    fi
}

case "${1:-}" in
    start) start ;;
    stop) stop ;;
    restart) stop; start ;;
    status) status ;;
    logs) docker logs -f "$CONTAINER" ;;
    *)
        echo "Usage: $0 start|stop|restart|status|logs" >&2
        exit 64
        ;;
esac
