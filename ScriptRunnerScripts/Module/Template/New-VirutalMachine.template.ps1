[CmdletBinding()]
param (
    #%%PARAMETER%%
)

$NodeFilePath = "%%NODEFILEPATH%%"
$NodeTemplateConfigurationPath = "%%NODETEMPLATECONFIGURATION%%"

#
# Load the ParameterNames
$ScriptParameterData = Get-ASTScriptParameters -ScriptPath $MyInvocation.MyCommand.Path

#
# Get the NodeConfigurationPath Paramter Items
$ParamtersToSubstitute = Get-NodeTemplateConfigParams -TemplateFilePath $NodeTemplateConfigurationPath
$FormattedYAMLTemplate = Get-Content -LiteralPath $NodeTemplateConfigurationPath | ConvertFrom-Yaml -Ordered

#
# Iterate through each of the NodeConfiguration Items and interpolate the items using the arrayIndex Property.
# This simplifies the logic to a replacement, rather then a lookup and replace.

ForEach ($ParameterName in $ScriptParameterData.Parameters) {

	# Perform a lookup to get the parameter value
	$lookupVar = Get-Variable -Name $ParameterName.TrimStart('$') -ErrorAction Stop

	# Perform a lookup in the parameter JSON data to see if it exists.
	[array]$matched = $ScriptParameterData.YAMLData | Where-Object {
		('${0}' -f $_.Name) -eq $ParameterName
	}
	
    #
    # If there is a match, associate the lookup according the metadata.
    # and then continue.
	if ($matched.count -eq 1) {
        [ScriptBlock]::Create(('{0} = "{1}"' -f $matched.LookupValue, $lookupVar.value)).Invoke()
        continue
	}

    #
    # Otherwise, just perform a regualar lookup and replace.
    [Array]$matched = $ParamtersToSubstitute | Where-Object {
        ('${0}' -f $_.ParameterName) -eq $ParameterName
    }

	#
	# Validate if there is a match. If not, skip!
	if ($matched.count -eq 0) { continue }	
    [ScriptBlock]::Create(('{0} = "{1}"' -f $Matched.YAMLPath, $lookupVar.value)).Invoke()

}

#
# Write the output of the file
$FormattedYAMLTemplate | Format-YAML -Property $Global:SRDSC.DatumModule.YAMLSortOrder | ConvertTo-Yaml | Set-Content -LiteralPath $NodeFilePath

#
# Onboard the Virtual Machine into Desired State Configuration

Add-SRDSCNode -NodeName $NodeName
