function Resolve-YamlItem {
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
