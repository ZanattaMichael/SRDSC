param([Switch]$CI)

$Location = Split-Path -Path (Get-Location) -Leaf
# Is the Executing Path of the Script inside the Tests Directory
if ($Location -eq 'Tests') {
    # Update the Root Path
    $RootPath = Split-Path -Path (Get-Location) -Parent
} else {
    $RootPath = (Get-Location).Path
}

# Set a Script Variable that sets the tests root path. This is used in Mocking with HTML
$Global:TestRootPath = Join-Path -Path $RootPath -ChildPath "Tests"

# Dot Source Functions used for mocking
$params = @{
    LiteralPath = "{0}\Functions" -f $Global:TestRootPath
    File = $true
}
Get-ChildItem @params | ForEach-Object { . $_.FullName }

$UpdatedPath = Join-Path -Path $RootPath -ChildPath '_build\LocalLoader.ps1' 

if ($IsCoreCLR -and $CI) {
    write-host $UpdatedPath
    $UpdatedPath = $UpdatedPath.Replace('/SRDSC/SRDSC/', '/SRDSC/')
}

# Invoke the Local Loader and Point it to the Module Directory
. $UpdatedPath $RootPath

# Invoke the Pester Tests
Invoke-Pester -Path (Join-Path -Path $Global:TestRootPath -ChildPath 'Private') -CI:$CI
Invoke-Pester -Path (Join-Path -Path $Global:TestRootPath -ChildPath 'Public') -CI:$CI
