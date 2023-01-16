#!/usr/bin/env pwsh

$ErrorActionPreference = "Stop"

$env:DEBIAN_FRONTEND="noninteractive"

bash (Join-Path $PSScriptRoot add-vault-apt.sh)
if ($LASTEXITCODE) { exit $LASTEXITCODE }
bash (Join-Path $PSScriptRoot add-google-apt.sh)
if ($LASTEXITCODE) { exit $LASTEXITCODE }
apt-get update
if ($LASTEXITCODE) { exit $LASTEXITCODE }
apt-get install -y debsums tmate python3-pip dotnet6 vault kubectl gnupg2 pass libsecret-1-0 python-is-python3 tshark
if ($LASTEXITCODE) { exit $LASTEXITCODE }
apt-get remove -y unattended-upgrades
if ($LASTEXITCODE) { exit $LASTEXITCODE }
rm -rf /root/snap
if ($LASTEXITCODE) { exit $LASTEXITCODE }
