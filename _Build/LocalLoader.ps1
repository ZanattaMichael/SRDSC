[CmdletBinding()]
param(
    # Module Path
    [parameter()]
    [String]
    $ModulePath,
    # Load Configuration into Memory
    [Parameter()]
    [Switch]
    $LoadConfiguration,
    # Bypass DSC Configuration Entries
    [Parameter()]
    [Switch]
    $CI
)

# Set ModulePath if the parameter isn't set.
if ([String]::IsNullOrEmpty($ModulePath)) {
    $path = $MyInvocation.MyCommand.Path
    $ModulePath = Split-Path (Split-Path $path -Parent) -Parent
}

Write-Host "[LocalLoader] ModulePath: $ModulePath"

# Bypass DSC Configurations
if (-not($CI.IsPresent)) {
    # Load DSC Configurations
    Get-ChildItem -LiteralPath (Join-Path $ModulePath -ChildPath 'Module\DSCConfiguration') -Recurse -File | ForEach-Object {
        Write-Host "[LocalLoader] Loading DSC Resource: $($_.FullName)" -ForegroundColor DarkBlue
        . $_.FullName 
    }
}

# Load Private Functions
Get-ChildItem -LiteralPath (Join-Path $ModulePath -ChildPath 'Module\Private') -Recurse -File | ForEach-Object {
    Write-Host "[LocalLoader] Loading Private Function: $($_.FullName)" -ForegroundColor Cyan
    . $_.FullName 
}

# Load Public Functions
Get-ChildItem -LiteralPath (Join-Path $ModulePath -ChildPath 'Module\Public') -Recurse -File | ForEach-Object {
    Write-Host "[LocalLoader] Loading Public Function: $($_.FullName)" -ForegroundColor Blue
    . $_.FullName 
}

# Load Testing Functions
Get-ChildItem -LiteralPath (Join-Path $ModulePath -ChildPath 'Tests\Functions') -Recurse -File | ForEach-Object {
    Write-Host "[LocalLoader] Loading Public Function: $($_.FullName)" -ForegroundColor Yellow
    . $_.FullName 
}

if ($LoadConfiguration.IsPresent) {

    Write-Host "[LocalLoader] Loading Configuration"

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
        ScriptRunnerServerPath = $CLIXML.ScriptRunnerServerPath
        PullServerRegistrationKey = $CLIXML.PullServerRegistrationKey
        DSCPullServer = $CLIXML.DSCPullServer
        DSCPullServerHTTP = $CLIXML.DSCPullServerHTTP
    }

    try {
        # Load the Global Settings
        Set-ModuleParameters @params 
    } catch {
        Write-Error "Configuration Import Failed. Use 'Register-LocalConfiguration' to redeploy."
        Write-Error $_
    }

}