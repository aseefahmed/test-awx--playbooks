#!/usr/bin/env pwsh

# This scripts needs to be copied and pasted in the "Inventory Scripts" section of awx
# It will not run well on PowerShell 5, do not try it, you need PowerShell Core
# And updated at https://github.com/BarfootThompson/devops-notes/blob/master/inventories/main.ps1

$workFolder = "/runner/data/"
$ErrorActionPreference = "Stop"
$vSphereServer = "192.168.200.85"
$vSphereDC = "DC01","DC02"
$cacheFile = $workFolder + "vsphere.cache"
$debug = $false
if ($debug) { $host.ui.WriteErrorLine((get-date -F "HH:mm:ss") + " Started")  }

# This is how you add additional host vars to the inventory
$additionalHosvars = @{
  "test-scapi1.barfoot.dmz" = @{
    website_host_header = "certtest.barfoot.co.nz";
    website_name = "certtest";
    website_port =  443;
    website_sslFlag = 0;
  };
  "192.168.200.101" = @{
    f5_server = "192.168.200.101";
    f5_user = "{{ f5_production_admin_username }}";
    f5_password =  "{{ f5_production_admin_password }}";
    ansible_host =  "127.0.0.1";
    ansible_connection = "local";
  };
  "192.168.200.104" = @{
    f5_server =  "192.168.200.104";
    f5_user =  "{{ f5_staging_admin_username }}";
    f5_password = "{{ f5_staging_admin_password }}";
    ansible_host =  "127.0.0.1";
    ansible_connection =  "local";
  };
} 

# Only powered on machines

# win - Windows 2012 Server or newer (by guest id)
# ubuntu - ubuntu (by guest id)
# linux - currently linux and ubuntu is exactly the them as we do not have any other types of linux we manage in ansible

# F5 - 192.168.200.101, 192.168.200.104 (note, these are not VMs)

# production - on those networks: "Admin Network", "DMZ", "DMZ Back End", "Infrastructure" (only in win or linux or F5)
# staging - on those networks: "Dev", "Stage-Admin", "Stage-DMZ", "Stage-DMZ-BACKEND", "Staging-Identity" (only in win or linux or F5)
# identity - on those networks: "Identity","Staging-Identity" (only in win or linux or F5)

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

function EnsureBarfootDomain {
param(
    [string]$name,
    [string]$network
  )
  if ($name -like "*.*") {
    $name
  }  else {
    "$($name).barfoot.co.nz"
  }
}

if (!(Test-Path $cacheFile)) {
  $parent = Split-Path $cacheFile
  if ($parent) {
    if (!(Test-Path $parent)) {
      $null = New-Item $parent
    }
  }
}

if ($debug) { $host.ui.WriteErrorLine((get-date -F "HH:mm:ss") + " Configured")  }

$server = Connect-VIServer -Server $vSphereServer -Password $env:VMWARE_PASSWORD -User $env:VMWARE_USER
if ($debug) { $host.ui.WriteErrorLine((get-date -F "HH:mm:ss") + " Connected to vSphere")  }

$nsStaging = "Dev", "Stage-Admin", "Stage-DMZ", "Stage-DMZ-BACKEND", "Staging-Identity"
$nsProduction = "Admin Network", "DMZ", "DMZ Back End", "Infrastructure"
$nsIdentity = "Identity","Staging-Identity"
$suffixes = ".barfoot.co.nz", ".barfoot.dmz", ".barfoot.id"
$suffixPattern = ($suffixes | ForEach-Object { [regex]::Escape($_) }) -join '|'

$cache = @()
if (Test-Path $cacheFile) {
  $cache = Import-Clixml $cacheFile
  if ($debug) { $host.ui.WriteErrorLine((get-date -F "HH:mm:ss") + " Cache read")  }
}

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

$lookup = @{}
$vms | %{ $lookup.Add($_.Name, $_) }

$vmData = ($cache | ?{ $lookup[$_.name] } | ?{ $nsStaging -contains $_.networkname -or $nsProduction -contains $_.networkname -or $nsIdentity -contains $_.networkname }) | ?{ 
  ((("windows8Server64Guest", "windows9Server64Guest" -contains $_.guestId) -and 
    ($_.hostname -match $suffixpattern))  -or
  ("ubuntu64Guest" -eq $_.guestId))
}
if ($debug) { $host.ui.WriteErrorLine((get-date -F "HH:mm:ss") + " VM Data filtered")  }

$vmData | ?{ !$_.hostname} | %{
	if ($debug) { $host.ui.WriteErrorLine((get-date -F "HH:mm:ss") + " $($_.name) does not have hostname")  }
}
$vmData = $vmData | ?{ $_.hostname}

$hostvars = @()

$win = $vmData | ?{ ("windows8Server64Guest", "windows9Server64Guest" -contains $_.guestId) } | %{ $_.hostname } | sort
$hostvars = @($hostvars) + @($vmData | ?{ ("windows8Server64Guest", "windows9Server64Guest" -contains $_.guestId) } | %{  @{ hostname = $_.hostname; vmname = $_.name } })
$linux = $vmData | ?{ ("ubuntu64Guest" -eq $_.guestId) } | %{ EnsureBarfootDomain $_.hostname $_.networkname } | sort
$hostvars = @($hostvars) + @($vmData | ?{ ("ubuntu64Guest" -eq $_.guestId) } | %{  @{ hostname = EnsureBarfootDomain $_.hostname $_.networkname; vmname = $_.name } })
$ubuntu = $linux | sort

$d = @{}
$hostvars | %{ $hostname = $_["hostname"]; $d."$hostname" = @{vmname = $_["vmname"]}}
$hostvars = $d

$additionalHosvars.Keys | %{
 $hostvars[$_] += $additionalHosvars[$_]
}

$F5 = "192.168.200.101","192.168.200.104"  | sort

$production = $vmData | ?{ compare-object $nsProduction $_.networkname -i -e } | %{ EnsureBarfootDomain $_.hostname $_.networkname }
$production = @($production) + "192.168.200.101" | sort

# This is how you add external hosts to required groups
$production = @($production) + "p-db-apiclu1.barfoot.dmz" | sort
$win = @($win) + "p-db-apiclu1.barfoot.dmz" | sort

$production = @($production) + "p-db-apiclu2.barfoot.dmz" | sort
$win = @($win) + "p-db-apiclu2.barfoot.dmz" | sort

$production = @($production) + "p-db-dr-apisql-01.barfoot.dmz" | sort
$win = @($win) + "p-db-dr-apisql-01.barfoot.dmz" | sort

$staging = $vmData | ?{ compare-object $nsStaging $_.networkname -i -e } | %{ EnsureBarfootDomain $_.hostname $_.networkname }
$staging = @($staging) + "192.168.200.104" | sort

$identity = $vmData | ?{ compare-object $nsIdentity $_.networkname -i -e } | %{ EnsureBarfootDomain $_.hostname $_.networkname } | sort

$customGroupNames = $vmData.customFields.key | select -unique

$customGroups = @{}
$customGroupNames | ?{
  $name = $_
  $group = $vmData | ?{($_.customFields | ?{ $_.Key -eq $name -and $_.Value -eq "True"}).Count -gt 0 } | %{ EnsureBarfootDomain $_.hostname $_.networkname } | sort
  $customGroups[$name] = $group
}


# This is how you apply custom attributes to external hosts
$customGroups["Btstarcert"] = @($customGroups["Btstarcert"]) + @("192.168.200.101","192.168.200.104") | sort

if ($debug) { $host.ui.WriteErrorLine((get-date -F "HH:mm:ss") + " Groups formed")  }

$json = @{
  _meta = @{ hostvars = $hostvars};
  all = @{
    children = @(
      "ungrouped",
      "F5",
      "linux",
      "production",
      "staging",
      "identity",
      "ubuntu",
      "win"
    )
  };
  F5 = @{ hosts = $F5 };
  win = @{ hosts = $win };
  linux = @{ hosts = $linux };
  ubuntu = @{ hosts = $ubuntu };
  production = @{ hosts = $production };
  staging = @{ hosts = $staging };
  identity = @{ hosts = $identity };
} 
$customGroups.Keys | %{
  $name = $_.ToLower()
  $json.all.children = @($json.all.children) + @($name)
  $json[$name] = @{ hosts = @($customGroups[$_]).where({$_}) }
}
if ($debug) { $host.ui.WriteErrorLine((get-date -F "HH:mm:ss") + " Json created")  }

$json | ConvertTo-Json -Depth 100
if ($debug) { $host.ui.WriteErrorLine((get-date -F "HH:mm:ss") + " Done")  }

$json | ConvertTo-Json -Depth 100 | Set-Content ($workFolder + "main-inventory-debug.json")
