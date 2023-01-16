#!/usr/bin/env pwsh

$ErrorActionPreference = "Stop"

# Borrowed from https://github.com/PowerShell/PowerShell/issues/1995#issuecomment-303345059
function Invoke-Native($command) {
    $env:commandlineargumentstring=($args | %{'"'+ ($_ -replace '(\\*)"','$1$1\"' -replace '(\\*)$','$1$1') + '"'}) -join ' ';
    & $command --% %commandlineargumentstring%
}

$response = Invoke-Native curl -fsSL "$env:VAULT_ADDR/v1/auth/approle/login" -X POST -d "{`"role_id`":`"$env:VAULT_ROLE_ID`", `"secret_id`":`"$env:VAULT_SECRET_ID`"}"
if ($LASTEXITCODE) { exit $LASTEXITCODE }
$vault_token = ($response | ConvertFrom-Json).auth.client_token

$response = Invoke-Native curl -fsSL -H "X-Vault-Request: true" -H "X-Vault-Token: $vault_token" "$env:VAULT_ADDR/v1/$env:VAULT_MTA_USERS_MOUNT_POINT/metadata/$env:VAULT_MTA_USERS_PATH_PREFIX`?list=true"
if ($LASTEXITCODE) { exit $LASTEXITCODE }

$passwords = @{}

$fromVault = ($response | ConvertFrom-Json).data.keys | %{
  $response = Invoke-Native curl -fsSL -H "X-Vault-Request: true" -H "X-Vault-Token: $vault_token" "$env:VAULT_ADDR/v1/$env:VAULT_MTA_USERS_MOUNT_POINT/data/$env:VAULT_MTA_USERS_PATH_PREFIX/$([uri]::EscapeDataString($_))"
  if ($LASTEXITCODE) { exit $LASTEXITCODE }
  $data =  ($response | ConvertFrom-Json).data.data
  $passwords[$data.email] = $data.password
  $data.sender | %{ $_ -split "," }
} | ?{ $_ } | %{ $_.Trim() } | select -unique

$fromSasl = gc "$PSScriptRoot/postfix/sasl_passwd" | %{
	$term = ($_ -split " ")[0]
	if ($term -and ($term.ToCharArray() -contains "@")) {
		$term
	}
}

$out = @($fromVault) + @($fromSasl) | %{
  $email = $_.replace(".","\.")
  "/^$email`$/ OK"
}

$out = @($out) + @('/^((?=[A-Z0-9][A-Z0-9@._%+-]{5,253}+$)[A-Z0-9._%+-]{1,64}+@(?:(?=[A-Z0-9-]{1,63}+\.)[A-Z0-9]++(?:-[A-Z0-9]++)*+\.){1,8}+[A-Z]{2,63}+$)/ REJECT Address $1 is invalid or not allowed to send.')
$target = "/mnt/docker/postfix/config/bft-pcre-allowed-senders"

$out | Set-Content $target


$passwords.Keys | %{
	$email = $_
	$password = $passwords[$email]
	$tokens = $email -split '@'
	$user = $tokens[0]
	$domain = $tokens[1]
        $password | docker run -i --rm --name postfix_config -v /mnt/docker/postfix/config:/etc/postfix -v /mnt/docker/postfix/sasl2:/etc/sasl2 registry.barfoot.co.nz/devops/postfix:{{ postfix_tag }} saslpasswd2 -c -p -f /etc/sasl2/sasldb2 -u $domain $user
        if ($LASTEXITCODE) { exit $LASTEXITCODE }
}

docker run -i --rm --name postfix_config -v /mnt/docker/postfix/config:/etc/postfix -v /mnt/docker/postfix/sasl2:/etc/sasl2 registry.barfoot.co.nz/devops/postfix:{{ postfix_tag }} chown -R postfix:postfix /etc/sasl2
if ($LASTEXITCODE) { exit $LASTEXITCODE }
