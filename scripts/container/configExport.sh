#!/usr/bin/env sh
# Remove existing configuration.
rm -rf ${DRUPAL_CONFIGURATION_DIR}/*

# Write out config.
drush --root=${DRUPAL_ROOT} --uri=default --yes config-export --skip-modules=${DRUPAL_CONFIGURATION_EXPORT_SKIP} --destination=${DRUPAL_CONFIGURATION_DIR}
rm -rf ${DRUPAL_CONFIGURATION_DIR}/*devel*
