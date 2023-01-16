#!/usr/bin/env pwsh

$ErrorActionPreference = "Stop"

$githubToken = Get-Content (Join-Path $PSScriptRoot githubToken.txt) -ErrorAction SilentlyContinue
#$env:debug_curl = "True"

$data = @(
 @{
    Command = "kubectx"
    Repository = "ahmetb/kubectx"
    Pattern = "^kubectx_v%version%+_linux_x86_64\.tar\.gz$"
    TargetFolder = "/opt/kubectx/%version%"
    LinkFolder = "/usr/local/bin"
    Token = $githubToken
  },
 @{
    Command = "kubens"
    Repository = "ahmetb/kubectx"
    Pattern = "^kubens_v%version%+_linux_x86_64\.tar\.gz$"
    TargetFolder = "/opt/kubens/%version%"
    LinkFolder = "/usr/local/bin"
    Token = $githubToken
  },
 @{
    Command = "stern"
    Repository = "stern/stern"
    Pattern = "^stern_%version%_linux_amd64\.tar\.gz$"
    TargetFolder = "/opt/stern/%version%"
    LinkFolder = "/usr/local/bin"
    Token = $githubToken
  },
 @{
    Command = "oh-my-posh"
    Repository = "JanDeDobbeleer/oh-my-posh"
    Pattern = "^posh-linux-amd64$"
    TargetFolder = "/opt/oh-my-posh/%version%"
    LinkFolder = "/usr/local/bin"
    Token = $githubToken
    ConfirmRawExecutable = $True
  },
 @{
    Command = "fzf"
    Repository = "junegunn/fzf"
    Pattern = "^fzf-%version%-linux_amd64\.tar\.gz$"
    TargetFolder = "/opt/fzf/%version%"
    LinkFolder = "/usr/local/bin"
    Token = $githubToken
    VersionTransform = "version_transform_equal"
  },
 @{
    Command = "glow"
    Repository = "charmbracelet/glow"
    Pattern = "^glow_%version%_linux_x86_64\.tar\.gz$"
    TargetFolder = "/opt/glow/%version%"
    LinkFolder = "/usr/local/bin"
    Token = $githubToken
  },
 @{
    Command = "bat"
    Repository = "sharkdp/bat"
    Pattern = "^bat-v%version%-x86_64-unknown-linux-gnu\.tar\.gz$"
    TargetFolder = "/opt/bat/%version%"
    LinkFolder = "/usr/local/bin"
    Token = $githubToken
    StripComponents = 1
  },
 @{
    Command = "lazygit"
    Repository = "jesseduffield/lazygit"
    Pattern = "^lazygit_%version%_Linux_x86_64\.tar\.gz$"
    TargetFolder = "/opt/lazygit/%version%"
    LinkFolder = "/usr/local/bin"
    Token = $githubToken
  }
)

chmod 600 (Join-Path $PSScriptRoot devops.key)
if ($LASTEXITCODE) { exit $LASTEXITCODE }

$env:GIT_SSH_COMMAND="ssh -i $(Join-Path $PSScriptRoot devops.key) -o IdentitiesOnly=yes -o 'StrictHostKeyChecking no'"

git clone git@github.com:BarfootThompson/DevOps.git "$env:HOME/DevOps"
if ($LASTEXITCODE) { exit $LASTEXITCODE }

Import-Module -Name "$env:HOME/DevOps/Andrew/InstallFromGithub"

$data | &{ process {
 Write-Host "Installing $($_.Command)..."
 Install-GitHubBinaryRelease @_ -InformationAction Continue
}}
