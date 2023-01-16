#!/usr/bin/env pwsh

param(
    [string]$vmname
  )

$ErrorActionPreference = "Stop"
$debug = $false
if ($debug) { $host.ui.WriteErrorLine((get-date -F "HH:mm:ss") + " Started")  }

function Load-Module ($m) {
    if (!(Get-Module | Where-Object {$_.Name -eq $m})){
        if (!(Get-Module -ListAvailable | Where-Object {$_.Name -eq $m})) {
            if (Find-Module -Name $m | Where-Object {$_.Name -eq $m}) {
                $module = Install-Module -Name $m -Force -Scope CurrentUser -AllowClobber
            }
            else {
                exit 1
            }
        }
    }
}

Load-Module "VMware.PowerCLI"
if ($debug) { $host.ui.WriteErrorLine((get-date -F "HH:mm:ss") + " VMware.PowerCLI Loaded")  }

$conf = Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false
$conf = Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false -Confirm:$false
$conf = Set-PowerCLIConfiguration -DefaultVIServerMode 'Single' -Confirm:$false

if ($debug) { $host.ui.WriteErrorLine((get-date -F "HH:mm:ss") + " Configured")  }

$server = Connect-VIServer -Server $env:VMWARE_HOST -Password $env:VMWARE_PASSWORD -User $env:VMWARE_USER
if ($debug) { $host.ui.WriteErrorLine((get-date -F "HH:mm:ss") + " Connected to vSphere")  }

$dss = Get-Vm $vmname | Get-Datastore

if ($dss.Count -ne 1) {
  Write-Warning "Datastore count is not 1, but $($dss.Count). Cannot automatically detect Datastore. `n$dss"
  ""
} else {
  $dss[0].Name
}

(Get-Datacenter -VM $vmname).Name
