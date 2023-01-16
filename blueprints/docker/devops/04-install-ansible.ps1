#!/usr/bin/env pwsh

$ErrorActionPreference = "Stop"

$users = '{{ devops_users | to_json }}' | ConvertFrom-Json
$users | Foreach-Object {
  sudo -u $_ python3 -m pip install --user ansible --no-warn-script-location
}
