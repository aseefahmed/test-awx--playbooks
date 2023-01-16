#!/bin/bash

docker exec semaphore_postgres pg_dump -U postgres -d semaphore | gzip > /mnt/docker/postgres/backup/dump.gz
