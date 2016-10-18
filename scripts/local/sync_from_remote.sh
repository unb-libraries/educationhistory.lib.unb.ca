#!/usr/bin/env bash

# Crude argument check.
if [ $# -lt 2 ]
  then
    echo "Usage : ./sync_from_remote.sh SITE_URI REMOTE_HOST"
fi

# Define sane variables from arguments.
SITE_URI=$1
DEV_HOSTNAME=$2

# Base command definitions.
DOCKER_LOCAL="docker"
DRUSH_COMMAND="drush --root=/app/html --yes"
RSYNC_COMMAND="rsync -avhP"
SSH_REMOTE="ssh $DEV_HOSTNAME"
DOCKER_REMOTE="$SSH_REMOTE $DOCKER_LOCAL"

# Common paths.
CONTAINER_APP_FILE_PATH="/app/html/sites/default/files"
LOCAL_TMP_CONF_DIR="./config-yml"
LOCAL_TMP_DB_DIR="./tmp-db"
LOCAL_TMP_FILE_DIR="./tmp-files"
TEMP_FILE_PATH="/tmp/drupal_sync_files-$SITE_URI"
TEMP_CONFIG_PATH="/tmp/drupal_sync_config-$SITE_URI"

# Check if local dev docker URI container is up.
LOCAL_RUNNING=$($DOCKER_LOCAL inspect --format='{{.State.Running}}' "$SITE_URI")
if [ "$LOCAL_RUNNING" == "false" ]; then
  echo "ERROR - $SITE_URI not running locally."
  exit 3
fi

# Check if we can SSH to DEV_HOSTNAME.
DEV_SSH_STATUS=$(ssh -o "BatchMode yes" -o "ConnectTimeout 5" -o -"StrictHostKeyChecking no" "$DEV_HOSTNAME" echo ok 2>&1)
if [[ $? -eq 1 ]] ; then
  echo "ERROR - Cannot open SSH connection to $DEV_HOSTNAME."
fi

# Check if remote docker URI container is up.
DEV_RUNNING=$($DOCKER_REMOTE inspect --format='{{.State.Running}}' "$SITE_URI")
if [ "$DEV_RUNNING" == "false" ]; then
  echo "ERROR - $SITE_URI not running on dev host."
  exit 3
fi

# Ensure we quit on error.
set -e

## Transfer Filesystem from dev docker URI.
#
# Remove temporary files from local and remote docker host, if they exist.
$SSH_REMOTE rm -rf "$TEMP_FILE_PATH"
rm -rf "$LOCAL_TMP_FILE_DIR"
# Rebuild the cache to avoid extraneous data coming over.
$DOCKER_REMOTE exec "$SITE_URI" $DRUSH_COMMAND cache-rebuild
# Copy the data from the container to the remote docker host in a temporary filesystem.
$DOCKER_REMOTE cp "$SITE_URI:$CONTAINER_APP_FILE_PATH" "$TEMP_FILE_PATH"
# Copy files
mkdir -p "$LOCAL_TMP_FILE_DIR"
$RSYNC_COMMAND "$DEV_HOSTNAME:$TEMP_FILE_PATH/" "$LOCAL_TMP_FILE_DIR" --delete
$SSH_REMOTE rm -rf "$TEMP_FILE_PATH"
$DOCKER_LOCAL exec "$SITE_URI" rm -rf "$CONTAINER_APP_FILE_PATH"
$DOCKER_LOCAL cp "$LOCAL_TMP_FILE_DIR" "$SITE_URI:$CONTAINER_APP_FILE_PATH"
$DOCKER_LOCAL exec "$SITE_URI" chown -R nginx:nginx "$CONTAINER_APP_FILE_PATH"
$DOCKER_LOCAL exec "$SITE_URI" $DRUSH_COMMAND cache-rebuild
rm -rf "$LOCAL_TMP_FILE_DIR"

## Dump database from dev docker URI and import to local.
#
rm -rf "$LOCAL_TMP_DB_DIR"
mkdir -p "$LOCAL_TMP_DB_DIR"
$DOCKER_REMOTE exec "$SITE_URI" $DRUSH_COMMAND sql-dump > "$LOCAL_TMP_DB_DIR/$SITE_URI.sql.txt"
$DOCKER_LOCAL exec -i "$SITE_URI" $DRUSH_COMMAND sql-cli < "$LOCAL_TMP_DB_DIR/$SITE_URI.sql.txt"
$DOCKER_LOCAL exec "$SITE_URI" $DRUSH_COMMAND cache-rebuild
rm -rf "$LOCAL_TMP_DB_DIR"

## Dump configuration from dev docker URI and import to local dev folder to
# reflect upstream. Since the database now also stores a cached copy of the
# config, it is not necessary to config-import this into the local container,
# since the database dump already.
#
rm -rf "$LOCAL_TMP_CONF_DIR/*"
$DOCKER_LOCAL exec "$SITE_URI" rm -rf "$TEMP_CONFIG_PATH"
$SSH_REMOTE rm -rf "$TEMP_CONFIG_PATH"
$DOCKER_REMOTE exec "$SITE_URI" rm -rf "$TEMP_CONFIG_PATH"
$DOCKER_REMOTE exec "$SITE_URI" mkdir -p "$TEMP_CONFIG_PATH"
$DOCKER_REMOTE exec "$SITE_URI" $DRUSH_COMMAND config-export --destination="$TEMP_CONFIG_PATH/"
$DOCKER_REMOTE cp "$SITE_URI:$TEMP_CONFIG_PATH" "$TEMP_CONFIG_PATH"
$DOCKER_REMOTE exec "$SITE_URI" rm -rf "$TEMP_CONFIG_PATH"
$RSYNC_COMMAND "$DEV_HOSTNAME:$TEMP_CONFIG_PATH/" $LOCAL_TMP_CONF_DIR --delete
$SSH_REMOTE rm -rf "$TEMP_CONFIG_PATH"

# Export the configuration to the container's config path to keep all synced.
$DOCKER_LOCAL exec "$SITE_URI" /scripts/configExport.sh

## Apply any entity updates that may have come down from the remote instance.
$DOCKER_LOCAL exec "$SITE_URI" $DRUSH_COMMAND entity-updates

# Restore wiped-out .gitkeep file.
git checkout -- "$LOCAL_TMP_CONF_DIR/.gitkeep"
