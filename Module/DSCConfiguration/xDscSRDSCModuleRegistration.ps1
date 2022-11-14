Configuration xDscSRDSCModuleRegistration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String]
        $ConfigurationParentPath,
        [Parameter(Mandatory)]
        [String]
        $ScriptRunnerDSCRepository,        
        [Parameter(Mandatory)]
        [String[]]
        $FilesToCopy

    )

    #
    # Create the Configuration Directory stored on C:\Program Files
    File 'ConfigurationDirectory' {
        Ensure = 'Present'
        Type = 'Directory'
        DestinationPath = $ConfigurationParentPath
    }

    #
    # Create 'SRDSC' Directory within the Script Runner Script Repo
    File 'SRDSCScriptRunnerModuleDirectory' {
        Ensure = 'Present'
        Type = 'Directory'
        DestinationPath = $ScriptRunnerDSCRepository        
    }

    #
    # Copy Files into the respective directory.
    ForEach($File in $Files) {

        File "$($File)" 
        {
            DependsOn = '[File]SRDSCScriptRunnerModuleDirectory'
            SourcePath = $File
            DestinationPath  = $ScriptRunnerDSCRepository
            Ensure = "Present"
            Force = $true
            MatchSource = $true
        }

    }

}