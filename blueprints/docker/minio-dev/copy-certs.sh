#!/bin/bash
mkdir -p /mnt/docker/minio/config/certs
set -e
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

cp $SCRIPT_DIR/private.key /mnt/docker/minio/config/certs/private.key
cp $SCRIPT_DIR/public.crt /mnt/docker/minio/config/certs/public.crt
