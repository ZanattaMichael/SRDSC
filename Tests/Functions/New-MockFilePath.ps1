Function New-MockFilePath ($Path) {
    return [PSCustomObject]@{
        FullName = $Path
        Name = Split-Path $Path -Leaf
    }    
}
