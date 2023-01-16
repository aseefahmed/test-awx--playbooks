$ErrorActionPreference = "Stop"
$sensorInstaller = ".\falconWin.exe"
Write-Host "Downloading sensor..."
curl.exe -sSLf $env:SENSOR_URL -o $sensorInstaller
if ($LASTEXITCODE) { exit $LASTEXITCODE }
Write-Host "Installing sensor..."
. $sensorInstaller /install /quiet /norestart CID=$env:CCID
