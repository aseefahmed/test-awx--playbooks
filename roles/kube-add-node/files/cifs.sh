#!/bin/bash

set -e

sudo apt-get install cifs-utils jq util-linux coreutils -y
export VOLUME_PLUGIN_DIR="/usr/libexec/kubernetes/kubelet-plugins/volume/exec"
sudo mkdir -p "$VOLUME_PLUGIN_DIR/fstab~cifs"
cd "$VOLUME_PLUGIN_DIR/fstab~cifs"
sudo curl -L -O https://raw.githubusercontent.com/fstab/cifs/7e19c6c77dc1c9d78339dd23df5342211a02f719/cifs
sudo chmod 755 cifs
sudo $VOLUME_PLUGIN_DIR/fstab~cifs/cifs init
