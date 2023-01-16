#!/usr/bin/env pwsh
#Requires -Version 7

param(
    [string]$apiKey,
    [string]$varFileName,
    [string]$server
  )

$ErrorActionPreference = "Stop"

# Generic wrapper to Vault REST API - GET request
# Note that this uses global variables $server and $apiKey so that we do not have to pass them every call
function OctopusRest {
  param(
    [string]$partialPath,
    [string]$verb,
    [string]$payload
  )

  if (!$verb) {
    $verb = "GET"
  }

  if ($payload) {
    $response = curl -sS -X $verb "$server/$partialPath" -H "accept: application/json" -H "X-Octopus-ApiKey: $apiKey" -w "\n%{http_code}\n" -d $payload
  }
  else {
    $response = curl -sS -X $verb "$server/$partialPath" -H "accept: application/json" -H "X-Octopus-ApiKey: $apiKey" -w "\n%{http_code}\n"
  }

  # Last line will be http_code
  $status = @($response)[-1]
  $body = $null
  if ($status -eq "200" -or $status -eq "201") {
    # All lines but the last one is our json
    $body = $response[0..$($response.length - 2)] -join "`n"
  }

  [pscustomobject]@{status = $status; body = $body; response = $response }

}

function OctopusJson {
  $result = OctopusRest @args
  [pscustomobject]@{status = $result.status; json = $result.body ? ($result.body | ConvertFrom-Json) : $null; response = $result.response }
}

# This runs OctopusJson, expects a particular status code and produces a error if a different status code returned. Returns the json object
function OctopusExpect {
  param(
    [string]$expectedStatus,
    [string]$partialPath,
    [string]$verb,
    [string]$payload
  )

  $result = OctopusJson $partialPath $verb $payload
  if ($result.status -ne $expectedStatus) {
    Write-Error "Octopus REST call failed, expected status '$expectedStatus'`n$($result.response -join "`n")"
    return
  }
  $result.json
}

# This runs OctopusJson, expects 200 and produces a error if not 200. Returns the json object
function OctopusExpect200 {
  param(
    [string]$partialPath,
    [string]$verb,
    [string]$payload
  )

  OctopusExpect "200" $partialPath $verb $payload
}

function getAllSensitiveVars {
  $projects = OctopusExpect200 "api/projects/?skip=0&take=2147483647"
  $projects.Items | Where-Object {
    # "TestBed", "Wip API", "To Decomission"
    @("ProjectGroups-63","ProjectGroups-301","ProjectGroups-201")  -notcontains $_.ProjectGroupId
  } | ForEach-Object{
    $projectName =  $_.Name
    $vs = OctopusExpect200 $_.Links.Variables.TrimStart("/")
    $vs.Variables | Where-Object{ $_.IsSensitive } | ForEach-Object{
      [pscustomobject]@{type = "Project"; name = $projectName; var = $_.Name}
    }
  } | Select-Object * -Unique

  $lvs = OctopusExpect200 "api/LibraryVariableSets?skip=0&take=2147483647"
  $lvs.Items | Where-Object {
    # "Vault"
    @("LibraryVariableSets-166")  -notcontains $_.Id
  } | ForEach-Object{
    $varSetName =  $_.Name
    $vs = OctopusExpect200 $_.Links.Variables.TrimStart("/")
    $vs.Variables | Where-Object{ $_.IsSensitive } | ForEach-Object{
      [pscustomobject]@{type = "Library Set"; name = $varSetName; var = $_.Name}
    }
  } | Select-Object * -Unique
}

getAllSensitiveVars | Export-Csv $varFileName
