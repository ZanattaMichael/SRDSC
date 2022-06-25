function Format-DatumConfiguration {
    [CmdletBinding()]
    param (
        # Datum Configuration
        [Parameter(Mandatory, ValueFromPipeline)]
        [Object]
        $DatumConfiguration
    )

    $DatumConfiguration | Where-Object {$_.isVar} |
        Group-Object -Property ItemName | ForEach-Object {
            ($_.Group | Where-Object {$_.Values.Count -ne 0 })
        } | Select-Object *, @{
            Name = 'ParameterName'
            Exp = { ($_.ItemName -replace '(^\$\(\$Node.)','').Replace(')','') }
        },
        @{
            Name = 'ParameterValues'
            Exp = { $_.Values.ItemName | Sort-Object -Unique }
        }

}
