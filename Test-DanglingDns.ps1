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

if (!$SHORTCUT) {
    $inputFileDnsRecords = (Join-Path $OutputFileLocation 'DnsRecords.csv')

    # Convert the zone file provided by Oracle into a CSV file for use below
    $ZoneRecordsFile = (Get-Item 'allZoneRecords.csv' -ErrorAction SilentlyContinue)
    #$inputFileDnsRecordsFile = (Get-Item $inputFileDnsRecords -ErrorAction SilentlyContinue)
    #if (!$ZoneRecordsFile -or !$inputFileDnsRecordsFile -or ($ZoneRecordsFile.LastWriteTimeUtc.CompareTo($inputFileDnsRecordsFile.LastWriteTimeUtc) -gt 0)) {
        Convert-ZoneRecordsToCnameRecords -InputFileDnsRecords $ZoneRecordsFile -OutputFileDnsRecords $inputFileDnsRecords
    #}

    # Based on: https://github.com/Azure/Azure-Network-Security/tree/master/Cross%20Product/Find%20Dangling%20DNS%20Records
    .\Get-DanglingDnsRecords.ps1 -OutputFileLocation $OutputFileLocation -InputFileDnsRecords $inputFileDnsRecords #-CacheAzResourcesInputJsonFilename $CacheAzResourcesInputJsonFilename -FileAndAzureSubscription
}

Import-Csv (Join-Path $OutputFileLocation 'AzureCNameMissingResources.csv') |
    Get-ResolveDnsNameResults |
    Where-Object { $_.ResolvedDns -ne $null } |
    Select-Object -ExpandProperty ResolvedDns |
    Select-Object -Property Name, Server, NameHost, QueryType |
    Export-Csv (Join-Path $OutputFileLocation 'AzureCNameMissingResourcesResolved.csv') -NoTypeInformation -Force