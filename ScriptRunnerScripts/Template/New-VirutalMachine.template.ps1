
    %%PARAMETER%%

$NodeFilePath = '%%NODEFILEPATH%%'
$NodeTemplateFileConfigurationPath = '%%AD_SOFTWARE%%'

#
#
$ParameterNames = Get-ASTScriptParameters -ScriptPath $MyInvocation.MyCommand.Path

#
# Get the NodeConfigurationPath Paramter Items
$ParamtersToSubstitute = Get-NodeTemplateConfigParams -TemplateFilePath $NodeTemplateFileConfigurationPath
$NodeTemplateFile = Get-Content -LiteralPath $NodeTemplateFileConfigurationPath

#
# Iterate through each of the NodeConfiguration Items and interpolate the items using the arrayIndex Property.
# This simplifies the logic to a replacement, rather then a lookup and replace.
$ParamtersToSubstitute | ForEach-Object {

    # Perform a lookup of the variable to see if it exists
    # If it does, good news!
    $lookupVar = Get-Variable -Name $_.Name -ErrorAction Stop

    # Perform a string intpolation
    $NodeTemplateFile[$_.IndexNumber] = 
        $NodeTemplateFile[$_.IndexNumber].Replace(
            $_.YAMLValue, 
            $lookupVar.value
        )

}

#
# Write the output of the file
$NodeTemplateFile | Set-Content -LiteralPath $NodeFilePath