#!/usr/bin/env sh
# Setup environment variables.
NEWRELIC_PHP_BASE_FILE="newrelic-php5-${NEWRELIC_PHP_VERSION}-linux"
NEWRELIC_DOWNLOAD_FILE="${NEWRELIC_PHP_BASE_FILE}-musl.tar.gz"
NEWRELIC_DOWNLOAD_URI="http://download.newrelic.com/php_agent/release/${NEWRELIC_DOWNLOAD_FILE}"
NR_INSTALL_SILENT="true"

# Install Package.
mkdir -p /opt/newrelic
cd /opt/newrelic
wget ${NEWRELIC_DOWNLOAD_URI} -O /opt/newrelic/${NEWRELIC_DOWNLOAD_FILE}
tar -zxf ${NEWRELIC_DOWNLOAD_FILE}
cd /opt/newrelic/${NEWRELIC_PHP_BASE_FILE}-${NEWRELIC_PHP_ARCH}
sh newrelic-install install
