#!/usr/bin/env pwsh

$ErrorActionPreference = "Stop"

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

$conf = Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false
$conf = Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false -Confirm:$false
$conf = Set-PowerCLIConfiguration -DefaultVIServerMode 'Single' -Confirm:$false

$vmhost = $env:VMWARE_HOST
$vmpass = $env:VMWARE_PASSWORD
$vmuser = $env:VMWARE_USER

$server = Connect-VIServer -Server $vmhost -Password $vmpass -User $vmuser

$vms = get-vm | ?{ $_.PowerState -eq "PoweredOn" }
$tags = Get-TagAssignment
$result = $vms | %{
  $vm = $_
  $annotation = $_.notes
  $network = Get-NetworkAdapter $_ | select -First 1 | select -exp NetworkName
  $dc = Get-Datacenter -vm $_ | select -exp Name
  $backup = $tags | ?{ $_.Entity -eq $vm } | Select -exp Tag | ?{ [string]$_.Category -eq "Backups" } | Select -Exp Name
  $ip = $_.Guest.IPAddress | ?{$_ -match '\.'} | select -First 1
  [pscustomobject]@{vm=$vm.name;ip=$ip;dc=$dc;network=$network;backup=$backup;annotation=$annotation}
}
$other = Import-Csv /tmp/assets.csv
$novm = $other | ?{ !$_.vm }
$lookup = @{}
$other.foreach({
  if ($_.vm) {
    $lookup[$_.vm] = $_
  }
})

$part1 = $result | %{
  if ($lookup.ContainsKey($_.vm)) {
    [pscustomobject]@{vm=$_.vm;fqdn=$lookup[$_.vm].fqdn;ip=$_.ip;dc=$_.dc;os=$lookup[$_.vm].os;network=$_.network;backup=$_.backup;kernel=$lookup[$_.vm].kernel;annotation=$_.annotation}
  } else {
    [pscustomobject]@{vm=$_.vm;fqdn="";ip=$_.ip;dc=$_.dc;os="";network=$_.network;backup=$_.backup;kernel="";annotation=$_.annotation}
  }
}

$networks = @{
  "192.168.6.0"   = "Admin Network"
  "192.168.60.0"  = "Stage-Admin"
  "192.168.70.0"  = "Stage-DMZ"
  "192.168.80.0"  = "Stage-DMZ-Backend"
  "10.150.255.0"    = "Dev"
  "192.168.7.0"   = "DMZ"
  "192.168.8.0"   = "DMZ Back End"
  "192.168.11.0"  = "Identity"
  "192.168.110.0" = "Staging-Identity"
  "192.168.16.0"  = "Branch-DMZ"
  "192.168.200.0" = "Infrastructure"
}

$part2 = $novm | %{
  $isIp = "^([1-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])){3}$"
  if ($_.fqdn -match $isIp) {
    $ip = $_.fqdn
  } else {
    $ip = getent hosts $($_.fqdn) | awk '{ print $1 }' | tail -n 1
  }
  $sub = [string][IPAddress](([IPAddress] $ip).Address -band ([IPAddress] "255.255.255.0").Address)
  $network=$networks[$sub]
  [pscustomobject]@{vm="";fqdn=$_.fqdn;ip=$ip;dc="";os=$_.os;network=$network;backup="";annotation=""}
}

@($part1) + @($part2) | Export-Csv /tmp/vminfo.csv
