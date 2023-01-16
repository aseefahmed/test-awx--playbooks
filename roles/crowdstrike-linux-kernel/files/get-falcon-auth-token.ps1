#!/usr/bin/env pwsh

$ErrorActionPreference = "Stop"

# API documentation: https://falcon.us-2.crowdstrike.com/documentation/93/oauth2-auth-token-apis

#Write-Host "curl -sSv --fail-with-body -X POST *$env:FALCON_API_URL/oauth2/token* -H *accept: application/json* -H *Content-Type: application/x-www-form-urlencoded* -d *client_id=$env:FALCON_CLIENT_ID&client_secret=$env:FALCON_SECRET* 2>output.txt"
$ErrorActionPreference = "Continue"
$result = curl -sSv --fail-with-body -X POST "$env:FALCON_API_URL/oauth2/token" -H "accept: application/json" -H "Content-Type: application/x-www-form-urlencoded" -d "client_id=$env:FALCON_CLIENT_ID&client_secret=$env:FALCON_SECRET" 2>output.txt
$ErrorActionPreference = "Stop"
Write-Host "[$(get-date -Format "dddd, d MMMM yyyy HH:mm:ss")]DEBUG get token START----"
Get-Content output.txt | Write-Host
Write-Host "[$(get-date -Format "dddd, d MMMM yyyy HH:mm:ss")]DEBUG get token body----"
Write-Host $result
Write-Host "[$(get-date -Format "dddd, d MMMM yyyy HH:mm:ss")]DEBUG get token END----"
Remove-Item output.txt
if ($LASTEXITCODE) { exit $LASTEXITCODE }

$token = ($result | ConvertFrom-Json).access_token
$token
