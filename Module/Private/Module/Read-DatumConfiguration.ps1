function Read-DatumConfiguration {
<#
.Description
Read-DatumConfiguration is the first step in loading and pre-parsing the datum configuration and 
the file structure. It utilizes Resolve-DatumItem to read the Datum Resolution Precidence
and Resolve-YamlItem to parse and match the Datum directory/file structure defined in the resolution
precidence.

.PARAMETER DatumConfigurationFile
The Filepath of the Datum.yaml file.

.PARAMETER DatumConfigurationPath
The 'sources' directory filepath within the datum module.

.EXAMPLE

$DatumConfiguration = Read-DatumConfiguration `
        -DatumConfigurationFile $Global:SRDSC.DatumModule.ConfigurationFile `
        -DatumConfigurationPath $Global:SRDSC.DatumModule.ConfigurationPath

.SYNOPSIS
Loads the Datum Resolution Precidence and pre-parses the datum file structure as values into datum object structure.
#>      
    [CmdletBinding()]
    param (
        # Datum.yml file
        [Parameter(Mandatory)]
        [ValidateScript({
            Test-Path -LiteralPath $_ -ErrorAction SilentlyContinue
        })]
        [String]
        $DatumConfigurationFile,
        # Datum Configuration Path
        [Parameter(Mandatory)]
        [ValidateScript({
            Test-Path -LiteralPath $_ -ErrorAction SilentlyContinue
        })]
        [String]
        $DatumConfigurationPath
    )

    $DatumConfiguration = Get-Content $DatumConfigurationFile | ConvertFrom-Yaml
    $DatumConfiguration.ResolutionPrecedence | Resolve-DatumItem -YamlItems (Resolve-YamlItem -FilePath $DatumConfigurationPath)

}
