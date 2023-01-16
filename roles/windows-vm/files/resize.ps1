$ErrorActionPreference="Stop"
"Rescanning disks..." | Write-Host
"rescan" | diskpart

Write-Host
"Getting current disk size..." | Write-Host
$currentSize = (Get-Partition –DiskNumber 0 –PartitionNumber 2).Size
"Current disk size: $currentSize" | Write-Host
$maxSize = (Get-PartitionSupportedSize –DiskNumber 0 –PartitionNumber 2).SizeMax
"Max disk size:     $maxSize" | Write-Host
if ($maxSize -gt $currentSize) {
  "Resizing disk..." | Write-Host
  Resize-Partition -DiskNumber 0 –PartitionNumber 2 -Size $maxSize
}
"ExpandDisk.ps1 - Done!" | Write-Host
