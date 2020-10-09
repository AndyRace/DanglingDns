<#
Azure Front Door            microsoft.network/frontdoors                abc.azurefd.net
Azure Blob Storage          microsoft.storage/storageaccounts           abc.blob.core.windows.net
Azure CDN                   microsoft.cdn/profiles/endpoints            abc.azureedge.net
Public IP addresses         microsoft.network/publicipaddresses         abc.EastUs.cloudapp.azure.com
Azure Traffic Manager       microsoft.network/trafficmanagerprofiles    abc.trafficmanager.net
Azure Container Instance    microsoft.containerinstance/containergroups abc.EastUs.azurecontainer.io
Azure API Management        microsoft.apimanagement/service             abc.azure-api.net
Azure App Service           microsoft.web/sites                         abc.azurewebsites.net
Azure App Service - Slots   microsoft.web/sites/slots                   abc-def.azurewebsites.net
#>

function Convert-ZoneRecordsToCnameRecords {
[cmdletbinding()]
    param
    (   
        [parameter(Mandatory = $true)]
        [string]$InputFileDnsRecords,

        [parameter(Mandatory = $true)]
        [string]$OutputFileDnsRecords
    )

    $ErrorActionPreference = "Stop"

    $interestedAzureDnsZones = "azurefd.net|core.windows.net|azureedge.net|cloudapp.azure.com|trafficmanager.net|azurecontainer.io|azure-api.net|azurewebsites.net|cloudapp.net"

    $domainSuffixPatternMatch = "^CNAME .*\.($interestedAzureDnsZones)\.$"

    Import-Csv -Path $InputFileDnsRecords -Header 'Record', 'Value' | Where-Object { 
            $_.Record -imatch "^(?!awverify\.|cdnverify\.)" -and $_.Value -imatch $domainSuffixPatternMatch
        } | ForEach-Object {
            [pscustomobject]@{CNAME=$_.Record; FQDN=$_.Value.substring(6).TrimEnd('.')}
        } | Export-Csv $OutputFileDnsRecords -IncludeTypeInformation:$false
}

Export-ModuleMember -Function Convert-ZoneRecordsToCnameRecords