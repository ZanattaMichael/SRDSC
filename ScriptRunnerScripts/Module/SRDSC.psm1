$parent = (Split-Path $MyInvocation.MyCommand.Path -Parent)

Get-ChildItem -LiteralPath (Join-Path $parent -ChildPath 'DSCConfiguration') -Recurse -File | ForEach-Object {
    . $_.FullName 
}

Get-ChildItem -LiteralPath (Join-Path $parent -ChildPath 'Private') -Recurse -File | ForEach-Object {
    . $_.FullName 
}

Get-ChildItem -LiteralPath (Join-Path $parent -ChildPath 'Public') -Recurse -File | ForEach-Object {
    . $_.FullName 
}

#
# 

Set-ModuleParameters -DatumModulePath 'D:\Git\DSC-ScriptRunner\DSC-ScriptRunner' -ScriptRunnerModulePath 'D:\Git\DSC-ScriptRunner\DSC-ScriptRunner\ScriptRunnerScripts\Module'