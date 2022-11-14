Configuration xDscPullServerRegistration
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [HashTable]
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

    Node $NodeName
    {

        xDscWebServiceRegistration DSCPullServer
        {
            DependsOn = '[xDscDatumModuleRegistration]DSCPullServerDatumConfiguration'
            RegistrationKey = $xDscWebServiceRegistrationParams.RegistrationKey
            WebServerFilePath = $xDscWebServiceRegistrationParams.WebServerFilePath
            CertificateThumbPrint = $xDscWebServiceRegistrationParams.CertificateThumbPrint 
        }

        xDscDatumModuleRegistration DSCPullServerDatumConfiguration 
        {
            DependsOn = '[xDscSRDSCModuleRegistration]DSCPullServerModuleConfiguration'
            DatumModulePath = $xDscDatumModuleRegistrationParams.DatumModulePath
            DatumModuleTemplatePath = $xDscDatumModuleRegistrationParams.DatumModuleTemplatePath
            SRDSCTemplateFile = $xDscDatumModuleRegistrationParams.SRDSCTemplateFile
        }

        xDscSRDSCModuleRegistration DSCPullServerModuleConfiguration
        {
            ConfigurationParentPath = $xDscSRDSCModuleRegistrationParams.ConfigurationParentPath
            ScriptRunnerDSCRepository = $xDscSRDSCModuleRegistrationParams.ScriptRunnerDSCRepository
            FilesToCopy = $xDscSRDSCModuleRegistrationParams.FilesToCopy

        }

    }

}