#!/usr/bin/env pwsh

$ErrorActionPreference = "Stop"

"Getting access token..." | Write-Host
$result = curl -sSf -X POST "$env:FALCON_API_URL/oauth2/token" -H "accept: application/json" -H "Content-Type: application/x-www-form-urlencoded" -d "client_id=$env:FALCON_CLIENT_ID&client_secret=$env:FALCON_SECRET"
if ($LASTEXITCODE) { exit $LASTEXITCODE }

$token = ($result | ConvertFrom-Json).access_token

"Getting sensor info..." | Write-Host
$result = curl -sSf -X GET "$env:FALCON_API_URL/sensors/combined/installers/v1" -H 'Accept: application/json' -H "Authorization: Bearer $token" -H 'Content-Type: application/json'
if ($LASTEXITCODE) { exit $LASTEXITCODE }

$windows = (($result | ConvertFrom-Json).resources | ?{ $_.os -eq "Windows" } | sort-object version | select-object -Last 2 | select-object -First 1)
$ubuntu = (($result | ConvertFrom-Json).resources | ?{ $_.os -eq "Ubuntu" -and $_.os_version -notlike '*arm*' } | sort-object version | select-object -Last 2 | select-object -First 1)

$hashWindows = $windows.sha256
$hashUbuntu = $ubuntu.sha256

Set-Content windows.version $windows.version
Set-Content ubuntu.version $ubuntu.version

"Downloading Windows sensor..." | Write-Host
curl -sSf -X GET "$env:FALCON_API_URL/sensors/entities/download-installer/v1?id=$hashWindows" -H "Authorization: Bearer $token" -o falcon-sensor.exe
if ($LASTEXITCODE) { exit $LASTEXITCODE }

"Downloading Ubuntu sensor..." | Write-Host
curl -sSf -X GET "$env:FALCON_API_URL/sensors/entities/download-installer/v1?id=$hashUbuntu" -H "Authorization: Bearer $token" -o falcon-sensor.deb
if ($LASTEXITCODE) { exit $LASTEXITCODE }
