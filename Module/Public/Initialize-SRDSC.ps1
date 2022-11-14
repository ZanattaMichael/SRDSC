
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
    # Check PowerShell Window is evelated.
    if (-not(Test-isElevated)) {
        Throw "An Elevated PowerShell Window is required to Install and Initialize a Script Runner DSC Pull Server"
        return
    }

    #
    # Write installation message to the screen
    Write-Warning "Installing ScriptRunner DSC Pull Server. Please wait:"

    #
    # Create Configuration file to store the datum module information

    $ConfigurationPath = "{0}\PowerShell\SRDSC\Configuration.clixml" -f $Env:ProgramData
    $ConfigurationParentPath = Split-Path $ConfigurationPath -Parent

    #
    # Set the Global Vars

    $SRConfiguration = @{
        DatumModulePath = $DatumModulePath
        ScriptRunnerModulePath = Split-Path (Get-Module SRDSC).Path -Parent
        ScriptRunnerServerPath = $ScriptRunnerServerScriptPath
        ScriptRunnerServerName = $ScriptRunnerServerName
        DSCPullServerWebAddress = $PullWebServerPath
        PullServerRegistrationKey = [guid]::newGuid().Guid
        DSCPullServer = $ENV:COMPUTERNAME
        DSCPullServerHTTP = $(
            if ($UseSelfSignedCertificate.IsPresent -or $PFXCertificatePath) {
                'https'
            } else {
                'http'
            }
        )       
    }

    Set-ModuleParameters @SRConfiguration

    #
    # Installing DSC Pull Server
    Write-Warning "Installing ScriptRunner DSC Pull Server. Please wait:"

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

    $xDscPullServerRegistrationParams = @{

        NodeName = 'localhost'
        
        xDscWebServiceRegistrationParams = @{

            RegistrationKey = $SRConfiguration.PullServerRegistrationKey
            WebServerFilePath = $PullWebServerPath
            CertificateThumbPrint = $certificate.Thumbprint

        }

        xDscDatumModuleRegistrationParams = @{
            
            DatumModulePath = $Global:SRDSC.DatumModule.DatumModulePath
            DatumModuleTemplatePath = $Global:SRDSC.DatumModule.DatumTemplates
            SRDSCTemplateFile = $Global:SRDSC.ScriptRunner.NodeRegistrationFile

        }

        xDscSRDSCModuleRegistrationParams = @{
            ConfigurationParentPath = $ConfigurationParentPath
            ScriptRunnerDSCRepository = $Global:SRDSC.ScriptRunner.ScriptRunnerDSCRepository
            FilesToCopy = @(
                "{0}\Publish-SRAction.ps1" -f $Global:SRDSC.Module.Template
                "{0}\Start-SRDSC.ps1" -f $Global:SRDSC.Module.Template
            )
        }

    }
    xDscPullServerRegistration @xDscPullServerRegistrationParams
    Start-DscConfiguration -Path 'C:\Windows\Temp' -Wait -Verbose -Force    


    #
    # Export the Configuration
    ([PSCustomObject]$SRConfiguration) | Export-Clixml -LiteralPath $ConfigurationPath

    #
    # Clone the DSCWorkshop PowerShell Module (contains Datum)
    Write-Warning "Installing DSCWorkshop:"

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
    # Perform Git Initialization on Datum Source Directory
    $PreviousLocation = Get-Location 
    Set-Location $Global:SRDSC.DatumModule.SourcePath
    git init

    #
    # Configure Git
    
    git config --global user.name "SCRIPTRUNNERSERVICE" 
    git config --global user.email ("SCRIPTRUNNERSERVICE@{0}" -f $ENV:USERDOMAIN)

    #
    # Add and Commit the files
    git add .
    git commit -m 'Initial Commit'

    Set-Location $PreviousLocation.Path

    #
    # Create the Action and Scheduled Tasks in Script Runner


}

if ($isModule) { Export-ModuleMember -Function Initialize-SRDSC }

<#


    #
    # Create an action in SR
    #


    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    $session.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 Safari/537.36"
    Invoke-WebRequest -UseBasicParsing -Uri "http://scriptrunner01.contoso.local:8091/ScriptRunner/ActionContextItem/Default.CreateAction" `
    -Method "POST" `
    -WebSession $session `
    -Headers @{
    "Accept"="application/json;q=0.9, */*;q=0.1"
      "Accept-Encoding"="gzip, deflate"
      "Accept-Language"="en-US,en;q=0.9"
      "OData-MaxVersion"="4.0"
      "OData-Version"="4.0"
      "Origin"="http://localhost"
      "Referer"="http://localhost/"
    } `
    -ContentType "application/json" `
    -Body "{`"Title`":`"Start-SRDSC`",`"OwnerID`":0,`"Comment`":`"`",`"ScriptID`":43,`"IDLIST_Tags`":`"15`"}";
    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    $session.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 Safari/537.36"
    Invoke-WebRequest -UseBasicParsing -Uri "http://scriptrunner01.contoso.local:8091/ScriptRunner/ActionContextItem/Default.CreateAction" `
    -Method "OPTIONS" `
    -WebSession $session `
    -Headers @{
    "Accept"="*/*"
      "Accept-Encoding"="gzip, deflate"
      "Accept-Language"="en-US,en;q=0.9"
      "Access-Control-Request-Headers"="content-type,odata-maxversion,odata-version"
      "Access-Control-Request-Method"="POST"
      "Origin"="http://localhost"
      "Referer"="http://localhost/"
      "Sec-Fetch-Mode"="cors"
    };
    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    $session.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 Safari/537.36"
    Invoke-WebRequest -UseBasicParsing -Uri "http://scriptrunner01.contoso.local:8091/ScriptRunner/ActionContext(22)" `
    -Method "PATCH" `
    -WebSession $session `
    -Headers @{
    "Accept"="application/json;q=0.9, */*;q=0.1"
      "Accept-Encoding"="gzip, deflate"
      "Accept-Language"="en-US,en;q=0.9"
      "OData-MaxVersion"="4.0"
      "OData-Version"="4.0"
      "Origin"="http://localhost"
      "Referer"="http://localhost/"
    } `
    -ContentType "application/json" `
    -Body "{`"ImportModules`":`"SRDSC`",`"Insensitive`":true,`"IsScheduled`":true,`"RT_IDLIST_Targets`":`"-2`",`"RT_LIST_TargetNames`":`"Direct Service Execution`",`"Schedule`":`"M;30`",`"ScheduleEnd`":`"1999-01-01T00:00:00.000Z`"}";
    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    $session.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 Safari/537.36"
    Invoke-WebRequest -UseBasicParsing -Uri "http://scriptrunner01.contoso.local:8091/ScriptRunner/ActionContext(22)" `
    -Method "OPTIONS" `
    -WebSession $session `
    -Headers @{
    "Accept"="*/*"
      "Accept-Encoding"="gzip, deflate"
      "Accept-Language"="en-US,en;q=0.9"
      "Access-Control-Request-Headers"="content-type,odata-maxversion,odata-version"
      "Access-Control-Request-Method"="PATCH"
      "Origin"="http://localhost"
      "Referer"="http://localhost/"
      "Sec-Fetch-Mode"="cors"
    };
    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    $session.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 Safari/537.36"
    Invoke-WebRequest -UseBasicParsing -Uri "http://scriptrunner01.contoso.local:8091/ScriptRunner/ActionContext(22)" `
    -WebSession $session `
    -Headers @{
    "Accept"="application/json;q=0.9, */*;q=0.1"
      "Accept-Encoding"="gzip, deflate"
      "Accept-Language"="en-US,en;q=0.9"
      "OData-MaxVersion"="4.0"
      "Origin"="http://localhost"
      "Referer"="http://localhost/"
    };
    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    $session.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 Safari/537.36"
    Invoke-WebRequest -UseBasicParsing -Uri "http://scriptrunner01.contoso.local:8091/ScriptRunner/ActionContextItem(22)/Default.ChangeAction" `
    -Method "POST" `
    -WebSession $session `
    -Headers @{
    "Accept"="application/json;q=0.9, */*;q=0.1"
      "Accept-Encoding"="gzip, deflate"
      "Accept-Language"="en-US,en;q=0.9"
      "OData-MaxVersion"="4.0"
      "OData-Version"="4.0"
      "Origin"="http://localhost"
      "Referer"="http://localhost/"
    } `
    -ContentType "application/json" `
    -Body "{`"ScriptParameters`":[],`"Values`":[],`"Hides`":[],`"TypeHints`":[],`"InputRefs`":[]}";
    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    $session.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 Safari/537.36"
    Invoke-WebRequest -UseBasicParsing -Uri "http://scriptrunner01.contoso.local:8091/ScriptRunner/ActionContextItem(22)/Default.ChangeAction" `
    -Method "OPTIONS" `
    -WebSession $session `
    -Headers @{
    "Accept"="*/*"
      "Accept-Encoding"="gzip, deflate"
      "Accept-Language"="en-US,en;q=0.9"
      "Access-Control-Request-Headers"="content-type,odata-maxversion,odata-version"
      "Access-Control-Request-Method"="POST"
      "Origin"="http://localhost"
      "Referer"="http://localhost/"
      "Sec-Fetch-Mode"="cors"
    };
    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    $session.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 Safari/537.36"
    Invoke-WebRequest -UseBasicParsing -Uri "http://scriptrunner01.contoso.local:8091/ScriptRunner/ActionContextItem(22)/Default.UpdateAssignments" `
    -Method "POST" `
    -WebSession $session `
    -Headers @{
    "Accept"="application/json;q=0.9, */*;q=0.1"
      "Accept-Encoding"="gzip, deflate"
      "Accept-Language"="en-US,en;q=0.9"
      "OData-MaxVersion"="4.0"
      "OData-Version"="4.0"
      "Origin"="http://localhost"
      "Referer"="http://localhost/"
    } `
    -ContentType "application/json" `
    -Body "{`"Assignments`":[]}";
    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    $session.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 Safari/537.36"
    Invoke-WebRequest -UseBasicParsing -Uri "http://scriptrunner01.contoso.local:8091/ScriptRunner/ActionContextItem(22)/Default.UpdateAssignments" `
    -Method "OPTIONS" `
    -WebSession $session `
    -Headers @{
    "Accept"="*/*"
      "Accept-Encoding"="gzip, deflate"
      "Accept-Language"="en-US,en;q=0.9"
      "Access-Control-Request-Headers"="content-type,odata-maxversion,odata-version"
      "Access-Control-Request-Method"="POST"
      "Origin"="http://localhost"
      "Referer"="http://localhost/"
      "Sec-Fetch-Mode"="cors"
    }

#>

#
# TODO: Download DSC Pipeline from Github
#
# Check if DSC is installed, stop
# Download DSC Pipeline

#Configuration 

# Create SR, scheduled actions (disabled) to 
