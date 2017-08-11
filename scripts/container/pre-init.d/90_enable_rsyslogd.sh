#!/usr/bin/env sh
if [ "$LOGZIO_KEY" != "" ]; then
  echo "Starting rsyslogd..."
  sed -i "s|LOGZIO_KEY|$LOGZIO_KEY|g" /etc/rsyslog.d/21-logzio-nginx.conf
  /usr/sbin/rsyslogd -f /etc/rsyslog.conf
fi
