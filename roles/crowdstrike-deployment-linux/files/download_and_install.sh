#!/bin/bash

set -e

sensorInstaller='./falcon-sensor.deb'

echo "Downloading sensor..."
curl -sSLf $SENSOR_URL -o $sensorInstaller

echo "Installing sensor..."
dpkg -i $sensorInstaller

echo "Setting ccid..."
/opt/CrowdStrike/falconctl -s -f --cid=$CCID

echo "Starting service..."
systemctl start falcon-sensor
