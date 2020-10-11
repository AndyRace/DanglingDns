$VerbosePreference = "SilentlyContinue"
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
Set-PSDebug -Strict

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
        [parameter(Mandatory = $true, ValueFromPipelineByPropertyName)]
        [string]$Node,
        [parameter(Mandatory = $true, ValueFromPipelineByPropertyName)]
        [string]$Record
    )

    begin {
        # List of resource providers taken from the Dangling Dns script
        # TODO: Share it between them
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

        $allOtherProviders = @(
            # [pscustomObject]@'{ Service = 'Azure Active Directory'; DomainSuffix = 'graph.windows.net/*' },
            [pscustomObject]@{ 'Service' = 'SQL Database'; DomainSuffix = 'database.windows.net' },
            [pscustomObject]@{ 'Service' = 'Access Control Service'; DomainSuffix = 'accesscontrol.windows.net' },
            [pscustomObject]@{ 'Service' = 'Service Bus'; DomainSuffix = 'servicebus.windows.net' },
            [pscustomObject]@{ 'Service' = 'File Service'; DomainSuffix = 'file.core.windows.net' },
            [pscustomObject]@{ 'Service' = 'Mobile Services'; DomainSuffix = 'azure-mobile.net' },
            [pscustomObject]@{ 'Service' = 'Media Services'; DomainSuffix = 'origin.mediaservices.windows.net' },
            [pscustomObject]@{ 'Service' = 'Visual Studio Online'; DomainSuffix = 'visualstudio.com' },
            [pscustomObject]@{ 'Service' = 'BizTalk Services'; DomainSuffix = 'biztalk.windows.net' },
            [pscustomObject]@{ 'Service' = 'CDN'; DomainSuffix = 'vo.msecnd.net' },
            [pscustomObject]@{ 'Service' = 'Traffic Manager'; DomainSuffix = 'trafficmanager.net' },
            [pscustomObject]@{ 'Service' = 'Active Directory'; DomainSuffix = 'onmicrosoft.com' },
            [pscustomObject]@{ 'Service' = 'Management Services'; DomainSuffix = 'management.core.windows.net' }
        )

        $interestedAzureDnsZones = (($resourceProviderList + $allOtherProviders).DomainSuffix | Select-Object -Unique) -join '|'
        $nodePrefixPatternMatch = "^(?!awverify\.|cdnverify\.|selector\d._domainkey\.)"
        $domainSuffixPatternMatch = "^(CNAME )?(?!awverify\.|cdnverify\.|selector\d._domainkey)(?<fqdn>.*\.($interestedAzureDnsZones))\.?$"
    }

    process {
        if ($Node -imatch $nodePrefixPatternMatch -and $Record -imatch $domainSuffixPatternMatch) {
            [pscustomobject]@{CNAME=$Node; FQDN=$Matches.fqdn}
        }
    }

    end {
    }
}

Export-ModuleMember -Function Convert-ZoneRecordsToCnameRecords