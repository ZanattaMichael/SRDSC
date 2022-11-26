Function Get-DefaultNetworkCredentials {
<#
.Description
An abstraction needed for Mocking.
.EXAMPLE
Get-DefaultNetworkCredentials
.SYNOPSIS
Returns the default network credentials.
#>    
    return [System.Net.CredentialCache]::DefaultNetworkCredentials
}
