#!/usr/bin/env pwsh

$ErrorActionPreference = "Stop"

bash (Join-Path $PSScriptRoot reinstall-man-pages.sh)
if ($LASTEXITCODE) { exit $LASTEXITCODE }
