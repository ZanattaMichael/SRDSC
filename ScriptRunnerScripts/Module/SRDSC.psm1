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
# Test if the configuration file exists

$ConfigurationPath = "{0}\PowerShell\SRDSC\Configuration.clixml" -f $Env:ProgramData

if (-not(Test-Path -LiteralPath $ConfigurationPath)) {
    Write-Warning "Module Loaded: Use Initialize-SRDSC to setup and configure the module."
    return
}

#
# Load the configuration
$CLIXML = Import-Clixml $ConfigurationPath
$params = @{
    DatumModulePath = $CLIXML.DatumModulePath
    ScriptRunnerModulePath = $CLIXML.ScriptRunnerModulePath
    ScriptRunnerServerPath = $CLIXML.ScriptRunnerScriptPath
    PullServerRegistrationKey = $CLIXML.PullServerRegistrationKey
}

# Load the Global Settings
Set-ModuleParameters @params
