#region ConvertTo-PowerShellParameter
function ConvertTo-PowerShellParameter {
<#
.Description
This function takes the formatted Datum (Containing enumerated values) and Template configuration
and constructs PowerShell parameters that can be used by the 'New-VirtualMachine' PowerShell Script.
It's important to understand that datum is the authortative winner for duplicate items with the node template
file, unless the node template has '%%SR_PARAM_OVERRIDE%%' set in the value.
This is to address pre-existing datum paramters (i.e NodeName) that should be prompted for user input,
otherwise the script would only allow you to select existing nodes that are present in the configuration.
(Not useful, when your trying to create a new machine)

For it to accuratly to join the parameters together, it needs to perform the following logic:

1. Retrive all Datum Configuration Paramters that IS AUTHORATATIVE (i.e It could have a duplicate, and if it does
   the node template configuration dosen't have 'SR_PARAM_OVERRIDE' specified.)
2. Retrive all the Node Template Configuration Parameters that aren't authoritative (or not in the authoritative list).
3. Iterate through all the enumerate non-authoritative Node Template Configuration Paramters
   and construct the PowerShell parameter.
   
   During this process it also serializes the (YAML) the Parameter Name and PowerShell .NET property
   path the the matching object as JSON.

   Note The generated script can uses this data to locate and set the paramter value within the Node Template Configuration.
   (See Get-ASScriptParameters)
   
4. Iterate through all the authoritative datum configuration paramters and construct paramters
   with prefilled data stored as values within the ValidateSet attribute
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
            $null = $sb.AppendFormat("`t[ValidateNotNullOrEmpty()]`n")
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