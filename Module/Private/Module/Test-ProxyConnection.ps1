Function Test-ProxyConnection {
<#
.Description
Test for a proxy server and attempt to authenticate to it.
.PARAMETER uri

URL to test.

.EXAMPLE

    Test-ProxyConnection

.SYNOPSIS
Test for a proxy server and attempt to authenticate to it.
#>     
    param (
        [parameter(Mandatory = $false, Position = 0)]
        [string]
        $uri = "https://www.google.com"
    )

    #Create a webclient proxy object
    try {
        $webProxy = (New-Object System.Net.WebClient)
    } catch {
        Write-Warning "[Test-ProxyConnection] Failed to create the proxy object. Could be a permissions problem?"
        return ($false)
    }

    if (-not($webProxy.proxy.GetProxies($uri))) {
        Write-Host "[Test-ProxyConnection] No Proxy Found!" -ForegroundColor Green
        return ($false)
    }
    
    Write-Warning "[Test-ProxyConnection] Proxy Server Found. Attempting to set authentication to 'Default Network Creds':"

    #Proxy detected, configure the session proxy to use the system proxy
    try {
        $webProxy.Proxy.Credentials = Get-DefaultNetworkCredentials
        Write-Host "Success! Proxy Authenticated!" -ForegroundColor Green
        return ($true)
    } catch {
        Write-Warning "[Test-ProxyConnection] Error: $($_)"
    }

    $false
}