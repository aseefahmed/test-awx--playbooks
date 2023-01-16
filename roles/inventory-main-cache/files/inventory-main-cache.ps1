#!/usr/bin/env pwsh

$workFolder = "/runner/data/"
$ErrorActionPreference = "Stop"
$vSphereServer = "192.168.200.85"
$vSphereDC = "DC01","DC02"
$cacheFile = $workFolder + "vsphere.cache"
$debug = $false
if ($debug) { $host.ui.WriteErrorLine((get-date -F "HH:mm:ss") + " Started")  }

if (!(Test-Path $cacheFile)) {
  $parent = Split-Path $cacheFile
  if ($parent) {
    if (!(Test-Path $parent)) {
      $null = New-Item $parent
    }
  }
}

$server = Connect-VIServer -Server $vSphereServer -Password $env:VMWARE_PASSWORD -User $env:VMWARE_USER
if ($debug) { $host.ui.WriteErrorLine((get-date -F "HH:mm:ss") + " Connected to vSphere")  }

$cache = @()

$vms = get-vm -Location $vSphereDC | ?{ $_.powerstate -eq "PoweredOn" }
if ($debug) { $host.ui.WriteErrorLine((get-date -F "HH:mm:ss") + " VM list read")  }

$newVms = $vms | ?{ $cache.name -notcontains $_.name }
if ($debug) { $host.ui.WriteErrorLine((get-date -F "HH:mm:ss") + " New VM filtered; $($newVms.Count) new VMs")  }

$newCache = $newVms |%{
  [pscustomobject]@{
    date = Get-Date;
    name = $_.Name
    guestId = $_.ExtensionData.Config.GuestId;
    hostname = $_.ExtensionData.Guest.hostname
    networkname = ($_|Get-NetworkAdapter).networkname;
    customFields = $_.CustomFields;
  }
}
if ($debug) { $host.ui.WriteErrorLine((get-date -F "HH:mm:ss") + " New data for cache fetched")  }

$cache  = @($cache) + @($newCache)
if ($debug) { $host.ui.WriteErrorLine((get-date -F "HH:mm:ss") + " Cache merged")  }

$tempFile = New-TemporaryFile
$cache | Export-Clixml $tempFile
Move-Item $tempFile $cacheFile -Force
if ($debug) { $host.ui.WriteErrorLine((get-date -F "HH:mm:ss") + " Cache written")  }
