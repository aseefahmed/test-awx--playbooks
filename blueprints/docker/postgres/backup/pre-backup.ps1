#!/usr/bin/env pwsh

$ErrorActionPreference = "Stop"
$manifests = "~/manifests_rendered"
$pathToBackup = "/mnt/docker/postgres/backup"


cd $manifests
docker compose down
if ($LASTEXITCODE) { exit $LASTEXITCODE }

sed 's/- 5432:5432//;s/ports://' docker-compose.yaml > tmpcompose.yaml
if ($LASTEXITCODE) { exit $LASTEXITCODE }
docker compose -f tmpcompose.yaml up -d
if ($LASTEXITCODE) { exit $LASTEXITCODE }

$timeOutSeconds = 30
$waitIndicatorWritten = $false
$start = Get-Date
do {
  docker exec -it -u postgres postgres pg_isready
  if ($LASTEXITCODE -eq 0) {
    if ($waitIndicatorWritten) { Write-Host }
    "OK" | Write-Host
    $success = $true
  } else {
    #"." | Write-Host -NoNewLine
    #$waitIndicatorWritten = $true
    Start-Sleep -Seconds 1
  }
} while (!$success -and (((Get-Date) - $start).TotalSeconds -le $timeOutSeconds))
if (!$success -and (((Get-Date) - $start).TotalSeconds -gt $timeOutSeconds)) {
    if ($waitIndicatorWritten) { Write-Host }
    "Timeout" | Write-Host
  exit 1
}

$dbs = docker exec -it -u postgres postgres psql -Atqc "select datname from pg_database where datistemplate='f' and datname!='postgres';"
if ($LASTEXITCODE) { exit $LASTEXITCODE }

$dbs | %{
  Get-Date | Write-Host
  $_ | write-Host
  bash -c "docker exec -it -u postgres postgres pg_dump $_  | gzip -c > $pathToBackup/$_.sql.gz"

}

Get-Date | Write-Host

bash -c "docker exec -it -u postgres postgres pg_dumpall -r | gzip -c > $pathToBackup/pg_roles.sql.gz"

Get-Date | Write-Host
