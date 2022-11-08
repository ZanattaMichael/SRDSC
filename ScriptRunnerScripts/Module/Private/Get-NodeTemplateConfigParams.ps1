function Get-NodeTemplateConfigParams {
    [CmdletBinding()]
    param (
        # Parameter help description
        [Parameter(Mandatory)]
        [String]
        $TemplateFilePath
    )

    $PropertyList = [System.Collections.Generic.List[PSCustomObject]]::New()
    $YAMLTemplate = Get-Content $TemplateFilePath | ConvertFrom-Yaml
    $FormattedYAMLTemplate = Format-YAMLObject -YAMLObject $YAMLTemplate -ObjectName 'FormattedYAMLTemplate'

    Find-YamlValue -YAMLObject $FormattedYAMLTemplate -ValueToFind '%%' | ForEach-Object {
            $PropertyList.Add([PSCustomObject]@{
                YAMLPath = $_.Path
                YAMLValue = $_.Value
                ParameterName = ($_.Path | ConvertYAMLPathTo-Parameter).ParameterLabel
            })
    }

    $PropertyList

}

if ($isModule) { Export-ModuleMember -Function Get-NodeTemplateConfigParams }