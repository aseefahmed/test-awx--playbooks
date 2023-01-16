#!/usr/bin/env pwsh

$ErrorActionPreference = "Stop"

{% if allowTLS == "true" %}
# Copy certififcate
mkdir -p /mnt/docker/postgres/certs
if ($LASTEXITCODE) { exit $LASTEXITCODE }

cp /etc/ssl/certs/_.barfoot.co.nz.* /mnt/docker/postgres/certs/

chmod 640 /mnt/docker/postgres/certs/_.barfoot.co.nz.key
if ($LASTEXITCODE) { exit $LASTEXITCODE }
chown 0:101 /mnt/docker/postgres/certs/_.barfoot.co.nz.key
if ($LASTEXITCODE) { exit $LASTEXITCODE }
chmod 644 /mnt/docker/postgres/certs/_.barfoot.co.nz.crt
if ($LASTEXITCODE) { exit $LASTEXITCODE }
chown 0:0 /mnt/docker/postgres/certs/_.barfoot.co.nz.crt
if ($LASTEXITCODE) { exit $LASTEXITCODE }

cp "$PSScriptRoot/rotate-certs.sh" /root/rotate-certs.sh

# Setup Schedule
bash "$PSScriptRoot/set-cronjob.sh"
{% endif %}

# Restore if any
cd $PSScriptRoot
sed 's/- 5432:5432//;s/ports://' "$PSScriptRoot/docker-compose.yaml" > tmpcompose.yaml 
if ($LASTEXITCODE) { exit $LASTEXITCODE }
docker compose -f tmpcompose.yaml up -d

if (Test-Path /mnt/docker/postgres/backup) {

  $timeOutSeconds = 30
  $waitIndicatorWritten = $false
  $start = Get-Date
  do {
    docker exec -it -u postgres postgres pg_isready -h postgres
    if ($LASTEXITCODE -eq 0) {
      if ($waitIndicatorWritten) { Write-Host }
      "OK" | Write-Host
      $success = $true
    } else {
      "." | Write-Host -NoNewLine
       $waitIndicatorWritten = $true
      Start-Sleep -Seconds 1
    }
  } while (!$success -and (((Get-Date) - $start).TotalSeconds -le $timeOutSeconds))
  if (!$success -and (((Get-Date) - $start).TotalSeconds -gt $timeOutSeconds)) {
      if ($waitIndicatorWritten) { Write-Host }
      "Timeout" | Write-Host
    exit 1
  }

  bash -c "zcat /mnt/docker/postgres/backup/pg_roles.sql.gz | docker exec -i -u postgres postgres psql"
  Get-ChildItem /mnt/docker/postgres/backup/*.sql.gz | ForEach-Object {
    if ($_.FullName -ne "/mnt/docker/postgres/backup/pg_roles.sql.gz") {
      $db = $_.Name.Replace(".sql.gz","")
      bash -c "docker exec -i -u postgres postgres createdb -O $db $db"
      bash -c "zcat $($_.FullName) | docker exec -i -u postgres postgres psql -d $db"
    }
  }  
}

$passwordFile = "$PSScriptRoot/vercheck.txt"
$username = "vercheck"

$password = Get-Content $passwordFile

$role = docker exec -i -u postgres postgres psql -t -c "select * from pg_roles where rolname = '$username'"
if ($LASTEXITCODE) { exit $LASTEXITCODE }

if ($role) {
  Write-Host "User $username already exists"
} else {
  docker exec -i -u postgres postgres psql -t -c "create user $username password '$password'"
  if ($LASTEXITCODE) { exit $LASTEXITCODE }
}
Remove-Item $passwordFile

docker compose -f tmpcompose.yaml down

{% if enforceTLS == "true" %}
# Disable non-tls connections
sed -i /mnt/docker/postgres/data/pg_hba.conf -e 's/host all all all scram-sha-256/hostssl all all all scram-sha-256/'
{% endif %}
