function Get-NodeTemplateConfigParams {
<#
.Description
Get-NodeTemplateConfigParams retrieves the Node Template Configuration from a specified file path and
identifies static entities within the configuration that are marked by '%% %%'.
It then returns the YAML path, value, and script parameter name of each static entity
using ConvertYAMLPathTo-Parameter. The YAML configuration is not formatted with Format-YAMLObject 
in this optimized version of the code, as it uses Get-Content and ConvertFrom-Yaml instead.

Although Get-NodeTemplateConfigParams is a private cmdlet, it is utilized outside of the module by New-VirtualMachine.ps1.

Example YAML configuration file:

NodeName: '%%SR_PARAM_OVERRIDE%%'
Environment: '[x={ $File.Directory.BaseName } =]'
Role: '%%SR_PARAM%%'
Description: '[x= "$($Node.Role) in $($Node.Environment)" =]'
Location: '%%SR_PARAM%%'
Baseline: '%%SR_PARAM%%'

.EXAMPLE
Get-NodeTemplateConfigParams -TemplateFilePath $Global:SRDSC.DatumModule.NodeTemplateFile

Get-NodeTemplateConfigParams is a PowerShell command that retrieves the configuration parameters for a node template file.
In this case, the TemplateFilePath parameter specifies the path of the node template file which is stored in the 
$Global:SRDSC.DatumModule.NodeTemplateFile variable. 
When executed, the command will read the specified node template file and return its configuration parameters.

.SYNOPSIS
This PowerShell command imports the Node Template Configuration
and generates a list that contains static entities as specified in the configuration file.

#> 
  # This line specifies that this is a PowerShell cmdlet with optional parameters.
  [CmdletBinding()]
  
  # This block defines the parameter(s) that will be accepted by the script.
  param (
      # The file path to the template file is required, and must be specified as a string.
      [Parameter(Mandatory)]
      [String]
      $TemplateFilePath
  )
  
  # This creates an empty list of PSCustomObjects to hold the static entities found in the YAML template.
  $StaticEntities = [System.Collections.Generic.List[PSCustomObject]]::New()
  
  # This reads the content of the YAML template file and converts it to a PowerShell object.
  $YAMLTemplate = Get-Content $TemplateFilePath | ConvertFrom-Yaml
  
  # This formats the YAML object, adding a _YAMLPATH property for each node to make it easier to reference them later.
  $FormattedYAMLTemplate = Format-YAMLObject -YAMLObject $YAMLTemplate -ObjectName 'FormattedYAMLTemplate'
  
  # This searches for any YAML values that contain '%%SR_PARAM%%' or '%%SR_PARAM_OVERRIDE%%', which indicate static entities.
  Find-YamlValue -YAMLObject $FormattedYAMLTemplate -ValueToFind '^%%SR_((PARAM)|(PARAM_OVERRIDE)).+%%$' | ForEach-Object {
      
      # This checks if there is an expression included within the Script Runner Parameter.
      $result = $_.Value -match '^%%SR_((PARAM)|(PARAM_OVERRIDE))&EXP=(?<exp>.+)%%$'
  
      # This adds a new PSCustomObject to the $StaticEntities list containing information about the static entity.
      $StaticEntities.Add([PSCustomObject]@{
          YAMLPath = $_.Path
          YAMLValue = $_.Value
          # This converts the _YAMLPATH .NET path to a PowerShell parameter label.
          ParameterName = ($_.Path | ConvertYAMLPathTo-Parameter).ParameterLabel
          # This adds the expression to the PSCustomObject if there is one, otherwise sets it to null.
          ParameterExpression = $(if ($result -eq $true) { $matches['exp'] } else { $null })
      })
  }
  
  # This outputs the list of static entities found in the YAML template.
  $StaticEntities
    
}

# It's a private cmdlet, but it's used by New-VirtualMachine
if ($isModule) { Export-ModuleMember -Function Get-NodeTemplateConfigParams }