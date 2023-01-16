#!/usr/bin/env pwsh

param(
    [string]$RefreshToken,
    [string]$ClientID,
    [string]$ClientSecret,
    [string]$Folders,
    [string]$SourceFile,
    [string]$TargetFile,
    [string]$SourceMime,
    [string]$TargetMime
  )

$ErrorActionPreference = "Stop"

$folderIds = $Folders -split ","

# Set the Google Auth parameters. Fill in your RefreshToken, ClientID, and ClientSecret
$params = @{
    Uri = 'https://accounts.google.com/o/oauth2/token'
    Body = @(
        "refresh_token=$RefreshToken", # Replace $RefreshToken with your refresh token
        "client_id=$ClientID",         # Replace $ClientID with your client ID
        "client_secret=$ClientSecret", # Replace $ClientSecret with your client secret
        "grant_type=refresh_token"
    ) -join '&'
    Method = 'Post'
    ContentType = 'application/x-www-form-urlencoded'
}
$accessToken = (Invoke-RestMethod @params).access_token


# Get the source file contents and details, encode in base64
$sourceItem = Get-Item $sourceFile
$sourceBase64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($sourceItem.FullName))

# Set the file metadata
$uploadMetadata = @{
    originalFilename = $sourceItem.Name
    name = $TargetFile
    description = $sourceItem.VersionInfo.FileDescription
    mimeType = $TargetMime
    parents = $folderIds # Include to upload to a specific folder
}

# Set the upload body
$uploadBody = @"
--boundary
Content-Type: application/json; charset=UTF-8

$($uploadMetadata | ConvertTo-Json)

--boundary
Content-Transfer-Encoding: base64
Content-Type: $SourceMime

$sourceBase64
--boundary--
"@

$uploadBody = $uploadBody.Replace("`n","`r`n")
curl -sS "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart" -X POST -H "Authorization: Bearer $accessToken" -H "Content-Type: multipart/related; boundary=boundary" -H "Content-Length: $($uploadBody.Length)" --data-binary $uploadBody
if ($LASTEXITCODE) { exit $LASTEXITCODE }
