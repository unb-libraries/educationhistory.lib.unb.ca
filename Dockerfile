FROM unblibraries/dockworker-drupal:latest
MAINTAINER UNB Libraries <libsupport@unb.ca>

ENV DRUPAL_SITE_ID eduhist
ENV DRUPAL_SITE_URI educationhistory.lib.unb.ca
ENV DRUPAL_SITE_UUID f1de2d88-eedf-4115-af2b-d55cf0a30215

# Override scripts with any local.
COPY ./scripts/container /scripts

# Add additional OS packages.
ENV ADDITIONAL_OS_PACKAGES rsyslog postfix php7-ldap php7-redis
RUN /scripts/addOsPackages.sh && \
  echo "TLS_REQCERT never" > /etc/openldap/ldap.conf && \
  /scripts/initRsyslog.sh

# Add package conf.
COPY ./package-conf /package-conf
RUN /scripts/setupStandardConf.sh

# Build the contrib Drupal tree.
ARG COMPOSER_DEPLOY_DEV=no-dev
ENV DRUPAL_BASE_PROFILE minimal
ENV DRUPAL_BUILD_TMPROOT ${TMP_DRUPAL_BUILD_DIR}/webroot

COPY ./build/ ${TMP_DRUPAL_BUILD_DIR}
RUN /scripts/build.sh ${COMPOSER_DEPLOY_DEV} ${DRUPAL_BASE_PROFILE}

# Deploy repo assets.
COPY ./tests/ ${DRUPAL_TESTING_ROOT}/
COPY ./config-yml ${TMP_DRUPAL_BUILD_DIR}/config-yml
COPY ./custom/themes ${TMP_DRUPAL_BUILD_DIR}/custom_themes
COPY ./custom/modules ${TMP_DRUPAL_BUILD_DIR}/custom_modules

# Universal environment variables.
ENV DEPLOY_ENV prod
ENV DRUPAL_DEPLOY_CONFIGURATION TRUE
ENV DRUPAL_CONFIGURATION_EXPORT_SKIP devel

# Metadata
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION
LABEL ca.unb.lib.generator="drupal8" \
      com.microscaling.docker.dockerfile="/Dockerfile" \
      com.microscaling.license="MIT" \
      org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.description="educationhistory.lib.unb.ca provides web-readble copies of the Development of the Theory and Practice of Education in New Brunswick at UNB Libraries." \
      org.label-schema.name="educationhistory.lib.unb.ca" \
      org.label-schema.schema-version="1.0" \
      org.label-schema.url="https://educationhistory.lib.unb.ca" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/unb-libraries/educationhistory.lib.unb.ca" \
      org.label-schema.vendor="University of New Brunswick Libraries" \
      org.label-schema.version=$VERSION
