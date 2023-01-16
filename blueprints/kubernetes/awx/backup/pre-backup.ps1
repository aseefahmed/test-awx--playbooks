#!/usr/bin/env pwsh

$ErrorActionPreference = "Stop"
$pathToBackup = "{{ local_stoarage_path }}/{{ backup_pv }}"

# Remove all previous backups
Remove-Item "$pathToBackup/*" -Recurse

$manifest = Join-Path $PSScriptRoot awxbackup.yaml

# Remove the olf backup object if any
kubectl delete -f $manifest

# Kick off the backup
kubectl apply -f $manifest
if ($LASTEXITCODE) { exit $LASTEXITCODE }

# Wait for backup to finish
$wait_script = Join-Path $PSScriptRoot wait-for-success.ps1
& $wait_script awxbackup {{ backup_name }}
if ($LASTEXITCODE) { exit $LASTEXITCODE }

# Backup process creates a subfolder based on timestamp, rename it to a pre-set folder name for restic backup/restore process
$backupDir = Get-ChildItem  $pathToBackup | Select-Object -Expand FullName | Sort-Object | Select-Object -Last 1
Move-Item $backupDir (Join-Path $pathToBackup backup)
