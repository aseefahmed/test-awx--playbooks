#!/usr/bin/env pwsh

Param (
    [string]$type,
    [string]$name

)

$timeOutSeconds = 600

$start = Get-Date

$success = $false
$waitIndicatorWritten = $false
do {
  echo "" | openssl s_client -verify_quiet -verify_return_error -brief -servername $domain -connect $connection >> wait-for-cert.log 2>&1
  if (kubectl -n {{ awx_namespace }} get $type $name "-otemplate={% raw %}{{range .status.conditions}}{{if and (eq .status `"True`") (eq .reason `"Successful`") (eq .type `"Successful`")}}Yes{{end}}{{end}}{% endraw %}") {
    if ($waitIndicatorWritten) { Write-Host }
    "{{ backup_name }} - OK" | Write-Host
    $success = $true
  } else {
    "." | Write-Host -NoNewLine
     $waitIndicatorWritten = $true
    Start-Sleep -Seconds 1
  }
} while (!$success -and (((Get-Date) - $start).TotalSeconds -le $timeOutSeconds))
if (!$success -and (((Get-Date) - $start).TotalSeconds -gt $timeOutSeconds)) {
    if ($waitIndicatorWritten) { Write-Host }
    "{{ backup_name }} - Timeout" | Write-Host
  exit 1
}
