param(
  [string]$certpass
)

$ErrorActionPreference = "Stop"

Import-Module ServerManager;

$seccertpass = $certpass | ConvertTo-SecureString -AsPlainText -Force
$pfxpath = 'C:\Temp\from_ansible.pfx'

#check if cert already installed
$newthumb = (Get-PfxData -FilePath $pfxpath -Password $seccertpass).EndEntityCertificates.Thumbprint
Write-Host "Checking if certificate already installed"
If((Get-ChildItem cert:\LocalMachine\My | ? {$_.Thumbprint -eq $newthumb}).length -le 0){
    Write-Host "Installing new certificate"
    Get-ChildItem -Path $pfxpath | Import-PfxCertificate -CertStoreLocation Cert:\LocalMachine\My -Password $seccertpass
    #Only required for untrusted certificates --> Get-ChildItem -Path $pfxpath | Import-PfxCertificate -CertStoreLocation Cert:\LocalMachine\Root
} else {Write-Host "Certificate already installed"}

#Update IIS Bindings
if ((Get-WindowsFeature Web-Server).Installed) {
    Add-WindowsFeature Web-Scripting-Tools
    Import-Module WebAdministration
    $sites = Get-Website
    $cert = Get-ChildItem cert:\LocalMachine\My | ?{$_.Thumbprint -eq $newthumb}
    foreach($site in $sites){
        $bindings = $site.bindings.Collection | ? {$_.protocol -eq 'https'}
        $bindings
        foreach($binding in $bindings){
                if($binding.bindingInformation.Split(':')[0] -eq '*'){
                    $bindip = '0.0.0.0'
                }else{$bindip = $binding.bindingInformation.Split(':')[0]}

                $bindport = $binding.bindingInformation.Split(':')[1]
                $sslbindingpath = "IIS:\SslBindings\" + $bindip + "!" + $bindport

                If(test-path -Path $sslbindingpath){
                    $sslbindingpathfull = Get-ChildItem -Path $sslbindingpath
                    If($sslbindingpathfull.Thumbprint -ne $newthumb){
                        Write-Host "Updating SSL binding"
                        Remove-Item $sslbindingpath
                        New-Item $sslbindingpath -Value $cert | out-null
                    }else{write-host "Binding OK"}
                }elseif((test-path -Path $sslbindingpath) -eq $False){
                    Write-Host "Adding SSL binding"
                    New-Item $sslbindingpath -Value $cert | out-null
                }else{write-host "Binding OK"}
        }
    }
}

#Update SSRS Bindings
$ssrsServerName = hostname
$wmiName = (Get-WmiObject -namespace root\Microsoft\SqlServer\ReportServer -class __Namespace -ea SilentlyContinue | ? {$_.PSComputerName -eq $ssrsServerName}).Name
if($wmiName){
    write-host "Checking SSRS"
    $version = (Get-WmiObject -namespace root\Microsoft\SqlServer\ReportServer\$wmiName  -class __Namespace).Name
    $ssrsServerName
    $rsConfig = Get-WmiObject -namespace "root\Microsoft\SqlServer\ReportServer\$wmiName\$version\Admin" -class MSReportServer_ConfigurationSetting
    $rs = $rsConfig.ListSSLCertificateBindings(1033)

    foreach($r in $rs){
        $apps = ($r.Application.Count)
        $cnt = 0
        if($apps -gt 0){
            do{
                if($r.certificatehash[$cnt] -ne $newthumb){
                    write-host 'Updating SSL bindings'
                    $rsConfig.RemoveSSLCertificateBindings($r.Application[$cnt], $r.CertificateHash[$cnt], $r.IPAddress[$cnt], $r.Port[$cnt], 1033)
                    $rsConfig.CreateSSLCertificateBinding($r.Application[$cnt], $newthumb.ToLower(), $r.IPAddress[$cnt], $r.Port[$cnt], 1033)
                }
                $cnt = $cnt + 1
            }while($cnt -lt $apps)
        }
    }
}

#Update Octopus bindings
if(((gp HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*).DisplayName -Match "Octopus Deploy Server").Length -gt 0){
    Write-Host "OD"
    start-process "C:\Program Files\Octopus Deploy\Octopus\octopus.server" -argumentlist "ssl-certificate --thumbprint=$newthumb --certificate-store=My" -Verb Runas -wait
}

#Update Seq bindings
if(((gp HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*).DisplayName -Match "Seq").Length -gt 0){
    Write-Host "Seq"
    start-process "seq" -argumentlist "bind-ssl --thumbprint=$newthumb" -Verb Runas -wait
}

#Remove old certificates
Write-host 'Removing old certificates'
Get-ChildItem cert:\LocalMachine\My | ? {$_.subject -like '*.barfoot.co.nz*' -and $_.Thumbprint -ne $newthumb} | Remove-Item
