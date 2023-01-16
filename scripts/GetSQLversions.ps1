#Get latest details here https://sqlserverbuilds.blogspot.com/
#Also https://buildnumbers.wordpress.com/sqlserver/

$versions = @{
  8    =@{name="2000"   ;latest="8.00.2305"}
  9    =@{name="2005"   ;latest="9.00.5324"}
  10   =@{name="2008"   ;latest="10.00.6556.0"}
  10.5 =@{name="2008 R2";latest="10.50.6560.0"}
  11   =@{name="2012"   ;latest="11.0.7507.2"}
  12   =@{name="2014"   ;latest="12.0.6439.10"}
  13   =@{name="2016"   ;latest="13.0.7016.1"}
  14   =@{name="2017"   ;latest="14.0.3456.2"}
  15   =@{name="2019"   ;latest="15.0.4261.1"}
  16   =@{name="2022"   ;latest="16.0.1000.6"}
}

function ver($string) {
  [regex]$r = "(?<major>\d+)\.(?<minor>\d+)\.(?<build>\d+)(?:.(?<patch>\d+))?"
  $m = $r.Match($string)
  [int]$major = $m.Groups["major"].value
  [int]$minor = $m.Groups["minor"].value
  [int]$build = $m.Groups["build"].value
  [int]$patch = $m.Groups["patch"].value
  [pscustomobject]@{major=$major;minor=$minor;build=$build;patch=$patch}
}

if((get-itemproperty -ErrorAction SilentlyContinue 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server').InstalledInstances)
{
  $inst = (get-itemproperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server').InstalledInstances
  foreach ($i in $inst)
  {
    $p = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL').$i
    $ed = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$p\Setup").Edition
    $ver = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$p\Setup").PatchLevel

    $verObj = ver $ver
    $index = $verObj.major
    if ($verObj.major -eq 10 -and ([string]($verObj.minor)).startswith("5")) { $index = 10.5 } 
    $reference = $versions[$index]
    $sqlName = "SQL Server $($reference.name)"
    $ver_target = $reference.latest
    $vt = ver $ver_target
    if ($vt.patch -and $verObj.build -eq $vt.build -and $verObj.patch -lt $vt.patch -or $verObj.build -lt $vt.build) {$ver_ok = "Needs update"} else {$ver_ok = "Up-to-date"}
    write-output "$env:computername,$p,$sqlname,$ed,$ver,$ver_ok,$ver_target"
  }
}
