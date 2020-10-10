$VerbosePreference = "SilentlyContinue"
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
Set-PSDebug -Strict

function Add-ResolveDnsMember {
    [cmdletbinding()]
    param
    (   
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        $record
    )

    begin {}
    
    process{
        # "resourceProvider","CNAME","FQDN"
        $record | 
            Add-Member -NotePropertyName 'ResolvedDns' -NotePropertyValue (Resolve-DnsName $record.CNAME -ErrorAction SilentlyContinue) -PassThru

        # if ($resolvedDns -and $resolvedDns.IP4Address -eq '0.0.0.0') {
        #     # The name resolves to a null address
        # }
    }

    end {}
}

Export-ModuleMember -Function Add-ResolveDnsMember