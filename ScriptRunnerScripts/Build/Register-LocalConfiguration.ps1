<#
.SYNOPSIS
    Creates development configuration on SRDSC used for local testing.
.EXAMPLE
    SRDSC uses $Global:SRDSC to store configuration about the module.
    This is information pertaining to the pull server. This command
    enables you to create a local implementation to develop/test
    local aspects of the code without issues.
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [String]
    $DatumModulePath,
    [Parameter(Mandatory)]
    [String]
    $ScriptRunnerModulePath,  
    [Parameter(Mandatory)]
    [String]
    $ScriptRunnerServerPath        
)

$PSObject = [PSCustomObject]@{
    DatumModulePath = $DatumModulePath
    ScriptRunnerModulePath = $ScriptRunnerModulePath
    ScriptRunnerScriptPath = $ScriptRunnerServerPath
    PullServerRegistrationKey = "MOCK"
}

$ConfigurationPath = "{0}\PowerShell\SRDSC\Configuration.clixml" -f $Env:ProgramData
$parent = Split-Path $ConfigurationPath -Parent

# Create the directory path if it dosen't exist
if (Test-Path -LiteralPath $parent) {
    $null = New-Item -Path $parent -Force -ItemType Directory -Confirm:$false
}

$PSObject | Export-CliXML -LiteralPath $ConfigurationPath