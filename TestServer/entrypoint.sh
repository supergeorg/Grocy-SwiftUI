#!/bin/sh
# Starts a pristine Grocy instance with a known API key.
#
# 1. Creates an empty data directory with the default config.
# 2. Runs the database migrations once (Grocy migrates on `GET /`), using a
#    short-lived server with authentication disabled.
# 3. Inserts the API key from GROCY_TEST_API_KEY for the default admin user.
# 4. Serves Grocy with normal authentication on port 80.
set -eu

: "${GROCY_TEST_API_KEY:?GROCY_TEST_API_KEY must be set}"
DATA="${GROCY_DATAPATH:-/grocy-data}"

rm -rf "$DATA"
mkdir -p "$DATA/viewcache"
cp /grocy/config-dist.php "$DATA/config.php"

cd /grocy

GROCY_DISABLE_AUTH=true php -S 127.0.0.1:8080 -t public public/index.php >/tmp/grocy-migrate.log 2>&1 &
MIGRATE_PID=$!

php -r '
    for ($i = 0; $i < 60; $i++) {
        if (@file_get_contents("http://127.0.0.1:8080/") !== false) { exit(0); }
        usleep(500000);
    }
    fwrite(STDERR, "Grocy did not finish migrating in time\n");
    exit(1);
' || { cat /tmp/grocy-migrate.log; exit 1; }

kill "$MIGRATE_PID"
wait "$MIGRATE_PID" 2>/dev/null || true

php -r '
    $db = new PDO("sqlite:" . getenv("GROCY_DATAPATH") . "/grocy.db");
    $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $userId = $db->query("SELECT MIN(id) FROM users")->fetchColumn();
    if ($userId === false || $userId === null) { fwrite(STDERR, "No Grocy user found\n"); exit(1); }
    // Same values as Grocy'\''s ApiKeyService::CreateApiKey (a NULL expiry is treated as expired).
    $db->prepare("INSERT INTO api_keys (api_key, user_id, expires, key_type, description) VALUES (?, ?, \"2999-12-31 23:59:59\", \"default\", \"Grocy Mobile integration tests\")")
       ->execute([getenv("GROCY_TEST_API_KEY"), $userId]);
'

VERSION=$(php -r 'echo json_decode(file_get_contents("/grocy/version.json"))->Version;')
echo "Grocy $VERSION test server ready"

exec php -S 0.0.0.0:80 -t public public/index.php
