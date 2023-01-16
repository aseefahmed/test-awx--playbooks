#!/usr/bin/env pwsh

$ErrorActionPreference = "Stop"
$pathToBackup = "{{ local_stoarage_path }}/{{ backup_pv }}"

# Install awx operator, which will install awx
helm repo add awx-operator https://ansible.github.io/awx-operator/
if ($LASTEXITCODE) { exit $LASTEXITCODE }
helm repo update
if ($LASTEXITCODE) { exit $LASTEXITCODE }
helm search repo awx-operator
if ($LASTEXITCODE) { exit $LASTEXITCODE }
helm install -n awx --create-namespace my-awx-operator awx-operator/awx-operator
if ($LASTEXITCODE) { exit $LASTEXITCODE }
