function Format-YAML {
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