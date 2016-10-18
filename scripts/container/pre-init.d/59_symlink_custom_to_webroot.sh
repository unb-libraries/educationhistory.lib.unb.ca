#!/usr/bin/env sh
for PROJ_TYPE in modules themes
do
  mkdir -p ${APP_ROOT}/${PROJ_TYPE}/custom
  rsync -a --progress --no-perms --no-owner --no-group --delete "${TMP_DRUPAL_BUILD_DIR}/custom_${PROJ_TYPE}/" "${APP_ROOT}/${PROJ_TYPE}/custom/"
  ln -s ${APP_ROOT}/${PROJ_TYPE}/custom ${DRUPAL_ROOT}/${PROJ_TYPE}/custom
done
