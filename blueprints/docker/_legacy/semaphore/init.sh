#!/bin/bash

set -e
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

mkdir -p /mnt/docker/semaphore
cp $SCRIPT_DIR/config.json /mnt/docker/semaphore/config.json
chown 1001:1001 -R /mnt/docker/semaphore/config.json
