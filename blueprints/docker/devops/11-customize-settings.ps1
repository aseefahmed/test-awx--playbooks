#!/usr/bin/env pwsh

$ErrorActionPreference = "Stop"

Update-Help -ErrorAction SilentlyContinue
$users = '{{ devops_users | to_json }}' | ConvertFrom-Json
$users | &{ process {
  sudo -iu $_ pwsh -Command { Update-Help -ErrorAction SilentlyContinue }
  if ($LASTEXITCODE) { exit $LASTEXITCODE }
  $homedir = ((getent passwd $_) -split ":")[5]
  Copy-Item -Recurse "$env:HOME/DevOps" $homedir
  chown -R "$($_):$($_)" (Join-Path $homedir DevOps)
}}
