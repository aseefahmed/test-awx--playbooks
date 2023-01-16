param(
     [Parameter(Mandatory)]
     [string]$URL,
 
     [Parameter(Mandatory)]
     [string]$Token,
 
     [Parameter(Mandatory)]
     [string]$ADUsername,
 
     [Parameter(Mandatory)]
     [string]$ADPass
 )

 write-host "PSVersion" $psversiontable.psversion

 $ADPassSecure = ConvertTo-SecureString -String $ADPass -AsPlainText -Force

 $Global:BTCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ADUsername, $ADPassSecure  
 $Global:snipeITURL = $URL
 $Global:snipeITToken = $Token
 $Global:pathToSentDeletedUserIDList = "SentDeletedUserIDList.data"


 #$appSettings = @{}
 #$json = Get-Content "settings.json"| Out-String
 #(ConvertFrom-Json $json).psobject.properties | ForEach-Object { $appSettings[$_.Name] = $_.Value }
 
 #$Global:snipeITURL = $appSettings.URL
 #$Global:snipeITToken = $appSettings.token

 <#
$code= @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
public bool CheckValidationResult(ServicePoint srvPoint, X509Certificate certificate, WebRequest request, int certificateProblem) {
    return true;
}
}
"@

Add-Type -AssemblyName System.Web
Add-Type -TypeDefinition $code -Language CSharp
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
#>
#Use this to get users from AD in .csv file. Helpful for testing.
<# 

Get-ADUser -Filter 'Enabled -eq "true"' -SearchBase "OU=Managed,DC=barfoot,DC=co,DC=nz" -Properties givenName, sn,
 sAMAccountName, mail, employeeID, Title, department, physicalDeliveryOfficeName, telephoneNumber | Select-Object 
 givenName,sn,sAMAccountName,mail,employeeID,Title,department,physicalDeliveryOfficeName,telephoneNumber | Export-CSV "C:\\ADusers.csv" -NoTypeInformation 

#>
Function Get-SnipeITUsers 
{
    [CmdletBinding()] param (
    [Parameter()] [System.Collections.Generic.List[Department]] $snipeITDepartmentList,
    [Parameter()] [System.Collections.Generic.List[Location]] $snipeITLocationList
    )

    $output = [System.Collections.Generic.List[User]]@()

    $headers = @{ 
        "Authorization" = "Bearer $($Global:snipeITToken)"
        "accept" = "application/json"
    }

    $pagesToDownload = 1
    for( $i = 0; $i -lt $pagesToDownload * 500; $i += 500 )
    {
        try 
        {
        $results = Invoke-WebRequest  -Uri "$($Global:snipeITURL)/api/v1/users?offset=$i" `
                                -Headers $headers `
                                -Method Get `
                                -UseBasicParsing
        }
        catch 
        {
            Write-Host ("[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date) + $_)
            exit 1
        }
        Start-Sleep -Seconds 0.6
        $RawUsers = $results.Content | ConvertFrom-Json
        
        foreach($RawUser in $RawUsers.rows)
        {
            $department =  $snipeITDepartmentList | Where-Object {$_.ID -eq $RawUser.department.id}
            $location =  $snipeITLocationList | Where-Object {$_.ID -eq $RawUser.location.id}
            
            if (($null -ne $RawUser.employee_num -and "" -ne $RawUser.employee_num))
            {
                $output.Add([User]::New($RawUser.ID, $RawUser.first_name, $RawUser.last_name, $RawUser.username, $RawUser.email, $RawUser.employee_num,
                $RawUser.jobtitle, $null, $department, $location, $RawUser.phone, $RawUser.licenses_count, $RawUser.assets_count, $RawUser.Remote ))
            }
        }

        if ($pagesToDownload -eq 1)
        {
            $totalUsers = [int]$RawUsers.total
            $pagesToDownload = [math]::floor($totalUsers / 500 + 1)
        }
    }
    
    Write-Host ("[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date) + " Received $($output.Count) users from Snipe-IT")
    return $output

}
Function Get-ADUsers
{
    [CmdletBinding()] param (
    [Parameter()] [System.Collections.Generic.List[Department]] $snipeITDepartmentList,
    [Parameter()] [System.Collections.Generic.List[Location]] $snipeITLocationList
    )

    #$RawUsersFromAD = Import-CSV "ADUsers.csv" -delimiter ","
    try 
    {
        $RawUsersFromAD = Get-ADUser -Credential $Global:BTCredential -Filter 'Enabled -eq "true"' -SearchBase "OU=Managed,DC=barfoot,DC=co,DC=nz" -Properties givenName, sn, sAMAccountName, mail, employeeID, Title, department, physicalDeliveryOfficeName, telephoneNumber
    }
    catch 
    {
        Write-Host ("[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date) + $_)
        exit 1
    }
    

    $output = [System.Collections.Generic.List[User]]@()

    foreach($RawADUser in $RawUsersFromAD)
    {
        if ($null -eq $RawADUser.physicalDeliveryOfficeName -or $null -eq $RawADUser.mail -or 
        $null -eq $RawADUser.sn -or $null -eq $RawADUser.employeeID -or $null -eq $RawADUser.givenName -or 
        $RawADUser.physicalDeliveryOfficeName -eq "" -or $RawADUser.mail -eq "" -or $RawADUser.sn -eq "" -or 
        $RawADUser.employeeID -eq "" -or $RawADUser.givenName -eq "")
        {
            continue
        }

        $department = $null
        if ($null -ne $RawADUser.department -and "" -ne $RawADUser.department)
        {
            $department = $snipeITDepartmentList | Where-Object {$_.Name -eq $RawADUser.department} | Select-Object -First 1

            if ($null -eq $department)
            {
                $headers = @{ 
                    "Authorization" = "Bearer $($Global:snipeITToken)"
                    "accept" = "application/json"
                }
                $body = @{ 
                    "name" = "$($RawADUser.department)"
                }
                try
                {
                $results = Invoke-WebRequest  -Uri "$($Global:snipeITURL)/api/v1/departments" `
                                -Headers $headers `
                                -Method Post `
                                -Body ([System.Text.Encoding]::UTF8.GetBytes($body)) `
                                -UseBasicParsing
                }
                catch 
                {
                    Write-Host ("[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date) + $_)
                    exit 1
                }
                Start-Sleep -Seconds 0.6

                $departmentresults = $results.Content | ConvertFrom-Json
                $department = [Department]::New($($departmentresults.payload.id), $RawADUser.department)
                $snipeITDepartmentList.Add($department)
            }
        }
        $location = $snipeITLocationList | Where-Object {$_.Name -eq $RawADUser.physicalDeliveryOfficeName} | Select-Object -First 1

        if ($null -eq $location)
        {

            $headers = @{ 
                "Authorization" = "Bearer $($Global:snipeITToken)"
                "accept" = "application/json"
            }
            $body = @{ 
                "name" = "$($RawADUser.physicalDeliveryOfficeName)"
            }
            try
            {
            $results = Invoke-WebRequest  -Uri "$($Global:snipeITURL)/api/v1/locations" `
                            -Headers $headers `
                            -Method Post `
                            -Body ([System.Text.Encoding]::UTF8.GetBytes($body)) `
                            -UseBasicParsing
            }
            catch 
            {
                Write-Host ("[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date) + $_)
                exit 1
            }
            Start-Sleep -Seconds 0.6
            
            $locationresults = $results.Content | ConvertFrom-Json
            $location = [Location]::New($($locationresults.payload.id), $RawADUser.physicalDeliveryOfficeName)
            $snipeITLocationList.Add($location)
        
        }

        try {
        $output.Add([User]::New($null,  $RawADUser.givenName, $RawADUser.sn, 
        $RawADUser.sAMAccountName + "@barfoot.co.nz", $RawADUser.mail, $RawADUser.employeeID,
        $RawADUser.Title, $null, $department, $location, $RawADUser.telephoneNumber))
            
    }
    catch {
        Write-Output $_
    }
        
    }
    
    Write-Host ("[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date) + " Received $($output.Count) users from AD")
    return $output
}

Function Get-SnipeITLocations
{
    $headers = @{ 
        "Authorization" = "Bearer $($Global:snipeITToken)"
        "accept" = "application/json"
    }
    $results = Invoke-WebRequest  -Uri "$($Global:snipeITURL)/api/v1/locations" `
                                -Headers $headers `
                                -Method Get `
                                -UseBasicParsing
    Start-Sleep -Seconds 0.6

    $RawLocationList = $results.Content | ConvertFrom-Json
    $output = [System.Collections.Generic.List[Location]]@()

    foreach($RawLocation in $RawLocationList.rows)
    {
        $output.Add([Location]::New($RawLocation.id, $RawLocation.name))
    }

    Write-Host ("[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date) + " Received $($output.Count) Locations from Snipe-IT")
    return $output
}

Function Get-SnipeITDepartments
{
    $headers = @{ 
        "Authorization" = "Bearer $($Global:snipeITToken)"
        "accept" = "application/json"
    }
    try
    {
    $results = Invoke-WebRequest  -Uri "$($Global:snipeITURL)/api/v1/departments" `
                                -Headers $headers `
                                -Method Get `
                                -UseBasicParsing
    }
    catch 
    {
        Write-Host ("[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date) + $_)
        exit 1
    }
    Start-Sleep -Seconds 0.6

    $RawDepartmentList = $results.Content | ConvertFrom-Json
    $output = [System.Collections.Generic.List[Department]]@()

    foreach($RawDepartment in $RawDepartmentList.rows)
    {
        
        $output.Add(([Department]::New($RawDepartment.id, $RawDepartment.name)))
    }

    Write-Host ("[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date) + " Received $($output.Count) Departments from Snipe-IT")
    return $output
}


$departmentsFromSnipeIT = Get-SnipeITDepartments
$locationsFromSnipeIT = Get-SnipeITLocations
$usersFromSnipeIT = Get-SnipeITUsers $departmentsFromSnipeIT $locationsFromSnipeIT
$usersFromAD = Get-ADUsers $departmentsFromSnipeIT $locationsFromSnipeIT

$UserProcessor = [UserProcessor]::New($usersFromSnipeIT, $usersFromAD)

class UserProcessor
{
    [System.Collections.Generic.List[User]]$SnipeITUserList
    [System.Collections.Generic.List[User]]$ADUserList
    [System.Collections.Generic.List[User]]$UpdatedUserList
    [System.Collections.Generic.List[User]]$NewUserList
    [System.Collections.Generic.List[User]]$DeletedUserList

    UserProcessor([System.Collections.Generic.List[User]]$SnipeITUserList, [System.Collections.Generic.List[User]]$ADUserList)
    {
        $this.SnipeITUserList = $SnipeITUserList
        $this.ADUserList = $ADUserList
        $this.ProcessUsers()
        if ($this.UpdatedUserList.Count -gt 0)
        {
            if ($this.UpdateUsers.Count -gt 50)
            {
                Write-Host ("[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date) + "Something's probably wrong. This script is unable to update more than 50 users at a time.")
            }
            else 
            {
                $this.UpdateUsers()
            }
        }
        if ($this.NewUserList.Count -gt 0)
        {
            if ($this.NewUserList.Count -gt 50)
            {
                Write-Host ("[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date) + "Something's probably wrong. This script is unable to add more than 50 users at a time.")
            }
            else 
            {
                $this.NewUsers()
            }
        }
        if ($this.DeletedUserList.Count -gt 0)
        {
            if ($this.DeletedUserList.Count -gt 50)
            {
                Write-Host ("[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date) + "Something's probably wrong. This script is unable to delete more than 50 users at a time.")
            }
            else 
            {
                $this.DeleteUsers()
            }
        }
    }
    
    DeleteUsers()
    {
        # $SentDeletedEmailUserList = $this.GetSentDeletedEmailUserList()

        foreach ($DeletedUser in $this.DeletedUserList)
        {
            # $foundID = $($SentDeletedEmailUserList | Where-Object { $_ -eq $DeletedUser.ID })

            if ($null -ne $DeletedUser.licenses_count -and $DeletedUser.licenses_count -eq "0" -and $null -ne $DeletedUser.assets_count -and
             $DeletedUser.assets_count -eq "0")
             {
<#                 if ($null -ne $foundID)
                {
                    $SentDeletedEmailUserList.Remove($DeletedUser.ID)
                    $this.SetSentDeletedEmailUserList($SentDeletedEmailUserList)
                } #>

                $headers = @{ 
                    "Authorization" = "Bearer $($Global:snipeITToken)"
                    "accept" = "application/json"
                }
    
                $URI = "$($Global:snipeITURL)/api/v1/users/$($DeletedUser.ID)"
                try 
                {
                    $results = Invoke-WebRequest  -Uri $URI `
                                    -Headers $headers `
                                    -Method DELETE `
                                    -ContentType 'application/json' `
                                    -UseBasicParsing
                    Start-Sleep -Seconds 0.6
                }
                catch 
                {
                    Write-Host ("[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date) + $_)
                    exit 1
                }
             }
<#              else 
             {
                if ($null -eq $foundID)
                {
                    Write-Host ("infrastructure@barfoot.co.nz", "User has been terminiated but still has licenses applied. Please reassign licenses. $($DeletedUser.email)")
                    $SentDeletedEmailUserList.Add($DeletedUser.ID)
                    $this.SetSentDeletedEmailUserList($SentDeletedEmailUserList)
                }
             } #>

        }
        
        Write-Host ("[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date) + " Deleted users successfully")
    }

    SendEmail($email, $Message)
    {

    }
    
    UpdateUsers()
    {
        foreach ($UpdatedUser in $this.UpdatedUserList)
        {
            $headers = @{ 
                "Authorization" = "Bearer $($Global:snipeITToken)"
                "accept" = "application/json"
                "content-type" = "application/json"
            }
            $body = $UpdatedUser.getJSONString()

            $URI = "$($Global:snipeITURL)/api/v1/users/$($UpdatedUser.ID)"
            try 
            {
            $results = Invoke-WebRequest  -Uri $URI `
                            -Headers $headers `
                            -Method PATCH `
                            -ContentType 'application/json' `
                            -Body ([System.Text.Encoding]::UTF8.GetBytes($body)) `
                            -UseBasicParsing
            Start-Sleep -Seconds 0.6
            }
            catch 
            {
                Write-Host ("[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date) + $_)
                exit 1
            }
        }
        
        Write-Host ("[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date) + " Updated users successfully")
    }
    
    NewUsers()
    {
        foreach ($NewUser in $this.NewUserList)
        {
            $headers = @{ 
                "Authorization" = "Bearer $($Global:snipeITToken)"
                "Accept" = "application/json"
                "content-type" = "application/json"
            }
            $body = $NewUser.getJSONStringWithRandomPassword()
            try 
            {
            $results = Invoke-WebRequest  -Uri "$($Global:snipeITURL)/api/v1/users" `
                            -Headers $headers `
                            -Method POST `
                            -ContentType 'application/json' `
                            -Body ([System.Text.Encoding]::UTF8.GetBytes($body)) `
                            -UseBasicParsing
            }
            catch 
            {
                Write-Host ("[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date) + $_)
                exit 1
            }
            Start-Sleep -Seconds 0.6
        }
        Write-Host ("[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date) + " Added users successfully")
    }

    

    [System.Collections.Generic.List[string]]GetSentDeletedEmailUserList()
    {
        try {

            if ([System.IO.File]::Exists($Global:pathToSentDeletedUserIDList))
            {
                [string[]]$rawArray = Get-Content -Path $Global:pathToSentDeletedUserIDList
                [System.Collections.Generic.List[string]]$DeletedEmailedUserList = [System.Collections.Generic.List[string]]@($rawArray)
                
            }
            else {
                [System.Collections.Generic.List[string]]$DeletedEmailedUserList = [System.Collections.Generic.List[string]]@()
            }

            return $DeletedEmailedUserList
        }
        catch {
            Add-content "DCLog.log" -value ("[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date) + $_)
            exit 1
            return $null
        }
    }
    
    SetSentDeletedEmailUserList([System.Collections.Generic.List[string]]$SentDeletedEmailUserList)
    {
        try {
            $rawArray = $SentDeletedEmailUserList.ToArray()
            if ($rawArray.Count -lt 1)
            {
                Clear-Content -Path $Global:pathToSentDeletedUserIDList
            }
            else 
            {
                $rawArray | Set-Content -Path $Global:pathToSentDeletedUserIDList
            }
            }
            catch {
                Add-content "DCLog.log" -value ("[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date) + $_)

                exit 1
            }
    }

    hidden ProcessUsers()
    {
        
        $this.UpdatedUserList = [System.Collections.Generic.List[User]]@()
        $this.NewUserList = [System.Collections.Generic.List[User]]@()
        $this.DeletedUserList = [System.Collections.Generic.List[User]]@()
        
        foreach ($ADUser in $this.ADUserList)
        {
            $found = $false
            foreach ($SnipeITUser in $this.SnipeITUserList)
            {
                if ($SnipeITUser.EmployeeNumber -eq $ADUser.EmployeeNumber)
                {
                    $found = $true
                    if ($ADUser.isEqual($SnipeITUser) -eq $false)
                    {
                        $ADUser.ID = $SnipeITUser.ID
                        $this.UpdatedUserList.Add($ADUser)
                    }
                    continue
                }
            }
            if ($found -eq $false)
            {
                $this.NewUserList.Add($ADUser)
                continue
            }
                    
        }

        foreach ($SnipeITUser in $this.SnipeITUserList)
        {
            $user = $this.ADUserList | Where-Object{$_.EmployeeNumber -eq $SnipeITUser.EmployeeNumber }
            if ($null -eq $user)
            {
                $this.DeletedUserList.Add($SnipeITUser)
            }
        }

        
        Write-Host ("[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date) + " Found $($this.UpdatedUserList.Count) users to update")
        Write-Host ("[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date) + " Found $($this.NewUserList.Count) users to add")
        Write-Host ("[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date) + " Found $($this.DeletedUserList.Count) users to delete")
    }


}

class User {
    [string]$ID
    [string]$FirstName
    [string]$LastName
    [string]$Username
    [string]$Email
    [string]$EmployeeNumber
    [string]$Title
    [string]$Manager
    [Department]$Department
    [Location]$Location
    [string]$Phone
    [string]$licenses_count
    [string]$assets_count
    [bool]$Remote
    
    User([string]$ID, [string]$FirstName, [string]$LastName, [string]$Username, [string]$Email, $EmployeeNumber, 
    [string]$Title, [PSCustomObject]$Manager, [Department]$Department, [Location]$Location, [string]$Phone) {
            $this.ID = $ID
            $this.FirstName = [System.Net.WebUtility]::HtmlDecode($FirstName)
            $this.LastName = [System.Net.WebUtility]::HtmlDecode($LastName)
            $this.Username = $Username
            $this.Email = $Email
            $this.EmployeeNumber = $EmployeeNumber
            $this.Title = [System.Net.WebUtility]::HtmlDecode($Title)
            $this.Manager = $null
            $this.Department = $Department
            $this.Location = $Location
            $this.Phone = [System.Net.WebUtility]::HtmlDecode($Phone)
        }

    User([string]$ID, [string]$FirstName, [string]$LastName, [string]$Username, [string]$Email, $EmployeeNumber, 
    [string]$Title, [PSCustomObject]$Manager, [Department]$Department, [Location]$Location, [string]$Phone,
    [string]$licenses_count, [string]$assets_count, [string]$Remote) {
            $this.ID = $ID
            $this.FirstName = [System.Net.WebUtility]::HtmlDecode($FirstName)
            $this.LastName = [System.Net.WebUtility]::HtmlDecode($LastName)
            $this.Username = $Username
            $this.Email = $Email
            $this.EmployeeNumber = $EmployeeNumber
            $this.Title = [System.Net.WebUtility]::HtmlDecode($Title)
            $this.Manager = $null
            $this.Department = $Department
            $this.Location = $Location
            $this.Phone = [System.Net.WebUtility]::HtmlDecode($Phone)
            $this.licenses_count = $licenses_count
            $this.assets_count = $assets_count
            $this.Remote = $Remote
        }

        [bool]isEqual([User]$User)
        {
            if ($User.EmployeeNumber -ne $this.EmployeeNumber -or
                    $User.FirstName -ne $this.FirstName -or
                    $User.LastName -ne $this.LastName -or
                    $User.Username -ne $this.Username -or
                    $User.Email -ne $this.Email -or
                    $User.Title -ne $this.Title -or
                    $User.Manager -ne $this.Manager -or
                    $User.Department -ne $this.Department -or
                    $User.Location -ne $this.Location -or
                    $User.Phone -ne $this.Phone)
                    {
                        return $false
                    }
            return $true
        }

        [string]getJSONString()
        {
            $jsonString = @{
                'first_name' = $this.FirstName
                'last_name' = $this.LastName
                'employee_num' = $this.EmployeeNumber
                'email' = $this.Email
                'username' = $this.Username
                'manager_id' = $null
                'department_id' = $([int]$this.Department.ID)
                'location_id' = $([int]$this.Location.ID)
                'jobtitle' = $this.Title
                'phone' = $this.Phone
              } | ConvertTo-Json
            

            return $jsonString
                
        }

        [string]getJSONStringWithRandomPassword()
        {
            $randomPass = $this.GetRandomPassword(20)
            $jsonString = @{
                'first_name' = $this.FirstName
                'last_name' = $this.LastName
                'username' = $this.Username
                'password' = $randomPass
                'password_confirmation' = $randomPass
                'employee_num' = $this.EmployeeNumber
                'email' = $this.Email
                'manager_id' = $null
                'department_id' = $([int]$this.Department.ID)
                'location_id' = $([int]$this.Location.ID)
                'jobtitle' = $this.Title
                'phone' = $this.Phone
              } | ConvertTo-Json

            return $jsonString
                
        }

        [string]GetRandomPassword([int] $length)
        {
            $charSet = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789{]+-[*=@:)}$^%;(_!&amp;#?>/|.'.ToCharArray()
            #$charSet = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'.ToCharArray()
            $rng = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
            $bytes = New-Object byte[]($length)
         
            $rng.GetBytes($bytes)
         
            $result = New-Object char[]($length)
         
            for ($i = 0 ; $i -lt $length ; $i++) {
                $result[$i] = $charSet[$bytes[$i]%$charSet.Length]
            }
         
            return (-join $result)
        }
    }
    
class Department {
    [string]$ID
    [string]$Name
    
    Department([int]$ID, [string]$Name) {
            $this.ID = $ID
            $this.Name = [System.Net.WebUtility]::HtmlDecode($Name)
        }
    }
    
class Location {
    [string]$ID
    [string]$Name
        
    Location([int]$ID, [string]$Name) {
            $this.ID = $ID
            $this.Name = [System.Net.WebUtility]::HtmlDecode($Name)
        }
    }
