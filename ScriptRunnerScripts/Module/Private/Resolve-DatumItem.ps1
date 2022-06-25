function Resolve-DatumItem
{
    [CmdletBinding()]
    param (
        # Dataum Configuration Path Defined in the Resolution Precedence
        [Parameter(Mandatory,ValueFromPipeline)]
        [String]
        $DatumPath,
        # YAML File Items Enumerated from Resolve-YamlItem
        [Parameter(Mandatory)]
        [Object]
        $YamlItems
    )

    begin
    {
        $datumList = [System.Collections.Generic.List[PSCustomObject]]::New()
    }

    process
    {

        #
        # Reverse Recurse

        $items = [System.Collections.Generic.List[Hashtable]]::New()

        $tempPath = $DatumPath
        Do {
            $items.Add(@{
                ItemPath = '\{0}' -f $tempPath
                ItemName = Split-Path $tempPath -Leaf
                TopLevelParent = ('{0}' -f $tempPath -split '\\')[0]
                Depth = ($tempPath -split '\\').Count
                isVar = (Split-Path $tempPath -Leaf) -like '$($*'
                values = $null
            })
            $tempPath = Split-Path $tempPath
        } Until ([String]::IsNullOrEmpty($tempPath))

        # Populate Values
        ForEach($item in $items) {
            if (-not($item.isVar)) { continue }
            # Populate the values based on the depth.
            $item.values = $($YamlItems | Where-Object {
                ($item.Depth -eq $_.Depth) -and ($item.TopLevelParent -eq $_.TopLevelParent)
            })
        }

        $items | ForEach-Object { $datumList.Add([PSCustomObject]$_) }

    }

    end
    {
        write-output $datumList
    }

}
