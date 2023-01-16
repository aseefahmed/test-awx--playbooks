param (
      [string] $targetFolder,
      [string] $serverUrl
)

curl.exe -sSLO "$serverUrl/update/buildAgentFull.zip"

New-Item $targetFolder -type directory -Force
Expand-Archive buildAgentFull.zip $targetFolder
New-Item "$targetFolder\logs" -type directory -Force

curl.exe -sSLO https://corretto.aws/downloads/latest/amazon-corretto-11-x64-windows-jdk.zip
New-Item "$targetFolder\jre" -type directory -Force
New-Item "$targetFolder\jrestaging" -type directory -Force
Expand-Archive amazon-corretto-11-x64-windows-jdk.zip "$targetFolder\jrestaging"

$jreSource = (Get-ChildItem "$targetFolder\jrestaging")[0].FullName
Copy-Item -Path "$jreSource\*" -Destination "$targetFolder\jre" -Recurse

Remove-Item "$targetFolder\jrestaging" -Recurse

$Reg='Registry::HKLM\System\CurrentControlSet\Control\Session Manager\Environment';$OldPath=(Get-ItemProperty -Path $Reg -Name PATH).Path;$NewPath=$OldPath+';'+"$targetFolder\jre\bin";Set-ItemProperty -Path $Reg -Name PATH -Value $NewPath

cp c:\Windows\Temp\buildAgent.properties "$targetFolder\conf\buildAgent.properties"

cd "$targetFolder\bin"
cmd /c service.install.bat 
cmd /c service.start.bat
