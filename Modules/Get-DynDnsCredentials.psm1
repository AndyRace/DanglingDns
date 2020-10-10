$VerbosePreference = "SilentlyContinue"
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
Set-PSDebug -Strict

function Initialize-DynDnsSecrets {
    $SecretVaultName = 'DynDns.SecretStore'

    # Using SecretManagement
    # https://devblogs.microsoft.com/powershell/secretmanagement-preview-3/
    # @('Microsoft.PowerShell.SecretManagement', 'Microsoft.PowerShell.SecretStore') | ForEach-Object {
    #     if (!(Get-Module $_)) {
    #         Install-Module $_ -AllowPrerelease
    #     }
    # }
    if (!(Get-Module 'Microsoft.PowerShell.SecretManagement')) {
        Install-Module 'Microsoft.PowerShell.SecretManagement' -AllowPrerelease
        Install-Module 'Microsoft.PowerShell.SecretStore' -AllowPrerelease
    }

    if (!(Get-SecretVault -Name $SecretVaultName)) {
        Register-SecretVault -Name $SecretVaultName -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault | Out-Null
    }
}

function Get-DynDnsCredentials {
    [CmdletBinding()]
    param (
    )

    Initialize-DynDnsSecrets

    [PSCustomObject]@{
        CustomerName = Get-Secret -Name 'CustomerName' -AsPlainText
        Credentials = Get-Secret -Name 'Credentials'
    }
}

function New-DynDnsCredentials {
    [CmdletBinding()]
    param (
    )
    
    Initialize-DynDnsSecrets

    $CustomerName = Read-Host -Prompt "Customer Name" #-AsSecureString
    Set-Secret -Name 'CustomerName' -Secret $CustomerName

    $cred = Get-Credential -Message "Please enter the DynDns username/password"
    Set-Secret -Name 'Credentials' -Secret $cred
}

Export-ModuleMember -Function New-DynDnsCredentials, Get-DynDnsCredentials