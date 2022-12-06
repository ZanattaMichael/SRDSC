#
# Test if Git is Installed

try {
    git --version
} catch {
    Throw "Git is required for SRDSC. Please install git."
    return
}

#
# Starting processing the module

$parent = (Split-Path $MyInvocation.MyCommand.Path -Parent)

# Set isModule to true to enable module member export
$isModule = $true

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
    Write-Host "Module Loaded: Use Initialize-SRDSC to setup and configure the module." -ForegroundColor Green
    return
}

#
# Load the configuration
$CLIXML = Import-Clixml $ConfigurationPath
$params = @{
    DatumModulePath = $CLIXML.DatumModulePath
    ScriptRunnerModulePath = $CLIXML.ScriptRunnerModulePath
    ScriptRunnerServerPath = $CLIXML.ScriptRunnerServerPath
    PullServerRegistrationKey = $CLIXML.PullServerRegistrationKey
    DSCPullServer = $CLIXML.DSCPullServer
    DSCPullServerHTTP = $CLIXML.DSCPullServerHTTP
    ScriptRunnerURL = $CLIXML.ScriptRunnerURL    
}

# Load the Global Settings
Set-ModuleParameters @params
