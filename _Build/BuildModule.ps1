#Requires -Version 7.0

Write-Verbose "Building PowerShell Module:"

$BuildDirectory = Split-Path -parent $PSCommandPath
$BuildModuleDirectory = [System.IO.Path]::Join($BuildDirectory, "SRDSC")
$BuildModulePSDFile = [System.IO.Path]::Join($BuildModuleDirectory, "SRDSC.psd1")

$ModuleDirectory = [System.IO.Path]::Join((Split-Path $BuildDirectory -Parent),'Module')

$params = @{
    LiteralPath = $ModuleDirectory
    Destination = $BuildModuleDirectory
    Force = $true
    Recurse = $true
}

Copy-Item @params

$ModuleManifestParams = @{
    RootModule = 'SRDSC.psm1'
    Path = $BuildModulePSDFile
    Guid = [GUID]::NewGuid().Guid
    Author = 'Michael Zanatta'
    ModuleVersion = Get-Content -Path (Join-Path -Path $BuildDirectory -ChildPath '.\BuildVersion.txt' ) | Select-Object -Last 1
    Description = "Script Runner meet Desired State Configuration! Desired State Configuration meet Script Runner! SRDSC is a PowerShell Module that integrates Script Runner's portal with Desired State Configuration (using the DSC Toolbox with Datum). It's intention is to enable non-PowerShell users to create infrastructure services, abstracting away the complexities of understanding CaC (Configuration as Code) while Infrastructure teams retain control over key services."
    PowerShellVersion = '5.1'
    RequiredModules = 'powershell-yaml'
    FunctionsToExport = @()
}

#
# Locate all functions that need to be exported.

Get-ChildItem 'D:\Git\DSC-ScriptRunner\DSC-ScriptRunner\Module\Public' -Recurse -File | Select-Object {
    $ModuleManifestParams.FunctionsToExport += $_.BaseName
}
Get-ChildItem 'D:\Git\DSC-ScriptRunner\DSC-ScriptRunner\Module\Private' -Recurse -File | ForEach-Object {
    if ((Get-Content $_.FullName) -match 'Export-ModuleMember') {
        $ModuleManifestParams.FunctionsToExport += $_.BaseName
    }
}

#
# Create Module Manifest
#

New-ModuleManifest @ModuleManifestParams