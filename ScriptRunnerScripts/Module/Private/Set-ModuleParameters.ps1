
Function Set-ModuleParameters {
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
        $ScriptRunnerServerPath        
    )

    $Global:SRDSC = [PSCustomObject]@{

        ScriptRunner = [PSCustomObject]@{
            ScriptRunnerDSCRepository = '{0}\ScriptMgr\DSC' -f $ScriptRunnerServerPath
            NodeTemplateFile = '{0}\Template\NodeTemplateConfiguration.yml' -f $ScriptRunnerModulePath                           
            NodeRegistrationFile = '{0}\Configuration\NodeRegistration.clixml' -f $ScriptRunnerModulePath
            ScriptTemplates = [PSCustomObject]@{
                NewVMTemplate = '{0}\Template\New-VirutalMachine.template.ps1' -f $ScriptRunnerModulePath
            }
        }
    
        DSCPullServer = [PSCustomObject]@{
            DSCPullServerName = 'SCRIPTRUNNER01'
            DSCPullServerMOFPath = 'C:\Interpub\DSC\MOFS'
            DSCPullServerResourceModules = 'C:\Interpub\Somepath'
            DSCPullServerWebAddress = 'http://SCRIPTRUNNER01:8080'
        }

        DatumModule = [PSCustomObject]@{
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

