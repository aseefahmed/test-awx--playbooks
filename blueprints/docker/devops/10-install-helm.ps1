#!/usr/bin/env pwsh

curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
if ($LASTEXITCODE) { exit $LASTEXITCODE }
bash ./get_helm.sh
if ($LASTEXITCODE) { exit $LASTEXITCODE }
