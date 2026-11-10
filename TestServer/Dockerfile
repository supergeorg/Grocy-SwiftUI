# Grocy test server for the Grocy Mobile integration tests.
#
# Build context: a local clone of https://github.com/grocy/grocy
# Named context "harness": this directory (provides entrypoint.sh)
#
#   docker build -f TestServer/Dockerfile --build-context harness=TestServer ../grocy
#
# Use TestServer/grocy-test-server.sh instead of calling this directly.

FROM php:8.5-cli

COPY --from=mlocati/php-extension-installer:2 /usr/bin/install-php-extensions /usr/local/bin/
COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer

RUN apt-get update \
    && apt-get install -y --no-install-recommends git unzip \
    && rm -rf /var/lib/apt/lists/* \
    && install-php-extensions gd intl

WORKDIR /grocy
COPY . .

# Never ship local state from the clone (data, embedded mode marker, installed packages).
RUN rm -rf data/config.php data/*.db data/viewcache embedded.txt packages \
    && composer install --no-dev --no-interaction --no-progress --prefer-dist

COPY --from=harness --chmod=755 entrypoint.sh /usr/local/bin/grocy-test-entrypoint

ENV GROCY_DATAPATH=/grocy-data \
    PHP_CLI_SERVER_WORKERS=4

EXPOSE 80
ENTRYPOINT ["grocy-test-entrypoint"]
