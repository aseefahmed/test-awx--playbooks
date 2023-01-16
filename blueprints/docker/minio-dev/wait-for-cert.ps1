#!/usr/bin/env pwsh

$timeOutSeconds = 300

$domainsToCheck = "{{ minio_sub_domain }}.barfoot.co.nz", "{{ mc_sub_domain }}.barfoot.co.nz"
$connection = "127.0.0.1:443"

$start = Get-Date

$domainsToCheck | ForEach-Object {
  $success = $false
  $domain = $_
  $waitIndicatorWritten = $false
  do {
    echo "" | openssl s_client -verify_quiet -verify_return_error -brief -servername $domain -connect $connection >> wait-for-cert.log 2>&1
    if ($LASTEXITCODE -eq 0) {
      if ($waitIndicatorWritten) { Write-Host }
      "$domain - OK" | Write-Host
      $success = $true
    } else {
      "." | Write-Host -NoNewLine
       $waitIndicatorWritten = $true
      Start-Sleep -Seconds 1
    }
  } while (!$success -and (((Get-Date) - $start).TotalSeconds -le $timeOutSeconds))
  if (!$success -and (((Get-Date) - $start).TotalSeconds -gt $timeOutSeconds)) {
      if ($waitIndicatorWritten) { Write-Host }
      "$domain - Timeout" | Write-Host
    exit 1
  }
}
