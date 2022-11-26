function Resolve-DatumItem
{
<#
.Description
Processes each datum resolution precidence, splits the path into single object entities
by recusing backwards through the resolution precidence file structure.

For Example:

Source: - AllNodes\$($Node.Environment)\$($Node.NodeName)
Would be:

- $($Node.NodeName)
- $($Node.Environment)
- AllNodes

Resolve-Datum Item also locates and matches variables from the file structure and returns a formatted object containing:

Source: - AllNodes\$($Node.Environment)\$($Node.NodeName)

1. [String] ItemPath - The Path to the item
2. [String] ItemName - The Name of the Item
3. [String] ItemScriptPath - Formatted Item Path (removing '$($Node.' from the ItemPath))
4. [String] Depth - The directory depth. This is used for matching YAML values from the correct directory
5. [String] Top-level Parent - Root top-level parent directory.
6. [Bool] isVar - A booleen switch describing if the ItemName is a variable.
7. [Array] values - (isVar -eq $true) A list of matched files. 
    Matching is based on the 'Depth' and the 'TopLevelParent' from the file structure (YamlItems).
    
.PARAMETER DatumPath
This is the resolution precidence path [string] that was loaded with. (i.e)  

- AllNodes\$($Node.Environment)\$($Node.NodeName)

.PARAMETER YamlItems

The object output from Resolve-YamlItem

.EXAMPLE

$DatumConfiguration.ResolutionPrecedence | Resolve-DatumItem -YamlItems $YamlItems

.SYNOPSIS
Loads the Datum resolution precidence, locates and matches variables from the file structure
and returns an object containing datum variables and associated 

#>        
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

            # Add metadata about the object path into memory.
            $items.Add(@{
                ItemPath = '\{0}' -f $tempPath
                ItemName = Split-Path $tempPath -Leaf
                ItemScriptPath = ('\{0}' -f $tempPath -replace '(?<=\\)[\w\$\(\)]+\.(\w+)\)', '%$1').Replace('%','$')
                TopLevelParent = ('{0}' -f $tempPath -split '\\')[0]
                Depth = ($tempPath -split '\\').Count
                isVar = (Split-Path $tempPath -Leaf) -like '$($*'
                values = $null
            })

            # Split the path to get the parent and recurse.
            $tempPath = Split-Path $tempPath
        } Until ([String]::IsNullOrEmpty($tempPath))

        # Populate the values from YamlItems
        ForEach($item in $items) {
            # The Datum Item enumerated must be a variable,
            # Otherwise skip.
            if (-not($item.isVar)) { continue }
            # Populate the values based on the depth and the toplevelparent.
            # This ensures that there are no contamination from other directories making it in there.
            $item.values = $($YamlItems | Where-Object {
                ($item.Depth -eq $_.Depth) -and ($item.TopLevelParent -eq $_.TopLevelParent)
            })
        }

        # Finally, flatten the object structure, by iterating through each of the items
        # enumerated in the list and adding them to the output object.
        $items | ForEach-Object { $datumList.Add([PSCustomObject]$_) }

    }

    end
    {
        write-output $datumList
    }

}
