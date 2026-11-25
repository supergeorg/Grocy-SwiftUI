# Grocy test server

Integration tests in `Grocy MobileTests/Integration/` run against a real Grocy server built from a local clone of [grocy/grocy](https://github.com/grocy/grocy). The server runs in Docker, so no PHP setup is needed on the Mac.

## Requirements

- Docker Desktop (running)
- A Grocy clone, by default at `../grocy` next to this repository (override with `GROCY_SOURCE_DIR`). The scripts are pinned to Grocy **4.7.1** (`GROCY_VERSION`, equal to `GrocyAPP.supportedVersions`): if there is no clone yet, `grocy-test-server.sh start` clones the `v4.7.1` tag, and a clone at another version is refused (set `GROCY_ALLOW_OTHER_VERSION=1` to test it anyway).

## Run the integration tests

```sh
TestServer/run-integration-tests.sh                     # first available iPhone simulator
TestServer/run-integration-tests.sh "platform=macOS"    # any xcodebuild destination
KEEP_SERVER=1 TestServer/run-integration-tests.sh       # leave the server running afterwards
```

The script builds the image (cached after the first run, which takes about 2–3 minutes), starts a server with an empty database, runs the integration suites, and stops the server again.

## Run them from Xcode

1. `TestServer/grocy-test-server.sh start`
2. In the "Grocy MobileTests" scheme, go to Test › Arguments › Environment Variables and add `GROCY_TEST_SERVER_URL` = `http://localhost:9290`
3. Run the tests. Without `GROCY_TEST_SERVER_URL`, the integration suites are skipped and the other unit tests run as usual.

## Run the UI tests

UI tests in `Grocy MobileUITests/` (`MDLocationUITests`, `MDMasterDataUITests`, sharing the `GrocyUITestCase` base class) use the same server. They create their own fixtures over the REST API, check the screens' design and accessibility rules, and attach screenshots to the test report, so the layout can be reviewed per platform.

```sh
TestServer/grocy-test-server.sh start
TEST_RUNNER_GROCY_TEST_SERVER_URL=http://localhost:9290 \
xcodebuild test -project "Grocy Mobile.xcodeproj" -scheme "Grocy MobileUITests" \
    -destination "platform=macOS" -only-testing "Grocy MobileUITests/MDLocationUITests" -only-testing "Grocy MobileUITests/MDMasterDataUITests"
```

Any iOS simulator works as a destination, too. The app is launched with `GROCY_UITEST_SERVER_URL` in its environment, which turns on `UITestConfiguration` (debug builds only): both SwiftData stores stay in memory and the app logs in without creating a server profile, so the data, login and iCloud profiles of the installed app are never touched. Without `GROCY_TEST_SERVER_URL`, the UI tests are skipped. On macOS, the first run asks to allow UI automation; the Mac must be unlocked while the tests run.

## HTTPS with a self-signed certificate

To test "Trust this certificate" (servers with a self-signed certificate), put an HTTPS proxy in front of the test server:

```sh
TestServer/grocy-test-server.sh start
TestServer/grocy-https-proxy.sh start      # prints the URL, the API key and the certificate's SHA-256 fingerprint
```

Then log in to `https://localhost:9443` in the app (a simulator on this Mac reaches it as `localhost`) with the API key `grocy-mobile-integration-tests`. The app should show the certificate with the fingerprint the script printed and offer to trust it.

- The certificate is created once in `TestServer/.certs/` (git-ignored) and reused, so a trusted fingerprint keeps working across restarts. Delete that folder and restart the proxy to get a new certificate, which tests what happens when a trusted certificate changes.
- `TestServer/grocy-https-proxy.sh fingerprint` prints the fingerprint again, `stop` stops the proxy. It runs nginx in Docker, and the certificate is made with OpenSSL in Docker, so nothing has to be installed on the Mac.
- `GROCY_TEST_HTTPS_PORT` changes the port (default `9443`, bound to 127.0.0.1 only).

## A large household for profiling

`seed-large-household.py` fills a fresh test server with a household big enough to profile the app:
1,000 products (two thirds in stock, some due soon or overdue, some below their minimum), about 1,300 stock
entries, shopping lists with 150 items, 100 recipes with their ingredients, chores, tasks and batteries.
It only needs Python 3.

```sh
TestServer/grocy-test-server.sh start
TestServer/seed-large-household.py              # --products 5000 for a bigger one
```

Then log in to `http://localhost:9290` with the API key `grocy-mobile-integration-tests`. Every
`grocy-test-server.sh start` begins with an empty database again.

## Server control

```sh
TestServer/grocy-test-server.sh start|stop|restart|status|logs
```

| Variable             | Default                          |
|----------------------|----------------------------------|
| `GROCY_SOURCE_DIR`   | `../grocy`                       |
| `GROCY_VERSION`      | `4.7.1`                          |
| `GROCY_TEST_PORT`    | `9290` (bound to 127.0.0.1 only) |
| `GROCY_TEST_API_KEY` | `grocy-mobile-integration-tests` |

On every start, the container creates a fresh database, runs Grocy's migrations, and seeds the API key for the default admin user (see `entrypoint.sh`). Grocy runs in production mode with authentication enabled, so requests without a valid API key are rejected, as they are on a real server.
