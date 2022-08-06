function Get-NodeTemplateConfigParams {
    [CmdletBinding()]
    param (
        # Parameter help description
        [Parameter(Mandatory)]
        [String]
        $TemplateFilePath
    )

    $PropertyList = [System.Collections.Generic.List[PSCustomObject]]::New()

    $TemplateFilePath = 'D:\Git\DSC-ScriptRunner\DSC-ScriptRunner\ScriptRunnerScripts\Module\Template\NodeTemplateConfiguration.yml'
    $YAMLTemplate = Get-Content $TemplateFilePath | ConvertFrom-Yaml
    $FormattedYAMLTemplate = Format-YAMLObject -YAMLObject $YAMLTemplate -ObjectName 'FormattedYAMLTemplate'
    Find-YamlValue -YAMLObject $FormattedYAMLTemplate -ValueToFind '%%' | 
        Sort-Object -Unique -Property Path | ForEach-Object {
            $PropertyList.Add([PSCustomObject]@{
                YAMLPath = $_.Path
                YAMLValue = $_.Value
                ParameterName = ($_.Path | ConvertYAMLPathTo-Parameter).ParameterLabel
            })
    }


    <#
    $regex = [regex]::New("^(.+:)(()|( ))('%%.+%%')")
    $arrNumber = 0

    $Template = Get-Content $TemplateFilePath | ForEach-Object {

        # Parse the regex. Extract the name and the value.
        # Create an object containing that infomation with the array number
        # This will be used to build the prompts
        $results = $regex.Matches($_) 
        # If nothing was found, increment the counter and skip       
        if ($results.count -eq 0) {
            $arrNumber++
            return 
        }

        $PropertyList.Add([PSCustomObject]@{
            YAMLName = $results.Groups[1].Value.Trim()
            YAMLValue = $results.Groups[-1].Value.Trim().Trim('''')
            IndexNumber = $arrNumber
            Name = $results.Groups[1].Value.Trim().Trim(':')
        })

        # Increment the counter
        $arrNumber++

    }

    #>
    
    $PropertyList

}