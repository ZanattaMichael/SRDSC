function Initialize-SRDSC {
<#
.Description
Initalize-SRDSC is used for onboarding the ScriptRunner Server into DSC.
It performs the following tasks:

1. Installs the DSC Pull Server.
2. Downloads and Install's Datum onto the ScriptRunner Server (DSC Toolbox).
3. Sets SRDSC Configuration setting key properties that are used by the SRDSC Build Scripts.
4. Copies SRDSC Scripts into the ScriptRunner repository (in ProgramData).
5. Creates ScriptRunner Service Account Credential.
6. Creates ScriptRunner Local Machine Target with the DSC Service Account Credential.
7. Adds Start-SRDSCConfiguration and Publish-SRActionScript scripts into ScriptRunner and configures the target and sets a reoccuring schedule.

To initialize the script requires a number of parameters that are needed for execution.
These are:

-DatumModulePath: This is the destination path where the Datum Module is to be installed.
-PullWebServerPath: This is the destination path of the IIS instance (C:\Inetpub\).
-ScriptRunnerServerPath: The directory path of the ScriptRunner Script Repository (Usually Located at C:\ProgramData\).  
-ScriptRunnerURL: The URL to the ScriptRunner server.
-ScriptRunnerSACredential: A username/password used by ScriptRunner to Execute the ScriptRunner Script.
-PFXCertificatePath: (Used for the ScriptRunner Pull Server) If a custom SSL certificate is required, the path to that certificate is specified.
-PFXCertificatePassword: The Export password for the custom SSL certificate.
-UseSelfSignedCertificate: (Used for the ScriptRunner Pull Server) Use a Self-Signed certificate for the DSC Pull Server.

.PARAMETER DatumModulePath

This is the destination path where the Datum Module is to be installed.

.PARAMETER PullWebServerPath

This is the destination path of the IIS instance (C:\Inetpub\).

.PARAMETER ScriptRunnerServerPath

The directory path of the ScriptRunner Script Repository (Usually Located at C:\ProgramData\).  

.PARAMETER ScriptRunnerURL

The URL to the ScriptRunner server.

.PARAMETER ScriptRunnerSACredential

A username/password used by ScriptRunner to Execute the ScriptRunner Script.

.PARAMETER PFXCertificatePath

(Used for the ScriptRunner Pull Server) If a custom SSL certificate is required, the path to that certificate is specified.

.PARAMETER PFXCertificatePassword

The Export Password for the custom SSL certificate.

.PARAMETER UseSelfSignedCertificate

(Used for the ScriptRunner Pull Server) Use a Self-Signed certificate for the DSC Pull Server.

.EXAMPLE

Create a DSC Pull Server (installed at C:\Inetpub) on the local ScriptRunner server (http://SCRIPTRUNNER01/', 
with a custom Certificate located at C:\MyCertificate.pfx.
The PowerShell Datum module is installed at C:\Temp.

$params = @{
    DatumModulePath = 'C:\Temp'
    PullWebServerPath = 'C:\Inetpub'
    ScriptRunnerServerPath = 'C:\ProgramData\ScriptRunner' 
    ScriptRunnerURL = 'http://SCRIPTRUNNER01/'
    ScriptRunnerSACredential = (Get-Credential)
    PFXCertificatePath = "C:\MyCertificate.pfx"
    PFXCertificatePassword  = '123Password' | ConvertTo-SecureString -AsPlainText -Force
}

Initialize-SRDSC @params

.EXAMPLE

Create a DSC Pull Server (installed at C:\Inetpub) on the local ScriptRunner server (http://SCRIPTRUNNER01/', 
with a self-signed certificate. The PowerShell Datum module is installed at C:\Temp.

$params = @{
    DatumModulePath = 'C:\Temp'
    PullWebServerPath = 'C:\Inetpub'
    ScriptRunnerServerPath = 'C:\ProgramData\ScriptRunner' 
    ScriptRunnerURL = 'http://SCRIPTRUNNER01/'
    ScriptRunnerSACredential = (Get-Credential)
    UseSelfSignedCertificate = $true
}

Initialize-SRDSC @params

.SYNOPSIS
Onboarding script to install DSC Pull Server, Datum, and ScriptRunner Scripts.
#>
    [CmdletBinding(DefaultParameterSetName="SelfSigned")]
    param (
        # Datum Install Directory
        [Parameter(Mandatory,ParameterSetName="ThirdPartySSL")]
        [Parameter(Mandatory,ParameterSetName="SelfSigned")]
        [String]
        $DatumModulePath,
        # Parameter help description
        [Parameter(Mandatory,ParameterSetName="ThirdPartySSL")]
        [Parameter(Mandatory,ParameterSetName="SelfSigned")]
        [String]
        $PullWebServerPath,
        [Parameter(Mandatory,ParameterSetName="ThirdPartySSL")]
        [Parameter(Mandatory,ParameterSetName="SelfSigned")]
        [String]
        $ScriptRunnerServerPath,
        [Parameter(Mandatory,ParameterSetName="ThirdPartySSL")]
        [Parameter(Mandatory,ParameterSetName="SelfSigned")]
        [String]
        $ScriptRunnerURL,
        [Parameter(Mandatory,ParameterSetName="ThirdPartySSL")]
        [Parameter(Mandatory,ParameterSetName="SelfSigned")]
        [pscredential]
        $ScriptRunnerSACredential,
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

    $ModuleDirectory = Split-Path (Get-Module SRDSC).Path -Parent
    $ComputerFQDN = [System.Net.Dns]::GetHostEntry([string]"localhost").HostName
    $ComputerDomainName = (Get-WmiObject win32_computersystem).Domain

    #
    # Check PowerShell Window is evelated.
    if (-not(Test-isElevated)) {
        Throw "An Elevated PowerShell Window is required to Install and Initialize a ScriptRunner DSC Pull Server"
        return
    }

    #
    # Sanitize the Variables

    # Remove any trailing slashes.
    $ScriptRunnerURL = $ScriptRunnerURL.TrimEnd('/')

    #
    # Clear out the datum directory
    if (Test-Path -LiteralPath $DatumModulePath) {
        $null = Remove-Item $DatumModulePath -Force -Confirm:$false -Recurse
    }

    #
    # Write installation message to the screen
    Write-Warning "[Initialize-SRDSC] Installing ScriptRunner DSC Pull Server. Please wait:"

    #
    # Create Configuration file to store the datum module information

    $ConfigurationPath = "{0}\PowerShell\SRDSC\Configuration.clixml" -f $Env:ProgramData
    $ClientCertificatePath = "{0}\PowerShell\SRDSC\PullServer.cer" -f $Env:ProgramData
    $ConfigurationParentPath = Split-Path $ConfigurationPath -Parent

    #
    # Load SSL Certificates

    if ($UseSelfSignedCertificate.IsPresent) {

        #
        # Generate Self Signed Certificate on the DSC Pull Server.
        # If the file already exists, stop.
        Write-Warning "[Initialize-SRDSC] Generating Self-Signed Certificate. Please wait:"

        # Check if the certificate already exists. If so, remove them.
        Get-ChildItem Cert:\LocalMachine\ -Recurse | 
            Where-Object {$_.Subject -like ('*DSC.{0}*' -f $ENV:USERDNSDOMAIN)} | 
                Remove-Item -Force

        # Provision a new certificate.
        # DNSName will be a dsc prefix with the userdns domain as a suffix: .contoso.local
        $params = @{
            DNSName = "DSC.{0}" -f $ComputerDomainName
            CertStoreLocation = "cert:\LocalMachine\My"
        }
        $certificate = New-SelfSignedCertificate @params

    }

    #
    # If the SSL Certificate Path parameter was specified, import the cert

    if ($PFXCertificatePath) {

        #
        # Print to the user that a third party certificate is being installed.
        Write-Warning "[Initialize-SRDSC] Importing Third-Party Certificate. Please wait:"

        $params = @{
            FilePath = $PFXCertificatePath
            CertStoreLocation = "cert:\LocalMachine\My"
            Password = $PFXCertificatePassword
        }
        $certificate = Import-PfxCertificate @params
    }

    #
    # Set the Global Vars

    $SRConfiguration = @{
        DatumModulePath = $DatumModulePath
        ScriptRunnerModulePath = Split-Path (Get-Module SRDSC).Path -Parent
        ScriptRunnerServerPath = $ScriptRunnerServerPath
        PullServerRegistrationKey = [guid]::newGuid().Guid
        DSCPullServer = "DSC.{0}" -f $ComputerDomainName
        DSCPullServerHTTP = $(
            if ($UseSelfSignedCertificate.IsPresent -or $PFXCertificatePath) {
                'https'
            } else {
                'http'
            }
        ) 
        ScriptRunnerURL = $ScriptRunnerURL
        CertificateThumbPrint = $certificate.Thumbprint      
    }

    Set-ModuleParameters @SRConfiguration

    #
    # Define a hashtable containing parameters for registering the local node with a DSC pull server

    $xDscPullServerRegistrationParams = @{
        NodeName = 'localhost' # Specify the name of the local node to register
        xDscWebServiceRegistrationParams = @{
            RegistrationKey = $SRConfiguration.PullServerRegistrationKey # Specify the registration key for the pull server
            WebServerFilePath = $PullWebServerPath # Specify the path to the pull server web service endpoint
            CertificateThumbPrint = $certificate.Thumbprint # Specify the thumbprint of the certificate to use for authentication
        }
        xDscDatumModuleRegistrationParams = @{
            DatumModulePath = $Global:SRDSC.DatumModule.DatumModulePath # Specify the path to the datum module used by the script runner
            DatumModuleTemplatePath = "{0}\{1}" -f $Global:SRDSC.DatumModule.DatumTemplates, (Split-Path $Global:SRDSC.ScriptRunner.NodeTemplateFile -Leaf) # Specify the path to the datum module template used by the script runner
            SRDSCTemplateFile = $Global:SRDSC.ScriptRunner.NodeTemplateFile # Specify the path to the script runner node template file
        }
        xDscSRDSCModuleRegistrationParams = @{
            ConfigurationParentPath = $ConfigurationParentPath # Specify the path to the parent configuration directory for the script runner
            ScriptRunnerDSCRepository = $Global:SRDSC.ScriptRunner.ScriptRunnerDSCRepository # Specify the path to the script runner DSC repository
            Files = @(
                "{0}\Template\Publish-SRAction.ps1" -f $ModuleDirectory # Specify the path to the Publish-SRAction.ps1 script used by the script runner
                "{0}\Template\Start-SRDSC.ps1" -f $ModuleDirectory # Specify the path to the Start-SRDSC.ps1 script used by the script runner
                "{0}\Template\New-VirtualMachine.ps1" -f $ModuleDirectory # Specify the path to the New-VirtualMachine.ps1 script used by the script runner
            )
        }
        OutputPath = 'C:\Windows\Temp\' # Specify the output path for the registration files
    }
    
    # Register the local node with a DSC pull server using the parameters defined in the $xDscPullServerRegistrationParams hashtable
    xDscPullServerRegistration @xDscPullServerRegistrationParams

    # Start a DSC configuration at the specified path, wait for it to complete, and output verbose messages
    Start-DscConfiguration -Path 'C:\Windows\Temp' -Wait -Verbose -Force

    #
    # Use PowerShell Remoting and Invoke-DSCResource to create an C-NAME
    
    Write-Warning ("Please create a CNAME with 'DSC.{0}' pointing to '{1}'" -f $ComputerDomainName, $ComputerFQDN)

    <#
    $DSCResult = Invoke-Command -ComputerName $ComputerDomainName -ArgumentList $ComputerDomainName, $ComputerFQDN -ScriptBlock {
        param($ComputerDomainName, $ComputerFQDN)

        $ErrorActionPreference = 'Stop'

        #
        # Install an Load the DnsServerDsc Resource

        Install-Module -Name 'DnsServerDsc'
        Import-DscResource -ModuleName 'DnsServerDsc'

        $params = @{
            Name = 'DnsRecordCname'
            Property = @{
                ZoneName = $ComputerFQDN
                Name = 'DSC'
                HostNameAlias = $HostNameAlias
            }
            Method = 'Set'
        }

        Invoke-DscResource @params

    }
    #>

    #
    # Export the Configuration
    ([PSCustomObject]$SRConfiguration) | Export-Clixml -LiteralPath $ConfigurationPath

    #
    # Export the Public Certificate to ProgramData\PowerShell\SRDSC
    # This will be used to onboard nodes into the DSC Pull Server

    (Get-ChildItem Cert:\LocalMachine\ -Recurse | Where-Object {$_.Subject -like ('*DSC.{0}*' -f $ENV:USERDNSDOMAIN)})[0] | 
        Export-Certificate -Force -FilePath $ClientCertificatePath

    #
    # Clone the DSCWorkshop PowerShell Module (contains Datum)
    Write-Warning "[Initialize-SRDSC] Installing DSCWorkshop:"

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
    
    $zipPath = Expand-Archive @archiveParams

    # Move all files up one directory
    $null = Get-ChildItem -LiteralPath "$DatumModulePath\DscWorkshop-main" -File | Move-Item -Destination $DatumModulePath -Force
    $null = Get-ChildItem -LiteralPath "$DatumModulePath\DscWorkshop-main" -Directory | Move-Item -Destination $DatumModulePath -Force
    Remove-Item -LiteralPath "$DatumModulePath\DscWorkshop-main" -Force -Recurse
    
    #
    # Create ScriptRunner Tasks

    Write-Host "[Initialize-SRDSC] Configuring ScriptRunner Server:"

    $addSRActionParams = @{
        ScriptRunnerServer = $Global:SRDSC.ScriptRunner.ScriptRunnerURL
        useScheduling = $true
    }

    $commonSRParams = @{
        ScriptRunnerServer = $Global:SRDSC.ScriptRunner.ScriptRunnerURL
    }

    # Create a ScriptRunner Credential that will be used to execute the scripts
    $scriptRunnerCredential = New-ScriptRunnerCredential @commonSRParams -Credential $ScriptRunnerSACredential
    # Create a ScriptRunner Target for the Scripts to use
    $scriptRunnerTarget = New-ScriptRunnerTarget @commonSRParams -ScriptRunnerCredential $scriptRunnerCredential
    $addSRActionParams.ScriptRunnerTarget = $scriptRunnerTarget

    # Publish-SRAction - Triggers New-VirtualMachine.ps1 to be created
    Add-ScriptRunnerAction -ScriptName 'Publish-SRAction.ps1' -RepeatMins 15 -FailNonTerminatingErrors @addSRActionParams
    # Start-SRDSC - Triggers Datum Build and Deploy Script
    Add-ScriptRunnerAction -ScriptName 'Start-SRDSC.ps1' -RepeatMins 30 @addSRActionParams
    # New-VirtualMachine - Triggers automatic build and deploy
    $addSRActionParams.Remove('useScheduling')
    Add-ScriptRunnerAction -ScriptName 'New-VirtualMachine.ps1' -FailNonTerminatingErrors @addSRActionParams

    #
    # Create the Action and Scheduled Tasks in ScriptRunner
    Write-Host "[Initialize-SRDSC] Server Completed!" -ForegroundColor Green

}

if ($isModule) { Export-ModuleMember -Function Initialize-SRDSC }
