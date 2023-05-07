function Get-NodeTemplateConfigParams {
<#
.Description
Get-NodeTemplateConfigParams imports the Node Template Configuration, formats with Format-YAMLObject
(See Format-YAMLObject) and searches for static entities within the configuration ('%%') returning
the _YAMLPATH, it's Value and Script ParameterName using ConvertYAMLPathTo-Parameter
(See ConvertYAMLPathTo-Parameter).

Get-NodeTemplateConfigParams is a private cmdlet, however it's used outside the module by 
New-VirtualMachine.ps1.

Example YAML configuration file:

NodeName: '%%SR_PARAM_OVERRIDE%%'
Environment: '[x={ $File.Directory.BaseName } =]'
Role: '%%SR_PARAM%%'
Description: '[x= "$($Node.Role) in $($Node.Environment)" =]'
Location: '%%SR_PARAM%%'
Baseline: '%%SR_PARAM%%'

.EXAMPLE
Get-NodeTemplateConfigParams -TemplateFilePath $Global:SRDSC.DatumModule.NodeTemplateFile
.SYNOPSIS
Imports the Node Template Configuration and returns a list contining static entities.
#> 
    [CmdletBinding()]
    param (
        # Parameter help description
        [Parameter(Mandatory)]
        [String]
        $TemplateFilePath
    )

    $PropertyList = [System.Collections.Generic.List[PSCustomObject]]::New()
    $YAMLTemplate = Get-Content $TemplateFilePath | ConvertFrom-Yaml
    # Format the YAMLObject adding the _YAMLPATH property.
    $FormattedYAMLTemplate = Format-YAMLObject -YAMLObject $YAMLTemplate -ObjectName 'FormattedYAMLTemplate'

    # Locate static entites that contain '%%' (%%SR_PARAM%% or %%SR_PARAM_OVERRIDE%%)
    Find-YamlValue -YAMLObject $FormattedYAMLTemplate -ValueToFind '^%%.+%%$' | ForEach-Object {
            
            # Identity if any expression was included within the Script Runner Parameter
            # For example: %%SR_PARAM&EXP=[ValidateSet()]%%
            # or: %%SR_PARAM&EXP=[ValidateSet()%%
            $null = $_.Value -match '^%%SR_((PARAM)|(OVERRIDE))&EXP=(?<exp>.+)%%$'

            $PropertyList.Add([PSCustomObject]@{
                YAMLPath = $_.Path
                YAMLValue = $_.Value
                # Parse the _YAMLPATH .NET path and convert to a PowerShell Parameter Label.
                ParameterName = ($_.Path | ConvertYAMLPathTo-Parameter).ParameterLabel
                ParameterExpression = $matches['exp']
            })
    }

    $PropertyList

}

# It's a private cmdlet, but it's used by New-VirtualMachine
if ($isModule) { Export-ModuleMember -Function Get-NodeTemplateConfigParams }