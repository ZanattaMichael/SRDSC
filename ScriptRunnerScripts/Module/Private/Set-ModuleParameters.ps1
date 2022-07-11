
Function Set-ModuleParameters {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String]
        $DatumModulePath,
        [Parameter(Mandatory)]
        [String]        
        $ScriptRunnerModulePath
    )

    $Global:ScriptRunner = [PSCustomObject]@{

        ScriptRunner = [PSCustomObject]@{
            NodeTemplateFile = '{0}\Template\NodeTemplateConfiguration.yml' -f $ScriptRunnerModulePath                           
        }
    
        DSCPullServer = [PSCustomObject]@{
            DSCPullServerWebAddress = 'http://SCRIPTRUNNER01:8080'
            MOFNodeRegistrationFile = '{0}\Configuration\MOFNodeRegistrationFile.clixml' -f $ScriptRunnerModulePath
        }

        DatumModule = [PSCustomObject]@{
            ConfigurationPath = $DatumModulePath
            RenamedMOFOutput = '{0}\output\RenamedMOF' -f $DatumModulePath
            ConfigurationFile = '{0}\Datum.yml' -f $DatumModulePath
            CompiledMOFOutput = '{0}\output\MOF' -f $DatumModulePath
            CompileRequiredModulesOutput = '{0}\output\RequiredModules' -f $DatumModulePath
            BuildPath = '{0}\build.ps1' -f $DatumModulePath
        }
    
    }

}

