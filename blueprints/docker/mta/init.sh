#!/bin/bash

set -e
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

mkdir -p /mnt/docker/postfix/sasl2
mkdir -p /mnt/docker/postfix/rsyslog
mkdir -p /mnt/docker/postfix/logrotate

docker run --rm -d --name postfix_config -v "$SCRIPT_DIR/postfix":/config registry.barfoot.co.nz/devops/postfix:{{ postfix_tag }}
docker exec -it postfix_config postalias /etc/postfix/aliases
docker cp postfix_config:/etc/postfix /mnt/docker/postfix
mv /mnt/docker/postfix/postfix /mnt/docker/postfix/config
if [[ -f "$SCRIPT_DIR/postfix/sasl_passwd" ]]; then
  docker exec -it postfix_config postmap /config/sasl_passwd
fi

docker stop postfix_config

cp -r "$SCRIPT_DIR/postfix"/* /mnt/docker/postfix/config
cp -r "$SCRIPT_DIR/sasl2"/* /mnt/docker/postfix/sasl2
cp "$SCRIPT_DIR/rsyslog/rsyslog.conf" /mnt/docker/postfix/rsyslog/rsyslog.conf
cp "$SCRIPT_DIR/logrotate/postfix.conf" /mnt/docker/postfix/logrotate/postfix.conf

chown 0:0 -R /mnt/docker/postfix/config
chmod -R 600 /mnt/docker/postfix/config
chown 100:101 -R /mnt/docker/postfix/sasl2
chmod -R 600 /mnt/docker/postfix/sasl2
chmod 700 /mnt/docker/postfix/sasl2
