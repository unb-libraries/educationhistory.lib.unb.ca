FROM ghcr.io/unb-libraries/drupal:11.x-1.x-unblib

# Install additional OS packages.
ENV ADDITIONAL_OS_PACKAGES="postfix php${PHP_VERSION}-ldap php${PHP_VERSION}-xmlreader php${PHP_VERSION}-zip php${PHP_VERSION}-pecl-redis"
ENV DRUPAL_SITE_ID="eduhist"
ENV DRUPAL_SITE_URI="educationhistory.lib.unb.ca"
ENV DRUPAL_SITE_UUID="f1de2d88-eedf-4115-af2b-d55cf0a30215"

# Build application.
COPY ./build/ /build/
RUN ${RSYNC_MOVE} /build/scripts/container/ /scripts/ && \
  /scripts/addOsPackages.sh && \
  /scripts/initOpenLdap.sh && \
  /scripts/setupStandardConf.sh && \
  /scripts/build.sh

# Deploy configuration.
COPY ./configuration ${DRUPAL_CONFIGURATION_DIR}
RUN /scripts/pre-init.d/72_secure_config_sync_dir.sh

# Deploy custom modules, themes.
COPY ./custom/themes ${DRUPAL_ROOT}/themes/custom
COPY ./custom/modules ${DRUPAL_ROOT}/modules/custom

# Container metadata.
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION
LABEL ca.unb.lib.generator="drupal11" \
  org.opencontainers.image.title="educationhistory.lib.unb.ca" \
  org.opencontainers.image.description="educationhistory.lib.unb.ca provides web-readble copies of the Development of the Theory and Practice of Education in New Brunswick at UNB Libraries." \
  org.opencontainers.image.vendor="University of New Brunswick Libraries" \
  org.opencontainers.image.authors="UNB Libraries <libsupport@unb.ca>" \
  org.opencontainers.image.url="https://educationhistory.lib.unb.ca" \
  org.opencontainers.image.source="https://github.com/unb-libraries/educationhistory.lib.unb.ca" \
  org.opencontainers.image.version="$VERSION" \
  org.opencontainers.image.revision="$VCS_REF" \
  org.opencontainers.image.created="$BUILD_DATE"
