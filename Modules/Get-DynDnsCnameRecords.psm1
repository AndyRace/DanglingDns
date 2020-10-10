$VerbosePreference = "SilentlyContinue"
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
Set-PSDebug -Strict

[int]$LONG_TIMEOUT_SEC = 30

function Get-DynDnsCnameRecords {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $CustomerName,

        [Parameter(Mandatory=$true)]
        [PSCredential]
        $Credentials
    )

    # https://help.dyn.com/get-zones-api/
    # https://api.dynect.net/REST/Zone/

    Write-Host -ForegroundColor Green "$(Get-Date -Format 'G'): Creating session"
    $context = [pscustomobject]@{
        i = [int]0
        n = [int]0
        nCnameRecords = [int]0
        #ProgressActivity = 'Fetching CNAMEs'
        Session = Connect-DynDnsSession -CustomerName $CustomerName -Credentials $Credentials
        stack = [System.Collections.Concurrent.ConcurrentStack[pscustomobject]]::new()
        startTime = (Get-Date)
        # Pass over the path to the module used in the parallel ForEach-Object
        ModulePath = (Get-Module DynDnsApi).Path
        CustomerName = $CustomerName
        Credentials = $Credentials
        Progress = ""
    }
    try {
        Write-Host -ForegroundColor Green "$(Get-Date -Format 'G'): Retrieving all zones"
        $zones = (Invoke-DynDnsGet -Session $context.Session -Api 'Zone' -TimeoutSec $LONG_TIMEOUT_SEC).data
        # $zones = @(
        #     '/REST/Zone/<zone name>/'
        # )
        # [string[]]$zones = Get-Content .\zones.csv

        $context.n = $zones.Count

        # 1000 in 14:00
        # 200 in 4:11
        $bunchOfZones = @()
        ($zones | Sort-Object | ForEach-Object {
            if ($bunchOfZones.Count -eq 100) {
                ,$bunchOfZones
                $bunchOfZones = @()
            }
            $bunchOfZones += $_
        }) + ,$bunchOfZones 
        | ForEach-Object -ThrottleLimit 5 -Parallel {
        #| ForEach-Object {
            $ctx = $using:context
            #$ctx = $context

            Import-Module $ctx.ModulePath

            $bunchOfZones = $_
            Write-Host "$(Get-Date -Format 'G') [$((Get-Date) - $ctx.startTime)]: Processing new chunk of zones"

            [pscustomobject]$zoneSession = $null
            if (!$ctx.stack.TryPop([ref]$zoneSession)) {
                #Write-Host "$(Get-Date -Format 'G') [$((Get-Date) - $ctx.startTime)]: Connecting to DynDns"
                $zoneSession = Connect-DynDnsSession -CustomerName $ctx.CustomerName -Credentials $ctx.Credentials
                #Write-Host "$(Get-Date -Format 'G') [$((Get-Date) - $ctx.startTime)]: Connected to DynDns"
            }
            try {
                #Write-Host $bunchOfZones.Count
                $bunchOfZones | ForEach-Object {
                    $zone = $_ -replace '/REST/Zone/(.*)/', '$1'

                    # TODO: The following doesn't increment the value
                    #[System.Threading.Interlocked]::Increment([ref]$ctx.i)
                    [System.Threading.Monitor]::Enter($ctx)
                    try {
                        Write-Host -NoNewline (' ' * $ctx.progress.Length + "`r")
                        $percentage = $ctx.i++ / $ctx.n
                        $ctx.progress = "$(Get-Date -Format 'G') [$((Get-Date) - $ctx.startTime)]: $($ctx.i)/$($ctx.n) ($($percentage.ToString('P'))): $($ctx.nCnameRecords) CNAME record(s): ${zone}`r"
                        Write-Host -NoNewLine -ForegroundColor Green $ctx.progress 
                    } finally {
                        [System.Threading.Monitor]::Exit($ctx)
                    }

                    #Write-Progress $ctx.ProgressActivity -Status $progress -PercentComplete ($percentage * 100)
                    
                    # https://api.dynect.net/REST/CNAMERecord/<zone>
                    (Invoke-DynDnsGet -Session $zoneSession -Api "AllRecord/$zone").data
                        | Where-Object { $_ -match "/REST/CNAMERecord/"}
                        | ForEach-Object {
                            (Invoke-DynDnsGet -Session $zoneSession -Api ($_ -replace '/REST/', '')).data 
                                | ForEach-Object {
                                    [pscustomobject]@{ fqdn = $_.fqdn; cname = $_.rdata.cname.TrimEnd('.'); zone = $_.zone }
                                    $ctx.nCnameRecords++;

                                    # Write-Host -NoNewLine -ForegroundColor Blue '.'
                                }
                        }
                }
            } catch {
                Write-Warning $_
            } finally {
                $ctx.stack.TryAdd($zoneSession) | Out-Null
                # Write-Host (' ' * $ctx.progress.Length)
                Write-Host
            }
        }
    } finally {
        Write-Host -ForegroundColor Yellow "$(Get-Date -Format 'G') [$((Get-Date) - $context.startTime)]: Extracted $($context.nCnameRecords) CNAME record(s) from $($context.i)/$($context.n) zone(s)"
        #Write-Progress $context.ProgressActivity -Completed

        Write-Host -ForegroundColor Green "$(Get-Date -Format 'G'): Closing sessions"
        [pscustomobject]$tmpSession = $null
        while ($context.stack.TryPop([ref]$tmpSession)) {
            Disconnect-DynDnsSession -Session $tmpSession -ErrorAction SilentlyContinue | Out-Null
        }
        if ($context.Session) {
            Disconnect-DynDnsSession -Session $context.Session -ErrorAction SilentlyContinue | Out-Null
        }
    }
}

Export-ModuleMember -Function Get-DynDnsCnameRecords