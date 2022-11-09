configuration xDscWebServiceRegistration
{
    param
    (
        [ValidateNotNullOrEmpty()]
        [string[]]$NodeName,
  
        [ValidateNotNullOrEmpty()]
        [string] $RegistrationKey,

        [ValidateNotNullOrEmpty()]
        [string] $WebServerFilePath,

        [ValidateNotNullOrEmpty()]
        [string] $CertificateThumbPrint

    )

    Import-DSCResource -ModuleName PSDesiredStateConfiguration
    Import-DSCResource -ModuleName xPSDesiredStateConfiguration

    Node $NodeName
    {
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
            PhysicalPath            = "$WebServerFilePath\inetpub\PSDSCPullServer"
            CertificateThumbPrint   = $CertificateThumbPrint
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
            Contents        = $RegistrationKey
        }
    }
}