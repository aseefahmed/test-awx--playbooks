#!/usr/bin/env pwsh

$ErrorActionPreference = "Stop"

$users = '{{ devops_users | to_json }}' | ConvertFrom-Json
$users | Foreach-Object {
  sudo -iu $_ git clone https://github.com/udhos/update-golang.git
  if ($LASTEXITCODE) { exit $LASTEXITCODE }
  sudo -iu $_ bash -c 'cd update-golang; sudo ./update-golang.sh'
  if ($LASTEXITCODE) { exit $LASTEXITCODE }
}
