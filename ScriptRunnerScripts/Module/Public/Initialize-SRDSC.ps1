
function Initialize-SRDSC {
    [CmdletBinding(DefaultParameterSetName="Default")]
    param (
        # Datum Install Directory
        [Parameter(Mandatory,ParameterSetName="Default")]
        [Parameter(Mandatory,ParameterSetName="ThirdPartySSL")]
        [Parameter(Mandatory,ParameterSetName="SelfSigned")]
        [Parameter(Mandatory,ParameterSetName="NoSSL")]
        [String]
        $DatumModulePath,
        # Parameter help description
        [Parameter(Mandatory,ParameterSetName="Default")]
        [Parameter(Mandatory,ParameterSetName="ThirdPartySSL")]
        [Parameter(Mandatory,ParameterSetName="SelfSigned")]
        [Parameter(Mandatory,ParameterSetName="NoSSL")]
        [String]
        $PullWebServerPath,
        [Parameter(Mandatory,ParameterSetName="Default")]
        [Parameter(Mandatory,ParameterSetName="ThirdPartySSL")]
        [Parameter(Mandatory,ParameterSetName="SelfSigned")]
        [Parameter(Mandatory,ParameterSetName="NoSSL")]
        [String]
        $ScriptRunnerServerScriptPath,
        [Parameter(Mandatory,ParameterSetName="ThirdPartySSL")]
        [String]
        $PFXCertificatePath,
        [Parameter(Mandatory,ParameterSetName="ThirdPartySSL")]
        [SecureString]
        $PFXCertificatePassword,        
        [Parameter(Mandatory,ParameterSetName="SelfSigned")]
        [Switch]
        $UseSelfSignedCertificate                            
    )
    
    $ErrorActionPreference = "Stop"

    #
    # Create Configuration file to store the datum module information

    $ConfigurationPath = "{0}\PowerShell\SRDSC\Configuration.clixml" -f $Env:ProgramData
    $ConfigurationParentPath = Split-Path $ConfigurationPath -Parent

    $SRConfiguration = @{
        DatumModulePath = $DatumModulePath
        ScriptRunnerModulePath = Split-Path (Get-Module SRDSC).Path -Parent
        ScriptRunnerServerPath = $ScriptRunnerServerScriptPath
        PullServerRegistrationKey = [guid]::newGuid().Guid
    }

    # Set the Global Vars
    Set-ModuleParameters @SRConfiguration

    # If the folder path dosen't exist, create it.
    if (-not(Test-Path -Literalpath $ConfigurationParentPath)) {
        $null = New-Item -Path $ConfigurationParentPath -ItemType Directory -Force
    }

    # Export the Configuration
    ([PSCustomObject]$SRConfiguration) | Export-Clixml -LiteralPath $ConfigurationPath

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
    # Clone the DSCWorkshop PowerShell Module (contains Datum)
    Write-Warning "Installing DSCWorkshop:"

    # Create the folder structure. If required.
    if (Test-Path -LiteralPath $DatumModulePath) {
        #$DatumModulePath = (New-Item -Path $DatumModulePath -ItemType Directory -Force).FullName
    }

    # Download the Datum Module into the destination folder
    $webRequestParams = @{
        Uri = 'https://github.com/dsccommunity/DscWorkshop/archive/refs/heads/main.zip'
        OutFile = "{0}\DSCWorkshop.zip" -f $env:temp
    }
    $null = Invoke-WebRequest @webRequestParams
    # Expand the file
    $archiveParams = @{
        LiteralPath = $webRequestParams.OutFile
        DestinationPath = $DatumModulePath
        Force = $true
    }
    $null = Expand-Archive @archiveParams
    
    #
    # Load SSL Certificates

    if ($UseSelfSignedCertificate.IsPresent) {

        #
        # Generate Self Signed Certificate on the DSC Pull Server.
        # If the file already exists, stop.
        Write-Warning "Generating Self-Signed Certificate. Please wait:"

        # Check if the certificate already exists. If so, stop.
        Get-ChildItem Cert:\LocalMachine\ -Recurse | 
            Where-Object {$_.Subject -like ('*DSC.{0}*' -f $ENV:USERDNSDOMAIN)} | 
                Remove-Item -Force

        # Provision a new certificate.
        # DNSName will be a dsc prefix with the userdns domain as a suffix: .contoso.local
        $params = @{
            DNSName = "DSC.{0}" -f $ENV:USERDNSDOMAIN 
            CertStoreLocation = "cert:\LocalMachine\My"
        }
        $certificate = New-SelfSignedCertificate @params

    }

    #
    # If the SSL Certificate Path parameter was specified, import the cert
    if ($PFXCertificatePath) {

        #
        # Print to the user that a third party certificate is being installed.
        Write-Warning "Importing Third-Party Certificate. Please wait:"

        $params = @{
            FilePath = $PFXCertificatePath
            CertStoreLocation = "cert:\LocalMachine\My"
            Password = $PFXCertificatePassword
        }
        $certificate = Import-PfxCertificate @params
    }

    #
    # Installing DSC Pull Server
    Write-Warning "Installing ScriptRunner DSC Pull Server. Please wait:"

    # Kick off the DSC Configuration
    $xDscWebServiceRegistrationParams = @{
        NodeName = 'localhost'
        RegistrationKey = $SRConfiguration.PullServerRegistrationKey
        WebServerFilePath = $PullWebServerPath
        CertificateThumbPrint = $certificate.Thumbprint
        OutputPath = 'C:\Windows\Temp'
    }
    xDscWebServiceRegistration @xDscWebServiceRegistrationParams
    Start-DscConfiguration -Path 'C:\Windows\Temp' -Wait -Verbose -Force
    
    #
    # Create the filepath

    #
    # Create the Action and Scheduled Tasks in Script Runner



}

Export-ModuleMember -Function Initialize-SRDSC

#
# TODO: Download DSC Pipeline from Github
#
# Check if DSC is installed, stop
# Download DSC Pipeline

#Configuration 

# Create SR, scheduled actions (disabled) to 
