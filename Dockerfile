FROM unblibraries/drupal:8.x-2.x-slim-unblib
MAINTAINER UNB Libraries <libsupport@unb.ca>

ENV DRUPAL_SITE_ID eduhist
ENV DRUPAL_SITE_URI educationhistory.lib.unb.ca
ENV DRUPAL_SITE_UUID f1de2d88-eedf-4115-af2b-d55cf0a30215

# Override upstream scripts with those from this repository.
COPY ./scripts/container /scripts

# Install additional OS packages.
ENV ADDITIONAL_OS_PACKAGES rsyslog postfix php7-ldap php7-redis
RUN /scripts/addOsPackages.sh && \
  echo "TLS_REQCERT never" > /etc/openldap/ldap.conf && \
  /scripts/initRsyslog.sh

# Add package configuration, build webtree.
COPY ./package-conf /package-conf
RUN /scripts/setupStandardConf.sh
COPY ./build /build
RUN /scripts/build.sh ${DRUPAL_BASE_PROFILE}

# Deploy repository assets.
COPY ./config-yml ${DRUPAL_CONFIGURATION_DIR}
COPY ./custom/themes ${DRUPAL_ROOT}/themes/custom
COPY ./custom/modules ${DRUPAL_ROOT}/modules/custom

# Metadata.
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
