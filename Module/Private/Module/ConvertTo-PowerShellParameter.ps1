#region ConvertTo-PowerShellParameter
function ConvertTo-PowerShellParameter {
<#
.Description
This function is responsible for creating PowerShell parameters that can be used by the 'New-VirtualMachine' PowerShell script. It takes in the formatted Datum, which contains enumerated values, and the Template configuration.

It's important to note that the Datum is considered the authoritative winner for duplicate items with the node template file, unless the node template has '%%SR_PARAM_OVERRIDE%%' set in the value. This is done to address pre-existing datum parameters (such as NodeName) that should be prompted for user input. Otherwise, the script would only allow you to select existing nodes that are present in the configuration, which isn't useful when trying to create a new machine.

To accurately join the parameters together, the function performs the following logic:

1. Retrieve all Datum Configuration Parameters that are authoritative (i.e., they could have a duplicate, and if they do, the node template configuration doesn't have 'SR_PARAM_OVERRIDE' specified).
2. Retrieve all the Node Template Configuration Parameters that aren't authoritative (or not in the authoritative list).
3. Iterate through all the non-authoritative Node Template Configuration Parameters and construct the PowerShell parameter. During this process, it also serializes the YAML Parameter Name and PowerShell .NET property path to the matching object as JSON. Note that the generated script can use this data to locate and set the parameter value within the Node Template Configuration (see Get-ASScriptParameters).
4. Iterate through all the authoritative datum configuration parameters and construct parameters with prefilled data stored as values within the ValidateSet attribute.
5. Return the string back to the caller.

.PARAMETER ConfigurationTemplates
A Custom PSObject that's returned from Format-DatumConfiguration
.EXAMPLE

    (From Publish-SRActionScript)

    # Create the parameters
    $paramsString = $formattedDatumConfig | ConvertTo-PowerShellParameter

.SYNOPSIS
Converts the Datum and Template configuration into PowerShell Script Parameters.
#>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [Object]
        $ConfigurationTemplates
    )

    Begin {
        $sb = [System.Text.StringBuilder]::new()
    }

    Process {

        #
        # If the configuration is null, throw an error.
        if ($null -eq $ConfigurationTemplates) {
            throw "ConfigurationTemplates cannot be null"
        }

        #
        # If the DatumConfiguration is null, throw an error.
        if (($null -eq $ConfigurationTemplates.DatumConfiguration) -or ($ConfigurationTemplates.DatumConfiguration.Count -eq 0)) {
            throw "ConfigurationTemplates.DatumConfiguration cannot be null"
        }

        #
        # If the TemplateConfiguration is null, throw an error.
        if (($null -eq $ConfigurationTemplates.TemplateConfiguration) -or ($ConfigurationTemplates.TemplateConfiguration.Count -eq 0)) {
            throw "ConfigurationTemplates.TemplateConfiguration cannot be null"
        }

        #
        # NodeTemplateConfiguration items have higher precidence then automatic values. 
        # However it's possible to define positions within the configuration.

        $authoritativeDatumConfiguration = $ConfigurationTemplates.DatumConfiguration | Where-Object { -not($_.isOverwritten) }
        $authoritativeTemplateConfiguration = $ConfigurationTemplates.TemplateConfiguration | Where-Object {
            $_.ParameterName -notin $authoritativeDatumConfiguration.ParameterName
        }
        
        #
        # Iterate through NodeTemplateConfiguration
        # Exclude Duplicate items
        forEach ($configuration in $authoritativeTemplateConfiguration) {

            # Create a JSON structure containing the parametername with the lookup value.
            # This makes it a lot easier to deseralize.
            $YAMLObject = @{
                Name = $configuration.ParameterName
                LookupValue = $configuration.YAMLPath
            } | ConvertTo-Json -Compress

            $null = $sb.AppendLine("`t[Parameter(Mandatory)]")
            $null = $sb.AppendFormat("`t#JSONData: {0} `n", $YAMLObject)

            # If there was custom expression validation on the parameter, add it in.
            if ($null -eq $configuration.ParameterExpression) {
                $null = $sb.AppendFormat("`t$($configuration.ParameterExpression)`n")
            } else {
                # Otherwise add 'NotNullOrEmpty()'
                $null = $sb.AppendFormat("`t[ValidateNotNullOrEmpty()]`n")
            }

            $null = $sb.AppendLine("`t[String]")
            $null = $sb.AppendFormat("`t`${0},`n", $configuration.ParameterName)
        }        

        #
        # Iterate through the Datum Configuration Items
        forEach ($configuration in $authoritativeDatumConfiguration) {
            $null = $sb.AppendLine("`t[Parameter(Mandatory)]")
            $null = $sb.AppendFormat("`t[ValidateSet('{0}')]`n",$configuration.ParameterValues -join ''',''')
            $null = $sb.AppendLine("`t[String]")
            $null = $sb.AppendFormat("`t`${0},`n", $configuration.ParameterName)
        }

    }

    End {
        $sb.ToString().TrimEnd().TrimEnd(',')
    }

}
#endregion ConvertTo-PowerShellParameter