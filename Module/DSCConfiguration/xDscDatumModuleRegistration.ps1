Configuration xDscDatumModuleRegistration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String]
        $DatumModulePath,
        [Parameter(Mandatory)]
        [String]
        $DatumModuleTemplatePath,
        [Parameter(Mandatory)]
        [String]        
        $SRDSCTemplateFile
    )

    #
    # Create Datum Module Directory
    File 'SRDSCScriptRunnerModuleDirectory' {
        Ensure = 'Present'
        Type = 'Directory'
        DestinationPath = $DatumModulePath        
    }

    #
    # Create Datum Module Template Directory
    File 'SRDSCScriptRunnerModuleDirectory' {
        Ensure = 'Present'
        DependsOn = '[File]$SRDSCScriptRunnerModuleDirectory'
        Type = 'Directory'
        DestinationPath = $DatumModuleTemplatePath        
    }
    
    #
    # Copy the New-VM Teamplate YAML File into the Datum Directory
    File "NewVMTemplateConfigFile" 
    {
        DependsOn = '[File]SRDSCScriptRunnerModuleDirectory'
        SourcePath = $SRDSCTemplateFile
        DestinationPath  = $DatumModuleTemplatePath
        Ensure = "Present"
        Force = $true
        MatchSource = $true
    }

}