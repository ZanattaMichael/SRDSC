
function Initialize-SRDSC {
    [CmdletBinding()]
    param (
        # Datum Install Directory
        [Parameter(Mandatory)]
        [String]
        $DatumModulePath
    )
     
    #
    # Check PowerShell Window is evelated.
    if (-not(Test-isElevated)) {
        Throw "An Elevated PowerShell Window is required to Install and Initialize a Script Runner DSC Pull Server"
        return
    }

    #
    # Write installation message to the screen
    Write-Warning "Installing ScriptRunner DSC Pull Server. Please wait:"

    #
    # Ensure that PowerShellGet is up-to-date
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
        # Import the updated module
        Import-Module PowerShellGet
    }

    #
    # Test if chocolatley is installed
    try {
        $null = choco -v
    } catch {
        # Set the TLS Settings
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072;
        # Download and install Choco
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    }

    #
    # Install Git
    Write-Warning "Installing Git:"
    choco install git --confirm

    #
    # Clone the DSCWorkshop PowerShell Module (contains Datum)
    Write-Warning "Installing DSCWorkshop:"

    # Create the folder structure. If required.
    if (Test-Path -LiteralPath $DatumModulePath) {
        $DatumModulePath = (New-Item -Path $DatumModulePath -ItemType Directory -Force).FullName
    }

    # Clone the repo into the destination path
    git clone 'https://github.com/dsccommunity/DscWorkshop.git' $DatumModulePath

    #
    # Generate Self Signed Certificate on the DSC Pull Server.
    # If the file already exists, stop.

    # Check if the certificate already exists. If so, stop.
    if (
        [Array](Get-ChildItem Cert:\LocalMachine\ -Recurse |
                    Where-Object {$_.Subject -like ('*DSC.{0}*' -f $ENV:USERDNSDOMAIN)}).Count -eq 0
    ) { 

        # Provision a new certificate.
        # DNSName will be a dsc prefix with the userdns domain as a suffix: .contoso.local

        $params = @{
            DNSName = "DSC.{0}" -f $ENV:USERDNSDOMAIN 
            CertStoreLocation = "cert:\LocalMachine\My"
        }
        New-SelfSignedCertificate @params

    }


    #
    # Installing DSC Pull Server
    Write-Warning "Installing ScriptRunner DSC Pull Server. Please wait:"
    New-DSCPullServer

}

#
# TODO: Download DSC Pipeline from Github
#
# Check if DSC is installed, stop
# Download DSC Pipeline

#Configuration 

# Create SR, scheduled actions (disabled) to 