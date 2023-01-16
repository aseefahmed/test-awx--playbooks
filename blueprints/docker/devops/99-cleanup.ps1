#!/usr/bin/env pwsh

$ErrorActionPreference = "Stop"

Remove-Item (Join-Path $PSScriptRoot githubToken.txt)
Remove-Item (Join-Path $PSScriptRoot devops.key)
