function Read-DatumConfiguration {
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

    <#
    # In the template file, filter out any subexpressions
    $FilteredTemplateFileKeys = $TemplateFile.ScriptRunnerConfiguration.Keys | Where-Object {
        (
            $TemplateFile[$_] -like '`[x=*'
        ) -and (
            $TemplateFile[$_] -like '*=`]'
        )
    }
    #>


    $DatumConfiguration = Get-Content $DatumConfigurationFile | ConvertFrom-Yaml
    $DatumConfiguration.ResolutionPrecedence | Resolve-DatumItem -YamlItems (Resolve-YamlItem -FilePath $DatumConfigurationPath)

}
