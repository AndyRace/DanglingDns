# TODO: False positives (e.g. CNAMES that genuinely point to another tenant)

[cmdletbinding(DefaultParameterSetName = 'Parameter Set 0')]
param
(   
    # Control whether or not to use the DynDns APIs to get all the DNS CNAME records
    # See: https://help.dyn.com/dns-api-knowledge-base/
    [parameter(Mandatory = $false)]
    [bool]$UseDynDns = $true
)

$VerbosePreference = "SilentlyContinue"
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
Set-PSDebug -Strict

Set-Location $PSScriptRoot

# Generated files live here
$OutputFileLocation = (Join-Path $PSScriptRoot 'Output')
New-Item $OutputFileLocation -ItemType Directory -Force | Out-Null

# All relevant DNS records from Dyn Dns
# "CNAME","FQDN"
$DynDnsFilename = 'DynDnsRecords.csv'

# Zone data provided by Dyn Dns
# Node,Record Data
$AllZoneRecords = 'allZoneRecords.csv'

# All cnames that referred to Azure but were NOT found by this user in the subscriptions they have access to
$AzureCNameMissingResources = (Join-Path $OutputFileLocation 'AzureCNameMissingResources.csv')
# The above, with the names resolved.
# If they're missing AND resolve they could be inaccessible to this user, being hosted in another tenant OR have been compromised 
$AzureCNameMissingResourcesResolved = (Join-Path $OutputFileLocation 'AzureCNameMissingResourcesResolved.csv')

# Import all the modules for this
Get-ChildItem -Path (Join-Path $PSScriptRoot 'Modules' "*.psm1") | ForEach-Object { Import-Module $_  -Force }

# All DNS records
$inputFileDnsRecords = (Join-Path $OutputFileLocation 'DnsRecords.csv')

# Create csv ($inputFileDnsRecords) with the columns "cname","fqdn"
. {if ($UseDynDns) {
    # Credentials are managed using https://devblogs.microsoft.com/powershell/secretmanagement-preview-3/
    # Use this to initialise the secrets: New-DynDnsSecretStore
    $details = Get-DynDnsCredentials

    # todo: filter the records
    # Output: fqdn, cname, zone
    Get-DynDnsCnameRecords -CustomerName $details.CustomerName -Credentials $details.Credentials
        | Export-Csv $DynDnsFilename
    
    Import-Csv -Path $DynDnsFilename -Header 'Node', 'Record'
        | Select-Object -Skip 1
} else {
    Import-Csv -Path $AllZoneRecords -Header 'Node', 'Record'
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
Import-Csv $AzureCNameMissingResources
    | Add-ResolveDnsMember
    | Where-Object { $_.ResolvedDns -ne $null } 
    | Select-Object -ExpandProperty ResolvedDns -Property *
    | Select-Object -Property CNAME, FQDN, Name, Server, NameHost, QueryType
    | Export-Csv $AzureCNameMissingResourcesResolved -NoTypeInformation -Force