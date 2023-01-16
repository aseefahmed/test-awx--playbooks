#!/bin/bash

set -e

function resize() {
  DEVICE=$1
  PARTNR=$2

  sudo fdisk -l $DEVICE$PARTNR >> /dev/null 2>&1 || (echo "could not find device $DEVICE$PARTNR - please check the name" && exit 1)

  CURRENTSIZEB=$(sudo parted $DEVICE unit B print | awk "/ $PARTNR /{print \$4}" | tr -d B)
  CURRENTSIZE=$(expr $CURRENTSIZEB / 1024 / 1024)
  START=$(sudo parted $DEVICE unit B print | awk "/ $PARTNR /{print \$2}" | tr -d B)

  MAXSIZEB=$(sudo parted $DEVICE unit B print | grep "Disk ${DEVICE}" | cut -d' ' -f3 | tr -d B)
  END=$(expr $MAXSIZEB - 1)

  NEWSIZEMB=$(expr \( $END - $START + 1 \) / 1024 / 1024)

  echo "Will resize from ${CURRENTSIZE}MB to ${NEWSIZEMB}MB "

  echo "Resizing partition.."
  sudo parted ${DEVICE} unit B resizepart ${PARTNR} ${END}
  echo "[done]"

}


echo 1 | sudo tee /sys/class/block/sda/device/rescan
resize /dev/sda 2
resize /dev/sda 5

echo "Resizing lvm phisical volume.."
sudo pvresize /dev/sda5

echo "Resizing lvm logical volume and filesystem.."
sudo lvextend -r -l+100%FREE /dev/vgvagrant/root
