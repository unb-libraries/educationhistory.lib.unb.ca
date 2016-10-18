#!/usr/bin/env sh
# Deploy profile to drupal tree.
mv ${TMP_DRUPAL_BUILD_DIR}/profile/profile.info.yml ${TMP_DRUPAL_BUILD_DIR}/profile/${DRUPAL_SITE_ID}.info.yml
mv ${TMP_DRUPAL_BUILD_DIR}/profile/profile.install ${TMP_DRUPAL_BUILD_DIR}/profile/${DRUPAL_SITE_ID}.install
mv ${TMP_DRUPAL_BUILD_DIR}/profile/profile.profile ${TMP_DRUPAL_BUILD_DIR}/profile/${DRUPAL_SITE_ID}.profile
find ${TMP_DRUPAL_BUILD_DIR}/profile/ -type f -print0 | xargs -0 sed -i "s/PROFILE_SLUG/$DRUPAL_SITE_ID/g"
mv ${TMP_DRUPAL_BUILD_DIR}/profile ${TMP_DRUPAL_BUILD_DIR}/${DRUPAL_SITE_ID}
