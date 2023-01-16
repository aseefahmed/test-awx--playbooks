New-Item c:\octomerge -type directory -Force
$Reg='Registry::HKLM\System\CurrentControlSet\Control\Session Manager\Environment';$OldPath=(Get-ItemProperty -Path $Reg -Name PATH).Path;$NewPath=$OldPath+';'+"c:\octomerge";Set-ItemProperty -Path $Reg -Name PATH -Value $NewPath
