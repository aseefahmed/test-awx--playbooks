#!/bin/bash

set -e
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

cp $SCRIPT_DIR/_.barfoot.co.nz.crt /etc/ssl/certs/_.barfoot.co.nz.crt
cp $SCRIPT_DIR/_.barfoot.co.nz.key /etc/ssl/certs/_.barfoot.co.nz.key
