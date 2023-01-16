#!/usr/bin/env pwsh

$ErrorActionPreference = "Stop"

$token = $env:FALCON_TOKEN

# FQL documentation: https://falcon.us-2.crowdstrike.com/documentation/45/falcon-query-language-fql
$query = "vendor:'$env:FALCON_VENDOR'+distro:'$env:FALCON_DISTRO'+flavor:'$env:FALCON_FLAVOR'+(base_package_supported_sensor_versions:*'*$env:FALCON_VERSION')"

Write-Host "Getting kernel support info..."
$resources = @()
$offset = 0 # the API results are paged. The loop below recombines it from pages
do {
  # API documentation: https://falcon.us-2.crowdstrike.com/documentation/201/sensor-update-policy-apis
  $ErrorActionPreference = "Continue"
  $tempFile = New-TemporaryFile
  $result = curl -sSv --fail-with-body -X GET "$env:FALCON_API_URL/policy/combined/sensor-update-kernels/v1?offset=$offset&filter=$([uri]::EscapeDataString($query))" -H 'Accept: application/json' -H "Authorization: Bearer $token" -H 'Content-Type: application/json' 2>$tempFile
  $ErrorActionPreference = "Stop"
  Write-Host "[$(get-date -Format "dddd, d MMMM yyyy HH:mm:ss")]DEBUG get kernel info START----"
  Get-Content $tempFile |  Write-Host
  Write-Host "[$(get-date -Format "dddd, d MMMM yyyy HH:mm:ss")]DEBUG get kernel info body----"
  Write-Host $result
  Write-Host "[$(get-date -Format "dddd, d MMMM yyyy HH:mm:ss")]DEBUG get kernel info END----"
  Remove-Item $tempFile
  if ($LASTEXITCODE) { exit $LASTEXITCODE }
  $json = ($result | ConvertFrom-Json)
  $resources = @($resources) + @($json.resources)
  $offset = $json.meta.pagination.offset
  $total = $json.meta.pagination.total
  Write-Host "Read $offset out of $total"
} while ($offset -and $offset -lt $total) #if query returns zero results it succeed but $offset is empty

# Sort the versions and get the biggest (last one)
$targetKernelVersion = ($resources | sort-object {[version][regex]::replace($_.release,"((\d+).(\d+).(\d+))-(\d+).*",'$1.$5')} | select-object -Last 1).release

if (!$targetKernelVersion) {
        $resources | ConvertTo-Json -Depth 100 | Write-Host # for debugging
        Write-Error "Unable to find suitable target kernel version"
	exit 1
}

$targetKernelVersion
