Configuration xDscPullServerRegistration
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String]
        $NodeName,        
        [Parameter(Mandatory)]
        [HashTable]
        $xDscWebServiceRegistrationParams,
        [Parameter(Mandatory)]
        [HashTable]
        $xDscDatumModuleRegistrationParams,
        [Parameter(Mandatory)]
        [HashTable]
        $xDscSRDSCModuleRegistrationParams               
    )

    Import-DSCResource -ModuleName PSDesiredStateConfiguration
    Import-DSCResource -ModuleName xPSDesiredStateConfiguration

    Node $NodeName
    {
        #
        # DSC Pull Server Configuration
        #
        
        WindowsFeature DSCServiceFeature
        {
            Ensure = "Present"
            Name   = "DSC-Service"
        }       
    
        xDscWebService PSDSCPullServer
        {
            Ensure                  = "Present"
            EndpointName            = "PSDSCPullServer"
            Port                    = 8080
            PhysicalPath            = "$($xDscWebServiceRegistrationParams.WebServerFilePath)\PSDSCPullServer"
            CertificateThumbPrint   = $xDscWebServiceRegistrationParams.CertificateThumbPrint
            ModulePath              = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Modules"
            ConfigurationPath       = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Configuration"
            State                   = "Started"
            DependsOn               = "[WindowsFeature]DSCServiceFeature"
            RegistrationKeyPath     = "$env:PROGRAMFILES\WindowsPowerShell\DscService"
            AcceptSelfSignedCertificates = $true
            UseSecurityBestPractices     = $true
            Enable32BitAppOnWin64   = $false
        }
    
        File RegistrationKeyFile
        {
            Ensure          = 'Present'
            Type            = 'File'
            DestinationPath = "$env:ProgramFiles\WindowsPowerShell\DscService\RegistrationKeys.txt"
            Contents        = $xDscWebServiceRegistrationParams.RegistrationKey
            DependsOn       = "[xDscWebService]PSDSCPullServer"
        }
        
        #
        # Datum Module Configuration
        #

        #
        # Create Datum Module Directory
        File 'DatumModuleDirectory' {
            Ensure          = 'Present'
            Type            = 'Directory'
            DestinationPath = $xDscDatumModuleRegistrationParams.DatumModulePath        
        }
        
        #
        # Copy the New-VM Teamplate YAML File into the Datum Directory
        File "NewVMTemplateConfigFile" 
        {
            SourcePath          = $xDscDatumModuleRegistrationParams.SRDSCTemplateFile
            DestinationPath     = $xDscDatumModuleRegistrationParams.DatumModuleTemplatePath
            Ensure              = "Present"
            Force               = $true
            MatchSource         = $true
        }

        #
        # SRDSC Module Configuration
        #

        #
        # Create the Configuration Directory stored on C:\Program Files
        File 'ConfigurationDirectory' {
            Ensure = 'Present'
            Type = 'Directory'
            DestinationPath     = $xDscSRDSCModuleRegistrationParams.ConfigurationParentPath
        }
    
        #
        # Create 'SRDSC' Directory within the Script Runner Script Repo

        File 'SRDSCScriptRunnerModuleDirectory' {
            Ensure = 'Present'
            Type = 'Directory'
            DestinationPath     = $xDscSRDSCModuleRegistrationParams.ScriptRunnerDSCRepository        
        }
        
        #
        # Copy Files into the respective directory.
        ForEach($File in $xDscSRDSCModuleRegistrationParams.Files) {
    
            File "FileCopy_$(Split-Path $File -Leaf)" 
            {
                DependsOn           = '[File]SRDSCScriptRunnerModuleDirectory'
                SourcePath          = $File
                Type                = 'File'
                DestinationPath     = "{0}\{1}" -f 
                                    $xDscSRDSCModuleRegistrationParams.ScriptRunnerDSCRepository,
                                    (Split-Path $File -Leaf)
                Ensure              = "Present"
            }
    
        }
        
    }

}