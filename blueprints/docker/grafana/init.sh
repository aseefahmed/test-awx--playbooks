#!/bin/bash

mkdir -p /mnt/grafana/data
chown 472:0 /mnt/grafana/data

#docker run --rm -it --entrypoint 'bash' grafana/grafana:{{ grafana_tag }} -c 'cat /etc/grafana/grafana.ini' > /mnt/grafana/config/grafana.ini

docker run --rm -d --name grafana_config grafana/grafana:{{ grafana_tag }} 
docker cp grafana_config:/etc/grafana /mnt/grafana/config
docker stop grafana_config

chown 472:0 -R /mnt/grafana/config
