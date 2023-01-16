#!/bin/bash

set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

docker compose stop semaphore
docker exec semaphore_postgres psql -U postgres -c "create database semaphore"

if [[ ! -d /mnt/docker/postgres/backup ]]
then
  echo "Creating backup directory..."
  mkdir -p /mnt/docker/postgres/backup
fi

if [[ -f /mnt/docker/postgres/backup/dump.gz ]]
then
  echo "Restoring backup..."
  gzip -c -d /mnt/docker/postgres/backup/dump.gz | docker exec -i semaphore_postgres psql -U postgres -d semaphore
fi

docker compose up -d --force-recreate
