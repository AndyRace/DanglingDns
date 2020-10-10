$VerbosePreference = "SilentlyContinue"
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
Set-PSDebug -Strict

$TIMEOUT_DEFAULT_SEC = 10

[string]$DynUri = 'https://api.dynect.net/REST'

function Invoke-DynDnsRequest {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]
        $Session,

        [Parameter(Mandatory=$true)]
        [string]
        $Api,

        [Parameter(Mandatory=$false)]
        [hashtable]
        $Body,

        [Parameter(Mandatory=$false)]
        [string]
        $Method = 'POST',

        [Parameter(Mandatory=$false)]
        [int]
        $TimeoutSec = $TIMEOUT_DEFAULT_SEC
    )
    
    $params = @{
        Uri         = "$DynUri/$Api"
        Method      = $Method
        ContentType = 'application/json'
        Headers     = @{}
    }

    if ($null -ne $body) {
        $params.Body = $Body | ConvertTo-Json
    }

    if ($null -ne $Session -and $null -ne $Session.Token) {
        $params.Headers['Auth-Token'] = $Session.Token
    }

    $response = Invoke-RestMethod @params -TimeoutSec $TimeoutSec

    if ($response.status -ne 'success') {
        throw $response.msgs
    }

    $response
}

function Connect-DynDnsSession {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $CustomerName,

        [Parameter(Mandatory=$true)]
        [PSCredential]
        $Credentials,

        [Parameter(Mandatory=$false)]
        [int]
        $TimeoutSec = $TIMEOUT_DEFAULT_SEC
    )

    [pscustomobject]@{
        Token = (Invoke-DynDnsPost -Session @{Token = $null} -Api 'Session' -TimeoutSec $TimeoutSec -Body @{
            customer_name = $CustomerName
            user_name = $Credentials.UserName
            password = $Credentials.GetNetworkCredential().Password
        }).data.token
    }
}

function Disconnect-DynDnsSession {
    [CmdletBinding()]
    param (
        [PSCustomObject]
        $Session,

        [Parameter(Mandatory=$false)]
        [int]
        $TimeoutSec = $TIMEOUT_DEFAULT_SEC
    )

    Invoke-DynDnsDelete -Session $Session -Api 'Session' -TimeoutSec $TimeoutSec
}

function Invoke-DynDnsPost {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]
        $Session,

        [Parameter(Mandatory=$true)]
        [string]
        $Api,

        [Parameter(Mandatory=$false)]
        [hashtable]
        $Body,

        [Parameter(Mandatory=$false)]
        [int]
        $TimeoutSec = $TIMEOUT_DEFAULT_SEC
    )

    Invoke-DynDnsRequest -Session $Session -Api $Api -Body $Body -Method 'POST' -TimeoutSec $TimeoutSec
}

function Invoke-DynDnsGet {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]
        $Session,

        [Parameter(Mandatory=$true)]
        [string]
        $Api,

        [Parameter(Mandatory=$false)]
        [hashtable]
        $Body,

        [Parameter(Mandatory=$false)]
        [int]
        $TimeoutSec = $TIMEOUT_DEFAULT_SEC
    )

    Invoke-DynDnsRequest -Session $Session -Api $Api -Body $Body -Method 'GET' -TimeoutSec $TimeoutSec
}

function Invoke-DynDnsDelete {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]
        $Session,

        [Parameter(Mandatory=$true)]
        [string]
        $Api,

        [Parameter(Mandatory=$false)]
        [hashtable]
        $Body,

        [Parameter(Mandatory=$false)]
        [int]
        $TimeoutSec = $TIMEOUT_DEFAULT_SEC
    )

    Invoke-DynDnsRequest -Session $Session -Api $Api -Body $Body -Method 'DELETE' -TimeoutSec $TimeoutSec
}

Export-ModuleMember -Function *