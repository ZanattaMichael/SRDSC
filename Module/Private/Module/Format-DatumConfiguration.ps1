function Format-DatumConfiguration {
<#
.Description
Format-DatumConfiguration is the secondary merge (Read-DatumConfiguration being the first) combining
the Datum Configuration with the Node Template Configuration and formatting it.
The function creates an object with a formatted Parameter Name,
Parameter Value and isOverwritten booleen value. The isOverwritten property is used to identify 
if a Datum Parameter has been declared in the Node Template Configuration and if the matching
Note Template Configuration parameter is authoratitive over Datum. Remember, Datum Configuration
parameters have higher precidence over the node template configuration.
The Node Template Configuration is added to the output object under the TemplateConfiguration property.

.PARAMETER DatumConfiguration
Datum Object Data returned from Read-DatumConfiguration
.PARAMETER NodeTemplateConfiguration
Node Template Configuration Object Data from Get-NodeTemplateConfigParams
.EXAMPLE
    $formattedDatumParams = @{
        DatumConfiguration = $DatumConfiguration
        NodeTemplateConfiguration = Get-NodeTemplateConfigParams `
            -TemplateFilePath   $Global:SRDSC.DatumModule.NodeTemplateFile
    }

    $formattedDatumConfig = Format-DatumConfiguration @formattedDatumParams

.SYNOPSIS
Formats Datum Configuration with the Node Template Configuration
#>    
    [CmdletBinding()]
    param (
        # Datum Configuration
        [Parameter(Mandatory, ValueFromPipeline)]
        [Object]
        $DatumConfiguration,
        # Node Template Configuration
        [Parameter(Mandatory)]
        [PSCustomObject[]]
        $NodeTemplateConfiguration
    )

    $result = [PSCustomObject]@{
        TemplateFilePath = $Global:SRDSC.DatumModule.NodeTemplateFile
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
                            ($_.ParameterName -eq $ParameterName) -and ($_.YAMLValue -match '^%%SR_PARAM_OVERRIDE')
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
