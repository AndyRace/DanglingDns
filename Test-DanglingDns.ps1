# TODO: False positives (e.g. CNAMES that genuinely point to another tenant)

$SHORTCUT = $false

$VerbosePreference = "SilentlyContinue"
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
Set-PSDebug -Strict

Set-Location $PSScriptRoot

Get-ChildItem -Path (Join-Path $PSScriptRoot 'Modules' "*.psm1") | ForEach-Object { Import-Module $_  -Force }

$OutputFileLocation = (Join-Path $pwd 'Output')
New-Item $OutputFileLocation -ItemType Directory -Force | Out-Null

$inputFileDnsRecords = (Join-Path $OutputFileLocation 'DnsRecords.csv')

# Create csv ($inputFileDnsRecords) with the columns "cname","fqdn"
. {if ($true) {
    # Get the zone records from our name servers
    # See: https://help.dyn.com/dns-api-knowledge-base/

    if (!$SHORTCUT) {
        # Credentials are managed using https://devblogs.microsoft.com/powershell/secretmanagement-preview-3/
        # Use this to initialise the secrets: New-DynDnsSecretStore
        $details = Get-DynDnsCredentials

        # todo: filter the records
        # Output: fqdn, cname, zone
        Get-DynDnsCnameRecords -CustomerName $details.CustomerName -Credentials $details.Credentials
            | Export-Csv 'DynDnsRecords.csv'
    }
    
    Import-Csv -Path 'DynDnsRecords.csv' -Header 'Node', 'Record'
        | Select-Object -Skip 1
} else {
    Import-Csv -Path 'allZoneRecords.csv' -Header 'Node', 'Record'
        | Select-Object -Skip 1
}}
    # Convert the zone file provided by Oracle into a CSV file for use below
    # Input Node, Record
    # Output: CNAME, FQDN
    | Convert-ZoneRecordsToCnameRecords
    | Sort-Object -Property FQDN
    | Export-Csv $inputFileDnsRecords -IncludeTypeInformation:$false


# Based on: https://github.com/Azure/Azure-Network-Security/tree/master/Cross%20Product/Find%20Dangling%20DNS%20Records
.\Get-DanglingDnsRecords.ps1 -InputFileDnsRecords $inputFileDnsRecords -OutputFileLocation $OutputFileLocation #-CacheAzResourcesInputJsonFilename $CacheAzResourcesInputJsonFilename -FileAndAzureSubscription

# Decorate the missing resources with any resolved hostname details
Import-Csv (Join-Path $OutputFileLocation 'AzureCNameMissingResources.csv')
    | Add-ResolveDnsMember
    | Where-Object { $_.ResolvedDns -ne $null } 
    | Select-Object -ExpandProperty ResolvedDns -Property *
    | Select-Object -Property CNAME, FQDN, Name, Server, NameHost, QueryType
    | Export-Csv (Join-Path $OutputFileLocation 'AzureCNameMissingResourcesResolved.csv') -NoTypeInformation -Force