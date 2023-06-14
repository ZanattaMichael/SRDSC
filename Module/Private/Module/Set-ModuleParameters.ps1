
Function Set-ModuleParameters {
<#
.Description
Set-ModuleParamters is used by SRDSC to store the global configuration that's used within the module.
When the module is loaded the first time, it's statically loaded and the paramters needed for the configuration
is exported to C:\ProgramData\. Each subsequent time following that, the module loads the configuration
from the C:\ProgramData programatically.

.PARAMETER DatumModulePath

Datum Module File Path

.PARAMETER ScriptRunnerModulePath

SRDSC Module Path

.PARAMETER ScriptRunnerServerPath

Script Runner Server Script Repository Path

.PARAMETER PullServerRegistrationKey

Pull Server Registration Key

.PARAMETER DSCPullServer

Pull Server Name

.PARAMETER DSCPullServerHTTP

Pull Server URL

.PARAMETER ScriptRunnerURL

Script Runner URL Endpoint

.EXAMPLE

$CliXML = Import-Clixml $ConfigurationPath

$params = @{
    DatumModulePath = $CliXML.DatumModulePath
    ScriptRunnerModulePath = $CliXML.ScriptRunnerModulePath
    ScriptRunnerServerPath = $CliXML.ScriptRunnerServerPath
    PullServerRegistrationKey = $CliXML.PullServerRegistrationKey
    DSCPullServer = $CliXML.DSCPullServer
    DSCPullServerHTTP = $CliXML.DSCPullServerHTTP
    ScriptRunnerURL = $CliXML.ScriptRunnerURL
    CertificateThumbprint = $CliXML.CertificateThumbprint    
}

# Load the Global Settings
Set-ModuleParameters @params

.SYNOPSIS
Set's Global Configuration paramters used by the SRDSC Module.
#>    
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String]
        $DatumModulePath,
        [Parameter(Mandatory)]
        [String]        
        $ScriptRunnerModulePath,
        [Parameter(Mandatory)]
        [String]        
        $ScriptRunnerServerPath,
        [Parameter(Mandatory)]
        [String]        
        $PullServerRegistrationKey,
        [Parameter(Mandatory)]
        [String]        
        $DSCPullServer,
        [Parameter(Mandatory)]
        [String]        
        $DSCPullServerHTTP,
        [Parameter(Mandatory)]
        [String]
        $ScriptRunnerURL,
        [Parameter(Mandatory)]
        [String]
        $CertificateThumbprint        
    )

    $Global:SRDSC = [PSCustomObject]@{

        ScriptRunner = [PSCustomObject]@{
            ScriptRunnerURL = $ScriptRunnerURL
            ScriptRunnerDSCRepository = '{0}\ScriptMgr\DSC' -f $ScriptRunnerServerPath
            NodeTemplateFile = '{0}\Template\NodeTemplateConfiguration.yml' -f $ScriptRunnerModulePath                           
            NodeRegistrationFile = '{0}\Configuration\NodeRegistration.clixml' -f $ScriptRunnerModulePath
            ScriptTemplates = [PSCustomObject]@{
                NewVMTemplate = '{0}\Template\New-VirutalMachine.template.ps1' -f $ScriptRunnerModulePath
            }
        }
    
        DSCPullServer = [PSCustomObject]@{
            DSCPullServerName = $DSCPullServer
            # Use a UNC path since the pull server could be on a remote host
            DSCPullServerMOFPath = 'C$\Program Files\WindowsPowerShell\DscService\Configuration\'
            DSCPullServerResourceModules = 'C$\Program Files\WindowsPowerShell\DscService\Modules\'
            DSCPullServerWebAddress = '{0}://{1}:8080' -f $DSCPullServerHTTP, $DSCPullServer
            PullServerRegistrationKey = $PullServerRegistrationKey
            CertificateThumbprint = $CertificateThumbprint
        }

        DatumModule = [PSCustomObject]@{
            
            DatumModulePath = $DatumModulePath
            DatumTemplates = '{0}\SRDSCTemplates' -f $DatumModulePath
            NodeTemplateFile = '{0}\SRDSCTemplates\NodeTemplateConfiguration.yml' -f $DatumModulePath
            NodeRegistrationFile = '{0}\NodeRegistration.clixml' -f $DatumModulePath
            ConfigurationPath = '{0}\' -f $DatumModulePath
            RenamedMOFOutput = '{0}\output\RenamedMOF' -f $DatumModulePath
            SourcePath = '{0}\source\' -f $DatumModulePath
            ConfigurationFile = '{0}\source\Datum.yml' -f $DatumModulePath
            CompiledMOFOutput = '{0}\output\MOF' -f $DatumModulePath
            CompileCompressedModulesOutput = '{0}\output\CompressedModules' -f $DatumModulePath
            BuildPath = '{0}\build.ps1' -f $DatumModulePath
            YAMLSortOrder = @(
                'NodeName'
                'Environment'
                'Role'
                'Description'
                'Location'
                'Baseline'
                'ComputerSettings'
                'NetworkIpConfiguration'
                'PSDscAllowPlainTextPassword'
                'PSDscAllowDomainUser'
                'LcmConfig'
                'DscTagging'
            )
        }
    
    }

}

