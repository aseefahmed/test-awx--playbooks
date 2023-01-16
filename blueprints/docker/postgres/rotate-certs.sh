#!/bin/bash

date
mkdir -p /mnt/docker/postgres/certs

cp /etc/ssl/certs/_.barfoot.co.nz.* /mnt/docker/postgres/certs/

chmod 640 /mnt/docker/postgres/certs/_.barfoot.co.nz.key
chown 0:101 /mnt/docker/postgres/certs/_.barfoot.co.nz.key
chmod 644 /mnt/docker/postgres/certs/_.barfoot.co.nz.crt
chown 0:0 /mnt/docker/postgres/certs/_.barfoot.co.nz.crt

docker exec -t -u postgres postgres pg_ctl reload
