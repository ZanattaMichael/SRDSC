function Format-DatumConfiguration {
    [CmdletBinding()]
    param (
        # Datum Configuration
        [Parameter(Mandatory, ValueFromPipeline)]
        [Object]
        $DatumConfiguration,
        [Parameter(Mandatory)]
        [PSCustomObject[]]
        $NodeTemplateConfiguration
    )

    $result = [PSCustomObject]@{
        TemplateFilePath = $Global:SRDSC.ScriptRunner.NodeTemplateFile
        #
        # Format the Datum Configuration adding parameter names and values
        DatumConfiguration = $DatumConfiguration | Where-Object {$_.isVar} |
                Group-Object -Property ItemName | ForEach-Object {
                    ($_.Group | Where-Object {$_.Values.Count -ne 0 })
                } | Select-Object *, @{
                    Name = 'ParameterName'
                    Exp = { ($_.ItemName -replace '(^\$\(\$Node.)','').Replace(')','') }
                },
                @{
                    Name = 'ParameterValues'
                    Exp = { $_.Values.ItemName | Sort-Object -Unique }
                },
                @{
                    Name = 'isOverwritten'
                    Exp = { 
                        $ParameterName = ($_.ItemName -replace '(^\$\(\$Node.)','').Replace(')','')                        
                        [Array]$item = $NodeTemplateConfiguration | Where-Object {
                            ($_.ParameterName -eq $ParameterName) -and ($_.YAMLValue -eq '%%SR_PARAM_OVERRIDE%%')
                        }
                        $item.count -gt 0
                    }
                }
        #
        # Also include the template file overrides
        TemplateConfiguration = $NodeTemplateConfiguration    
    }

    return $result


}
