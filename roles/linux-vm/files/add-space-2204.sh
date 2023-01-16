#!/bin/bash

set -e

echo 1 | sudo tee /sys/class/block/sda/device/rescan
sudo growpart /dev/sda 3

echo "Resizing lvm phisical volume.."
sudo pvresize /dev/sda3

echo "Resizing lvm logical volume and filesystem.."
sudo lvextend -r -l+100%FREE /dev/ubuntu-vg/ubuntu-lv
