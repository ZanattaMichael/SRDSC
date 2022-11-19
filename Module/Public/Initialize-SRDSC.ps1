
#Initialize-SRDSC -DatumModulePath C:\Temp -PullWebServerPath C:\Inetpub -ScriptRunnerServerPath C:\Temp2 -UseSelfSignedCertificate

function Initialize-SRDSC {
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

    #
    # Check PowerShell Window is evelated.
    if (-not(Test-isElevated)) {
        Throw "An Elevated PowerShell Window is required to Install and Initialize a Script Runner DSC Pull Server"
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
    $ConfigurationParentPath = Split-Path $ConfigurationPath -Parent

    #
    # Set the Global Vars

    $SRConfiguration = @{
        DatumModulePath = $DatumModulePath
        ScriptRunnerModulePath = Split-Path (Get-Module SRDSC).Path -Parent
        ScriptRunnerServerPath = $ScriptRunnerServerPath
        PullServerRegistrationKey = [guid]::newGuid().Guid
        DSCPullServer = $ENV:COMPUTERNAME
        DSCPullServerHTTP = $(
            if ($UseSelfSignedCertificate.IsPresent -or $PFXCertificatePath) {
                'https'
            } else {
                'http'
            }
        ) 
        ScriptRunnerURL = $ScriptRunnerURL      
    }

    Set-ModuleParameters @SRConfiguration

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
        Write-Warning "[Initialize-SRDSC] Importing Third-Party Certificate. Please wait:"

        $params = @{
            FilePath = $PFXCertificatePath
            CertStoreLocation = "cert:\LocalMachine\My"
            Password = $PFXCertificatePassword
        }
        $certificate = Import-PfxCertificate @params
    }

    $xDscPullServerRegistrationParams = @{

        NodeName = 'localhost'
        
        xDscWebServiceRegistrationParams = @{

            RegistrationKey = $SRConfiguration.PullServerRegistrationKey
            WebServerFilePath = $PullWebServerPath
            CertificateThumbPrint = $certificate.Thumbprint

        }

        xDscDatumModuleRegistrationParams = @{
            
            DatumModulePath = $Global:SRDSC.DatumModule.DatumModulePath
            DatumModuleTemplatePath = "{0}\{1}" -f $Global:SRDSC.DatumModule.DatumTemplates, (Split-Path $Global:SRDSC.ScriptRunner.NodeTemplateFile -Leaf)
            SRDSCTemplateFile = $Global:SRDSC.ScriptRunner.NodeTemplateFile

        }

        xDscSRDSCModuleRegistrationParams = @{
            ConfigurationParentPath = $ConfigurationParentPath
            ScriptRunnerDSCRepository = $Global:SRDSC.ScriptRunner.ScriptRunnerDSCRepository
            Files = @(
                "{0}\Template\Publish-SRAction.ps1" -f $ModuleDirectory
                "{0}\Template\Start-SRDSC.ps1" -f $ModuleDirectory
                "{0}\Template\New-VirtualMachine.ps1" -f $ModuleDirectory
            )
        }

        OutputPath = 'C:\Windows\Temp\'

    }

    xDscPullServerRegistration @xDscPullServerRegistrationParams
    Start-DscConfiguration -Path 'C:\Windows\Temp' -Wait -Verbose -Force    


    #
    # Export the Configuration
    ([PSCustomObject]$SRConfiguration) | Export-Clixml -LiteralPath $ConfigurationPath

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
    # Create Script Runner Tasks

    Write-Host "[Initialize-SRDSC] Configuring Script Runner Server:"

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
    Add-ScriptRunnerAction -ScriptName 'Publish-SRAction.ps1' -RepeatMins 15 @addSRActionParams
    # Start-SRDSC - Triggers Datum Build and Deploy Script
    Add-ScriptRunnerAction -ScriptName 'Start-SRDSC.ps1' -RepeatMins 30 @addSRActionParams
    # New-VirtualMachine - Triggers automatic build and deploy
    $addSRActionParams.Remove('useScheduling')
    Add-ScriptRunnerAction -ScriptName 'New-VirtualMachine.ps1' @addSRActionParams

    #
    # Create the Action and Scheduled Tasks in Script Runner
    Write-Host "[Initialize-SRDSC] Server Completed!" -ForegroundColor Green

}

if ($isModule) { Export-ModuleMember -Function Initialize-SRDSC }
