#!/usr/bin/env pwsh

$ErrorActionPreference = "Stop"

timedatectl set-timezone Pacific/Auckland
if ($LASTEXITCODE) { exit $LASTEXITCODE }
