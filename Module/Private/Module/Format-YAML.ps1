function Format-YAML {
<#
.Description
When converting a Hashtable directly into YAML to create a datum NODE file, it's not ordered correctly
and causes readability issues. This function resolves this issue by converting the Hashtable into an
PSObject and using Select-Object to order the properties.
.PARAMETER Table
The Hashtable to format.
.PARAMETER Property
Ordered properties.
.EXAMPLE

    $FormattedYAMLTemplate | Format-YAML -Property $Global:SRDSC.DatumModule.YAMLSortOrder 

.SYNOPSIS
Formats a Hashtable into an order PowerShell Object ready for export into yaml.
#>    
    [CmdletBinding()]
    param (
        # HashTable
        [Parameter(Mandatory, ValueFromPipeline)]
        [HashTable]
        $Table,
        # Properties to filter by
        [Parameter(Mandatory)]
        [String[]]
        $Property
    )

    process {
        
        [PSCustomObject]$Table | Select-Object -Property $Property

    }
    
}

if ($isModule) { Export-ModuleMember 'Format-YAML' }