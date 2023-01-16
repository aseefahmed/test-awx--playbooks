#!/usr/bin/env pwsh

curl -sSL https://dl.min.io/client/mc/release/linux-amd64/mc -o /usr/local/bin/mc
if ($LASTEXITCODE) { exit $LASTEXITCODE }
chmod +x /usr/local/bin/mc
if ($LASTEXITCODE) { exit $LASTEXITCODE }
