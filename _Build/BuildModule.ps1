#Requires -Version 7.0

Write-Verbose "Building PowerShell Module:"

$BuildDirectory = Split-Path -parent $PSCommandPath
$BuildModuleDirectory = [System.IO.Path]::Join($BuildDirectory, "SRDSC")
$BuildModulePSMFile = [System.IO.Path]::Join($BuildModuleDirectory, "SRDSC.psm1")
$BuildModulePSDFile = [System.IO.Path]::Join($BuildModuleDirectory, "SRDSC.psd1")

$ModuleDirectory = [System.IO.Path]::Join((Split-Path $BuildDirectory -Parent),'Module')
$ModuleVersion = Get-Content -Path (Join-Path -Path $BuildDirectory -ChildPath '.\BuildVersion.txt' ) | Select-Object -Last 1

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
    ModuleVersion = $ModuleVersion -replace '\-\w+', ''
    Description = "Script Runner meet Desired State Configuration! Desired State Configuration meet Script Runner! SRDSC is a PowerShell Module that integrates Script Runner's portal with Desired State Configuration (using the DSC Toolbox with Datum). It's intention is to enable non-PowerShell users to create infrastructure services, abstracting away the complexities of understanding CaC (Configuration as Code) while Infrastructure teams retain control over key services."
    PowerShellVersion = '5.1'
    RequiredModules = 'powershell-yaml','xPSDesiredStateConfiguration'
    FunctionsToExport = @()
}

#
# Locate all functions that need to be exported.

Get-ChildItem "$ModuleDirectory\Public" -Recurse -File | Select-Object {
    $ModuleManifestParams.FunctionsToExport += $_.BaseName
}
Get-ChildItem "$ModuleDirectory\Private" -Recurse -File | ForEach-Object {
    if ((Get-Content $_.FullName) -match 'Export-ModuleMember') {
        $ModuleManifestParams.FunctionsToExport += $_.BaseName
    }
}

#
# Create Module Manifest
#

New-ModuleManifest @ModuleManifestParams

#
# New-ModuleManifest and Update-ModuleManifest isn't correctly
# setting the hashtable properties.
# Manually set the string till this is fixed.

if ($ModuleVersion -match '\-\w+') {

    $value = ($Matches.0).TrimStart('-')

    # Update the manifest file manually
    (Get-Content -LiteralPath $BuildModulePSDFile) -replace "# Prerelease = ''", "Prerelease = '$value'" |
    Set-Content -LiteralPath $BuildModulePSDFile
    
    'Write-Warning ''You are running a pre-release version of SRDSC. Please post bugs/issues to: "https://github.com/ZanattaMichael/SRDSC"''' |
    Add-Content -LiteralPath $BuildModulePSMFile

}