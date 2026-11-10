# Grocy test server

Integration tests in `Grocy MobileTests/Integration/` run against a real Grocy server built from a local clone of [grocy/grocy](https://github.com/grocy/grocy). The server runs in Docker, so no PHP setup is needed on the Mac.

## Requirements

- Docker Desktop (running)
- A Grocy clone, by default at `../grocy` next to this repository (override with `GROCY_SOURCE_DIR`). Check out a version listed in `GrocyAPP.supportedVersions`.

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

## Server control

```sh
TestServer/grocy-test-server.sh start|stop|restart|status|logs
```

| Variable             | Default                          |
|----------------------|----------------------------------|
| `GROCY_SOURCE_DIR`   | `../grocy`                       |
| `GROCY_TEST_PORT`    | `9290` (bound to 127.0.0.1 only) |
| `GROCY_TEST_API_KEY` | `grocy-mobile-integration-tests` |

On every start, the container creates a fresh database, runs Grocy's migrations, and seeds the API key for the default admin user (see `entrypoint.sh`). Grocy runs in production mode with authentication enabled, so requests without a valid API key are rejected, as they are on a real server.
