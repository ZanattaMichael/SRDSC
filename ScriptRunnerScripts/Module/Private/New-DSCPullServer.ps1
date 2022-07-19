Function New-DSCPullServer {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String]
        $DSCPullServer = 'localhost',
        [Parameter()]
        [String]
        $FilePath = $env:PROGRAMFILES

    )

    #
    # Ensure that the DSC Pull Server has the latest version of PowerShellGet
    Invoke-Command -ComputerName $DSCPullServer -ScriptBlock {

        if ((Get-PackageProvider PowerShellGet).Version.Major -le 1) {
            #
            # Using documentation from https://docs.microsoft.com/en-us/powershell/scripting/gallery/installing-psget?view=powershell-5.1

            # Set the TLS Settings
            [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12   
            # Update the PowerShell Package Provider, by first updating nuget
            $null = Install-PackageProvider -Name NuGet -Force
            # Update PowerShell Get
            $null = Install-Module PowerShellGet -AllowClobber -Force -Confirm:$false
            # Set the PowerShellGet Repo to be Trusted
            $null = Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
        }

    }

    #
    # Generate Self Signed Certificate on the DSC Pull Server.
    # If the file already exists, stop.
    Invoke-Command -ComputerName $DSCPullServer -ScriptBlock {

        # Check if the certificate already exists. If so, stop.
        if (
            [Array](Get-ChildItem Cert:\LocalMachine\ -Recurse |
                        Where-Object {$_.Subject -like ('*DSC.{0}*' -f $ENV:USERDNSDOMAIN)}).Count -ne 0
        ) { 
            Write-Verbose "Certificate Already Exists. Using Existing Certificate."
            return 
        }

        # Provision a new certificate.
        # DNSName will be a dsc prefix with the userdns domain as a suffix: .contoso.local

        $params = @{
            DNSName = "DSC.{0}" -f $ENV:USERDNSDOMAIN 
            CertStoreLocation = "cert:\LocalMachine\My"
        }
        New-SelfSignedCertificate @params

    }

    #
    # Generate GUID
    $GUID = [guid]::newGuid().Guid

    # Kick off the DSC Configuration
    xDscWebServiceRegistration -NodeName $DSCPullServer -RegistrationKey $GUID -WebServerFilePath $FilePath

}


