(Split-Path $MyInvocation.MyCommand.Path -Parent) | Get-ChildItem -Recurse -File | Where-Object {$_.BaseName -ne 'init'} | ForEach-Object {
    . $_.FullName 
}