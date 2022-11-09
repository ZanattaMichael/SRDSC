function ConvertTo-PowerShellParameter {
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
