#!/bin/bash
# Serves the Grocy test server over HTTPS with a self-signed certificate, for testing
# "Trust this certificate" (self-signed server certificates, #195).
#
# Usage: TestServer/grocy-https-proxy.sh start|stop|status|fingerprint
#
# Start the test server first (TestServer/grocy-test-server.sh start). This script puts an nginx
# container in front of it that terminates TLS with a self-signed certificate.
#
# Environment:
#   GROCY_TEST_PORT        Port of the Grocy test server  (default: 9290)
#   GROCY_TEST_HTTPS_PORT  HTTPS port on this Mac         (default: 9443, bound to 127.0.0.1 only)
#   GROCY_TEST_API_KEY     API key of the test server     (default: grocy-mobile-integration-tests)
#   GROCY_TEST_CERT_DIR    Where the certificate is kept  (default: TestServer/.certs, git-ignored)
#
# The certificate is created once and reused, so its fingerprint stays the same across restarts and a
# trusted fingerprint in the app keeps working. Delete the certificate folder to get a new one, which
# lets you test what the app does when a trusted certificate changes.
set -euo pipefail

HARNESS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

GROCY_TEST_PORT="${GROCY_TEST_PORT:-9290}"
GROCY_TEST_HTTPS_PORT="${GROCY_TEST_HTTPS_PORT:-9443}"
GROCY_TEST_API_KEY="${GROCY_TEST_API_KEY:-grocy-mobile-integration-tests}"
CERT_DIR="${GROCY_TEST_CERT_DIR:-$HARNESS_DIR/.certs}"

CONTAINER="grocy-mobile-test-https"
NGINX_IMAGE="nginx:1.27-alpine"
OPENSSL_IMAGE="alpine:3.20"
HTTPS_URL="https://localhost:${GROCY_TEST_HTTPS_PORT}"

require_docker() {
    if ! docker info >/dev/null 2>&1; then
        echo "error: Docker is not running." >&2
        exit 1
    fi
}

# Runs openssl in a container, so the result doesn't depend on the Mac's LibreSSL version.
openssl_in_docker() {
    docker run --rm -v "$CERT_DIR":/certs "$OPENSSL_IMAGE" sh -c "apk add --no-cache --quiet openssl >/dev/null && $1"
}

make_certificate() {
    mkdir -p "$CERT_DIR"
    if [[ -f "$CERT_DIR/cert.pem" && -f "$CERT_DIR/key.pem" ]]; then
        return
    fi
    echo "Creating a self-signed certificate in $CERT_DIR"
    # Within Apple's limits for TLS server certificates (RSA 2048, SHA-256, at most 825 days, SAN, serverAuth),
    # so it also works when it's installed and trusted as a profile instead of trusted in the app.
    openssl_in_docker 'openssl req -x509 -newkey rsa:2048 -sha256 -nodes -days 825 \
        -subj "/CN=Grocy Mobile Test Server" \
        -addext "subjectAltName=DNS:localhost,IP:127.0.0.1" \
        -addext "extendedKeyUsage=serverAuth" \
        -addext "keyUsage=digitalSignature,keyEncipherment" \
        -keyout /certs/key.pem -out /certs/cert.pem 2>/dev/null'
}

write_nginx_config() {
    cat >"$CERT_DIR/nginx.conf" <<CONF
events {}
http {
    server {
        listen 443 ssl;
        ssl_certificate /certs/cert.pem;
        ssl_certificate_key /certs/key.pem;
        client_max_body_size 50m;
        location / {
            proxy_pass http://host.docker.internal:${GROCY_TEST_PORT};
            proxy_set_header Host localhost:${GROCY_TEST_HTTPS_PORT};
            proxy_set_header X-Forwarded-Proto https;
        }
    }
}
CONF
}

fingerprint() {
    openssl_in_docker 'openssl x509 -noout -fingerprint -sha256 -in /certs/cert.pem' | sed 's/^.*=//'
}

start() {
    require_docker
    make_certificate
    write_nginx_config

    docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
    docker run -d --rm \
        --name "$CONTAINER" \
        --add-host=host.docker.internal:host-gateway \
        -p "127.0.0.1:${GROCY_TEST_HTTPS_PORT}:443" \
        -v "$CERT_DIR":/certs:ro \
        -v "$CERT_DIR/nginx.conf":/etc/nginx/nginx.conf:ro \
        "$NGINX_IMAGE" >/dev/null

    echo -n "Waiting for $HTTPS_URL "
    for _ in $(seq 1 30); do
        # -k: the certificate is self-signed, that's the point.
        if curl -kfsS -H "GROCY-API-KEY: $GROCY_TEST_API_KEY" "$HTTPS_URL/api/system/info" >/dev/null 2>&1; then
            echo
            echo "Grocy is available at $HTTPS_URL (self-signed certificate)"
            echo "API key:     $GROCY_TEST_API_KEY"
            echo "Fingerprint: $(fingerprint)"
            echo "The app should show this fingerprint when you log in to $HTTPS_URL."
            return 0
        fi
        echo -n "."
        sleep 1
    done
    echo
    echo "error: $HTTPS_URL didn't answer. Is the test server running (TestServer/grocy-test-server.sh start)?" >&2
    docker logs "$CONTAINER" >&2 || true
    exit 1
}

stop() {
    require_docker
    docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
    echo "Stopped $CONTAINER"
}

status() {
    if curl -kfsS -H "GROCY-API-KEY: $GROCY_TEST_API_KEY" "$HTTPS_URL/api/system/info" 2>/dev/null; then
        echo
    else
        echo "Not running on $HTTPS_URL"
        exit 1
    fi
}

case "${1:-}" in
    start) start ;;
    stop) stop ;;
    status) status ;;
    fingerprint) require_docker; fingerprint ;;
    *)
        echo "Usage: $0 start|stop|status|fingerprint" >&2
        exit 64
        ;;
esac
