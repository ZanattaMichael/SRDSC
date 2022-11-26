function Resolve-YamlItem {
<#
.Description
Resolve-Yaml item is used to enumerate the datum directory strcuture for yml files and produce 
a formatted object that is used by Resolve-DatumItem to match with the associated variables.

The properties are:

ItemPath = The file path (excluding the extention) to the YAML file.
TopLevelParent = The source directory. This is not the 'sources' directory, but
                the subdirectory nested below it.
ItemName = The filename with the extension removed.
Depth = The directory depth relative to the TopLevelParent.

.PARAMETER FilePath
The 'sources' directory filepath within the datum module.

.EXAMPLE

Resolve-YamlItem 'C:\Datum\Sources'

.SYNOPSIS
Enumerates the datum sources file path and returns a formatted object.
#>     
    [CmdletBinding()]
    param (
        [Parameter()]
        [String]
        $FilePath
    )

    Get-ChildItem -LiteralPath $FilePath -Recurse -Filter *.yml | Select-Object @{
        Name='ItemPath'
        Exp={
            $_.Fullname.replace('.yml','').replace($FilePath,'')
        }
    },
    @{
        Name = "TopLevelParent"
        Exp = {
            ($_.Fullname.replace($FilePath,'') -split '\\')[1]
        }
    },
    @{
        Name='ItemName'
        Exp={
            $_.Name.replace('.yml','')
        }
    },
    @{
        Name='Depth'
        Exp={
            ($_.Fullname.replace($FilePath,'') -split '\\').Count - 1
        }
    }

}
