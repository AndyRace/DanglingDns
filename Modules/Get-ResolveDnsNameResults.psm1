function Get-ResolveDnsNameResults {
    [cmdletbinding()]
    param
    (   
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        $record
    )

    begin {}
    
    process{
        # "resourceProvider","CNAME","FQDN"
        $resolvedDns = Resolve-DnsName $record.CNAME -ErrorAction SilentlyContinue

        # if ($resolvedDns -and $resolvedDns.IP4Address -eq '0.0.0.0') {
        #     # The name resolves to a null address
        # }

        @{
            Record = $record
            ResolvedDns = $resolvedDns
        }
    }

    end {}
}

Export-ModuleMember -Function Get-ResolveDnsNameResults