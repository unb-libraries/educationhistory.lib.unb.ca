FROM unblibraries/drupal:alpine-nginx-php7-8.x-composer
MAINTAINER UNB Libraries <libsupport@unb.ca>

LABEL name="educationhistory.lib.unb.ca"
LABEL vcs-ref=""
LABEL vcs-url="https://github.com/unb-libraries/educationhistory.lib.unb.ca"

ARG COMPOSER_DEPLOY_DEV=no-dev

# Universal environment variables.
ENV DEPLOY_ENV prod
ENV DRUPAL_DEPLOY_CONFIGURATION TRUE
ENV DRUPAL_SITE_ID eduhist
ENV DRUPAL_SITE_URI educationhistory.lib.unb.ca
ENV DRUPAL_SITE_UUID f1de2d88-eedf-4115-af2b-d55cf0a30215
ENV DRUPAL_CONFIGURATION_EXPORT_SKIP devel

# Newrelic.
ENV NEWRELIC_PHP_VERSION 7.1.0.187
ENV NEWRELIC_PHP_ARCH musl

# Add Mail Sending
RUN apk --update add postfix && \
  rm -f /var/cache/apk/*
COPY package-conf/postfix/main.cf /etc/postfix/main.cf

# Add nginx and PHP conf.
COPY package-conf/nginx/app.conf /etc/nginx/conf.d/app.conf
COPY package-conf/php/app-php.ini /etc/php7/conf.d/zz_app.ini
COPY package-conf/php/app-php-fpm.conf /etc/php7/php-fpm.d/zz_app.conf

# Scripts.
COPY ./scripts/container /scripts

# Remove upstream build and replace it with ours.
RUN /scripts/deleteUpstreamTree.sh
COPY build/ ${TMP_DRUPAL_BUILD_DIR}

# Deploy the generalized profile and makefile into our specific one.
RUN /scripts/deployGeneralizedProfile.sh

# Build Drupal tree.
ENV DRUPAL_BUILD_TMPROOT ${TMP_DRUPAL_BUILD_DIR}/webroot
RUN /scripts/buildDrupalTree.sh

# Install Newrelic.
RUN /scripts/installNewRelic.sh

# Copy configuration.
COPY ./config-yml ${TMP_DRUPAL_BUILD_DIR}/config-yml

# Custom modules not tracked in github.
COPY ./custom/modules ${TMP_DRUPAL_BUILD_DIR}/custom_modules
COPY ./custom/themes ${TMP_DRUPAL_BUILD_DIR}/custom_themes

# Tests
COPY ./tests/behat.yml ${TMP_DRUPAL_BUILD_DIR}/behat.yml
COPY ./tests/features ${TMP_DRUPAL_BUILD_DIR}/features
