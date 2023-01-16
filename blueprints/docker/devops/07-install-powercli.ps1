#!/usr/bin/env pwsh

$ErrorActionPreference = "Stop"

$users = '{{ devops_users | to_json }}' | ConvertFrom-Json
$users | Foreach-Object {
  sudo -iu $_ pwsh -Command { Install-Module VMware.PowerCLI -Force }
  if ($LASTEXITCODE) { exit $LASTEXITCODE }
}
