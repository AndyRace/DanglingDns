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

    #List of resource providers
    $resourceProviderList = @(
        [pscustomObject]@{'Service' = 'Azure API Management'; 'DomainSuffix' = 'azure-api.net' },
        [pscustomObject]@{'Service' = 'Azure Container Instance'; 'DomainSuffix' = 'azurecontainer.io' },
        [pscustomObject]@{'Service' = 'Azure CDN'; 'DomainSuffix' = 'azureedge.net' },
        [pscustomObject]@{'Service' = 'Azure Front Door'; 'DomainSuffix' = 'azurefd.net' },
        [pscustomObject]@{'Service' = 'Azure App Service'; 'DomainSuffix' = 'azurewebsites.net' },
        [pscustomObject]@{'Service' = 'Azure Blob Storage'; 'DomainSuffix' = 'blob.core.windows.net' },
        [pscustomObject]@{'Service' = 'Azure Public IP addresses'; 'DomainSuffix' = 'cloudapp.azure.com' },
        [pscustomObject]@{'Service' = 'Azure Classic Cloud'; 'DomainSuffix' = 'cloudapp.net' },
        [pscustomObject]@{'Service' = 'Azure Traffic Manager'; 'DomainSuffix' = 'trafficmanager.net' },
        [pscustomObject]@{'Service' = 'Azure Classic Compute'; 'DomainSuffix' = 'core.windows.net' }
    )

    $allKnownScopes = @(
        # [pscustomObject]@{ Service = 'Azure Active Directory'; DomainSuffix = 'graph.windows.net/*' },
        [pscustomObject]@{ Service = 'SQL Database'; DomainSuffix = 'database.windows.net' },
        [pscustomObject]@{ Service = 'Access Control Service'; DomainSuffix = 'accesscontrol.windows.net' },
        [pscustomObject]@{ Service = 'Service Bus'; DomainSuffix = 'servicebus.windows.net' },
        [pscustomObject]@{ Service = 'File Service'; DomainSuffix = 'file.core.windows.net' },
        [pscustomObject]@{ Service = 'Mobile Services'; DomainSuffix = 'azure-mobile.net' },
        [pscustomObject]@{ Service = 'Media Services'; DomainSuffix = 'origin.mediaservices.windows.net' },
        [pscustomObject]@{ Service = 'Visual Studio Online'; DomainSuffix = 'visualstudio.com' },
        [pscustomObject]@{ Service = 'BizTalk Services'; DomainSuffix = 'biztalk.windows.net' },
        [pscustomObject]@{ Service = 'CDN'; DomainSuffix = 'vo.msecnd.net' },
        [pscustomObject]@{ Service = 'Traffic Manager'; DomainSuffix = 'trafficmanager.net' },
        [pscustomObject]@{ Service = 'Active Directory'; DomainSuffix = 'onmicrosoft.com' },
        [pscustomObject]@{ Service = 'Management Services'; DomainSuffix = 'management.core.windows.net' }
    )

    $interestedAzureDnsZones = ($resourceProviderList + $allKnownScopes).DomainSuffix -join '|'

    $domainSuffixPatternMatch = "^CNAME .*\.($interestedAzureDnsZones)\.$"

    Import-Csv -Path $InputFileDnsRecords -Header 'Record', 'Value' | Where-Object { 
            $_.Record -imatch "^(?!awverify\.|cdnverify\.|selector\d._domainkey)" -and $_.Value -imatch $domainSuffixPatternMatch
        } | ForEach-Object {
            [pscustomobject]@{CNAME=$_.Record; FQDN=$_.Value.substring(6).TrimEnd('.')}
        } | Export-Csv $OutputFileDnsRecords -IncludeTypeInformation:$false
}

Export-ModuleMember -Function Convert-ZoneRecordsToCnameRecords