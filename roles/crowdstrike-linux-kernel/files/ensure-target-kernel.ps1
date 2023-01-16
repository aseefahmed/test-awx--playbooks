#!/usr/bin/env pwsh

$ErrorActionPreference = "Stop"

$env:DEBIAN_FRONTEND="noninteractive"

$target = $env:FALCON_TARGET_KERNEL
Write-Host "Target kernel: $target"

$installed =  apt list --installed | Select-String '^linux-image|^linux-headers' | ForEach-Object {($_ -split '/')[0]}
if ($LASTEXITCODE) { exit $LASTEXITCODE }

function installIfNotInstalled($package) {
  if ($installed -contains $package) {
    Write-Host "$package is already installed"
    return
  }
  apt install $package -y
  if ($LASTEXITCODE) { exit $LASTEXITCODE }
  $global:changed = "changed"
}

installIfNotInstalled "linux-image-$target"
installIfNotInstalled "linux-headers-$target"

# This is lazy: we already held these packages on all our boxes as a band aid to the crowdstrike kernel requirement problem,
# so this undoes that. It is nescessary because otherwise removal of these package will fail. This does not produce a error
# or causes an issue on systems where those are not held. This can be safely removed after this role has been applied to 
# the entire fleet. It would be cleaner to run the unhold in a separate playbook, same as hold was done, but this seems simpler
apt-mark unhold linux-headers-generic linux-image-generic
if ($LASTEXITCODE) { exit $LASTEXITCODE }

# This is required because otherwise uninstalling active linux kernel fails
# see https://unix.stackexchange.com/questions/398485/error-deleting-older-kernel-package
$env:DEBIAN_FRONTEND='noninteractive'

# When we run the removal for the first time for reasons unknown another "unsigned" kernel gets installed
# presumably to replace currently used kernel. So we run this twice, to remove that kernell too
1..2 | ForEach-Object {
  $installed =  apt list --installed | Select-String '^linux-image|^linux-headers' | ForEach-Object {($_ -split '/')[0]}
  $installed | ForEach-Object {
    if ($_ -ne "linux-image-$target" -and $_ -ne "linux-headers-$target") {
      apt remove $_ -y
      if ($LASTEXITCODE) { exit $LASTEXITCODE }
      $global:changed = "changed"
    }
  }
}

apt autoremove -y

# This is to signal ansible if any changes were made so it knows whether to reboot
$changed
