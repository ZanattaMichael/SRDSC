function ConvertTo-PowerShellParameter {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [Object]
        $DatumConfiguration
    )

    Begin {
        $sb = [System.Text.StringBuilder]::new()
    }

    Process {

        forEach ($configuration in $DatumConfiguration) {
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
