#!/usr/bin/env sh
# Copy build files into a temporary build location.
mkdir ${DRUPAL_BUILD_TMPROOT}
cp ${TMP_DRUPAL_BUILD_DIR}/composer.json ${DRUPAL_BUILD_TMPROOT}
cp -r ${TMP_DRUPAL_BUILD_DIR}/scripts ${DRUPAL_BUILD_TMPROOT}
cd ${DRUPAL_BUILD_TMPROOT}

# Build instance.
composer install --${COMPOSER_DEPLOY_DEV}

# Configure scaffolding files.
ln -s /app/html/vendor/bin/drush /usr/bin/drush
ln -s /app/html/vendor/bin/drupal /usr/bin/drupal
mv ${TMP_DRUPAL_BUILD_DIR}/${DRUPAL_SITE_ID} ${DRUPAL_BUILD_TMPROOT}/profiles/
mkdir -p ${DRUPAL_BUILD_TMPROOT}/sites/all
mv ${TMP_DRUPAL_BUILD_DIR}/settings ${DRUPAL_BUILD_TMPROOT}/sites/all/
