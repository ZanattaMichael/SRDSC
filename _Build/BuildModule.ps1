#Requires -Version 7.0

Write-Verbose "Building PowerShell Module:"

$BuildDirectory = Split-Path -parent $PSCommandPath
$BuildModuleDirectory = [System.IO.Path]::Join($BuildDirectory, "SelMVP")
$BuildModuleFile = [System.IO.Path]::Join($BuildModuleDirectory, "Module.psm1")
$BuildModulePSDFile = [System.IO.Path]::Join($BuildModuleDirectory, "SelMVP.psd1")
$BuildModuleDirectoryLibraries = [System.IO.Path]::Join($BuildModuleDirectory)
$BuildModuleDirectoryContributions = [System.IO.Path]::Join($BuildModuleDirectory, "Contributions")

$ModuleDirectory = $BuildDirectory -replace "Build","Module"
$ModuleFile = [System.IO.Path]::Join($ModuleDirectory, "Module.psm1")
$ModuleDirectoryPrivateFunctions = [System.IO.Path]::Join($ModuleDirectory, "Functions","Private")
$ModuleDirectoryPublicFunctions = [System.IO.Path]::Join($ModuleDirectory, "Functions","Public","Cmdlets")
$ModuleDirectoryDLLibraries = [System.IO.Path]::Join($ModuleDirectory, "Libraries")
$ModuleDirectoryContributions = [System.IO.Path]::Join($ModuleDirectory, "Functions","Public","Contributions")

$ModuleResourceData = [System.IO.Path]::Join($ModuleDirectory, "Resources")

$ModuleManifestParams = @{
    RootModule = 'Module.psm1'
    Path = $BuildModulePSDFile
    Guid = [GUID]::NewGuid().Guid
    Author = 'Michael.Zanatta'
    ModuleVersion = Get-Content -Path (Join-Path -Path $BuildDirectory -ChildPath '.\BuildVersion.txt' ) | Select-Object -Last 1
    Description = ""
    PowerShellVersion = '5.1'
    RequiredModules = ''
    NestedModules = ''
    FunctionsToExport = @()
    RequiredAssemblies = "Libraries\HTMLAgilityPack\HtmlAgilityPack.dll"
}

Write-Debug "`$BuildDirectory: $BuildDirectory"
Write-Debug "`$BuildModuleDirectory: $BuildModuleDirectory"
Write-Debug "`$BuildModuleDirectoryLibraries: $BuildModuleDirectoryLibraries"
Write-Debug "`$BuildModuleDirectoryContributions: $BuildModuleDirectoryContributions"
Write-Debug "`$ModuleFile: $ModuleFile"
Write-Debug "`$ModuleDirectoryPrivateFunctions: $ModuleDirectoryPrivateFunctions"
Write-Debug "`$ModuleDirectoryPublicFunctions: $ModuleDirectoryPublicFunctions"
Write-Debug "`$ModuleDirectoryDLLibraries: $ModuleDirectoryDLLibraries"
Write-Debug "`$ModuleDirectoryContributions: $ModuleDirectoryContributions"
Write-Debug "`$ModuleDirectoryLocalizedData: $ModuleDirectoryLocalizedData"

#
# Create Module Manifest
#

New-ModuleManifest @ModuleManifestParams