#!/usr/bin/env pwsh

$ErrorActionPreference = "Stop"

$githubToken = Get-Content (Join-Path $PSScriptRoot githubToken.txt)

$tempFile = New-TemporaryFile
$result = curl -sSv --fail-with-body -H "Authorization: Bearer $githubToken" https://api.github.com/repos/nvm-sh/nvm/releases/latest 2>$tempFile
Write-Host "[$(get-date -Format "dddd, d MMMM yyyy HH:mm:ss")]DEBUG get nvm latest info START----"
Get-Content $tempFile |  Write-Host
Write-Host "[$(get-date -Format "dddd, d MMMM yyyy HH:mm:ss")]DEBUG get nvm latest info body----"
Write-Host $result
Write-Host "[$(get-date -Format "dddd, d MMMM yyyy HH:mm:ss")]DEBUG get nvm latest info END----"
Remove-Item $tempFile
if ($LASTEXITCODE) { exit $LASTEXITCODE }

$tag = ($result | ConvertFrom-Json).tag_name

$install = (Join-Path /tmp nvm-install.sh)

$tempFile = New-TemporaryFile
curl -sSv --fail-with-body -o $install "https://raw.githubusercontent.com/nvm-sh/nvm/$tag/install.sh" 2>$tempFile
Write-Host "[$(get-date -Format "dddd, d MMMM yyyy HH:mm:ss")]DEBUG get nvm install script START----"
Get-Content $tempFile |  Write-Host
Write-Host "[$(get-date -Format "dddd, d MMMM yyyy HH:mm:ss")]DEBUG get nvm install script END----"
Remove-Item $tempFile
if ($LASTEXITCODE) { exit $LASTEXITCODE }

chmod +x $install

$users = '{{ devops_users | to_json }}' | ConvertFrom-Json
$users | Foreach-Object {
  sudo -u $_ $install
  if ($LASTEXITCODE) { exit $LASTEXITCODE }
  sudo -iu $_ bash -c '. $HOME/.nvm/nvm.sh;nvm install node'
  if ($LASTEXITCODE) { exit $LASTEXITCODE }
}
