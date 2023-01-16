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

$vSphereDC = "DC01","DC02"

$topName = "vSphere"
$topImgNum = "41"

$networks = @(
  @{ name ="Dev"; prefix = "10.150.255."; ImgNum="41" }
  @{ name ="Stage-Admin"; prefix = "192.168.60."; ImgNum="41" }
  @{ name ="Stage-DMZ"; prefix = "192.168.70."; ImgNum="41" }
  @{ name ="Stage-DMZ-BACKEND"; prefix = "192.168.80."; ImgNum="41" }
  @{ name ="Staging-Identity"; prefix = "192.168.110."; ImgNum="41" }
  @{ name ="Admin Network"; prefix = "192.168.6."; ImgNum="41" }
  @{ name ="DMZ"; prefix = "192.168.7."; ImgNum="41" }
  @{ name ="DMZ Back End"; prefix = "192.168.8."; ImgNum="41" }
  @{ name ="Infrastructure"; prefix = "192.168.200."; ImgNum="41" }
  @{ name ="Identity"; prefix = "192.168.11."; ImgNum="41" }
  @{ name ="Branch-DMZ"; prefix = "192.168.16."; ImgNum="41" }
)


$linuxUser = "[linux]"
$windowsUser = "[barfoot.co.nz]"
$identiyUser = "[barfoot.id]"
$adminUser = "administrator"

$linuxPattern = "|name|=#109#0%|address|%22%|user|%%-1%-1%%%%%0%0%0%%%-1%0%0%0%%1080%%0%0%1#MobaFont%10%0%0%-1%15%236,236,236%30,30,30%180,180,192%0%-1%0%%xterm%-1%-1%_Std_Colors_0_%80%24%0%1%-1%<none>%%0%0%-1#0# #-1"
$windowsPattern = "|name|=#91#4%|address|%3389%|user|%0%-1%-1%-1%-1%0%0%-1%%%%%0%0%%-1%%-1%-1%0%-1%0%-1#MobaFont%10%0%0%-1%15%236,236,236%30,30,30%180,180,192%0%-1%0%%xterm%-1%-1%_Std_Colors_0_%80%24%0%1%-1%<none>%%0%1%-1#0# #-1"

$ipv6regex = [regex]"(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))"
#$ipv4regex = [regex]"^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"


"Processing..." | Write-Host

$vms = get-vm -Location $vSphereDC | ?{ $_.powerstate -eq "PoweredOn" }
$g = $vms | ForEach-Object {
  $name = $_.Name
  $guestId = $_.ExtensionData.Config.GuestId;
  if ($guestId -like "*win*") { $os = "windows" }
  if (($guestId -like "*linux*") -or ($guestId -like "*centos*") -or ($guestId -like "*ubuntu*")) { $os = "linux" }
  if ($os) {
    $counter = 1
    $_.Guest.Nics | ForEach-Object{
      $network = $_.Device.NetworkName
      if ($network) {
        $_.IPAddress | ForEach-Object{
          if ($counter -eq 1) {$displayCounter=""} else {$displayCounter="($counter)"}
          if ($_ -and !$ipv6regex.IsMatch($_)) {
            [pscustomobject]@{vm=$name;ip=$_;network=$network;counter=$displayCounter;os=$os}
            $counter++
          }
        }
      }
    }
  } else {
    "$name is $guestId, skipping..." | Write-Host
  }
} | Group-Object network


& {
"[Bookmarks]"
"SubRep=$topName"
"ImgNum=$topImgNum"

$bookmarkCount = 1

$g | ForEach-Object {
  $network = $_.name
  $netData = @($networks.where({$_.name -eq $network}))
  if ($netData.Count -eq 1) {
    ""
    "[Bookmarks_$bookmarkCount]"
    "SubRep=$topName\$network ($($netData.prefix)0)"
    "ImgNum=$($netData.ImgNum)"
    $bookmarkCount++
    $_.Group | %{
      if ($_.os -eq "windows") { $user = $windowsUser }
      if ($_.os -eq "linux") { $user = $linuxUser }
      if ($network -eq "Branch-DMZ" -and ($_.os -eq "windows")) { $user = $adminUser }
      if (($network -like "*identity*") -and ($_.os -eq "windows")) { $user = $identiyUser }
      if ($_.os -eq "windows") {
        $windowsPattern.replace("|name|",$_.vm+$_.counter).replace("|address|",$_.ip).replace("|user|",$user)
      }
      if ($_.os -eq "linux") {
        $linuxPattern.replace("|name|",$_.vm+$_.counter).replace("|address|",$_.ip).replace("|user|",$user)
      }       
    }
  } else {
    "$network does not have valid net data specified, skipping..." | Write-Host
  }   
}
} | set-content /tmp/vsphere.mxtsessions
