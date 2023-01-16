#!/usr/bin/env pwsh

$ErrorActionPreference = "Stop"
$pathToBackup = "{{ local_stoarage_path }}/{{ backup_pv }}"

if (Test-Path $pathToBackup) { # restore mode
  $manifest = Join-Path $PSScriptRoot init awxrestore.yaml

  # Kick off the restore
  kubectl apply -f $manifest
  if ($LASTEXITCODE) { exit $LASTEXITCODE }

  # Wait for restore to finish
  $wait_script = Join-Path $PSScriptRoot backup wait-for-success.ps1
  & $wait_script awxrestore {{ backup_name }}
  if ($LASTEXITCODE) { exit $LASTEXITCODE }
} else { # setup mode
  # This has to be done for the persistent volume to come up
  mkdir -p $pathToBackup
  if ($LASTEXITCODE) { exit $LASTEXITCODE }

  $manifest = Join-Path $PSScriptRoot init init.yaml
  # Create a new installation of awx
  kubectl apply -f $manifest
  if ($LASTEXITCODE) { exit $LASTEXITCODE }
}
