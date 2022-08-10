
function Publish-SRActionScript {
    [CmdletBinding()]
    param (
        [Parameter()]
        [String]
        $OutputFilePath
    )

    #
    # Read the Datum Configuration
    $params = @{
        DatumConfigurationFile = $Global:SRDSC.DatumModule.ConfigurationFile
        DatumConfigurationPath = $Global:SRDSC.DatumModule.ConfigurationPath
    }

    #
    # Format the Datum Configuration and include the content from the template configuration file.
    $DatumConfiguration = Read-DatumConfiguration @params
    $formattedDatumParams = @{
        DatumConfiguration = $DatumConfiguration
        NodeTemplateConfiguration = Get-NodeTemplateConfigParams -TemplateFilePath $Global:SRDSC.ScriptRunner.NodeTemplateFile
    }

    $formattedDatumConfig = Format-DatumConfiguration @formattedDatumParams

    #
    # Items that are specificed in the NodeTemplateConfiguration, with SR_PARAM_OVERRIDE have higher precidence
    # then datum configuration items.
    # A notable example of this is NodeName, which needs to be prompted for since it pertains to existing items.

    # Create the parameters
    $paramsString = $formattedDatumConfig | ConvertTo-PowerShellParameter

    # Load the New-VirtualMachine.template.ps1 file.
    $templateFile = Get-Content -LiteralPath $Global:SRDSC.ScriptRunner.ScriptTemplates.NewVMTemplate

    # Interpolate the Parameters into the Script
    $templateFile = $templateFile -replace '#%%PARAMETER%%', $paramsString

    # Interpolate the Node file path
    $nodeFilePath = ($DatumConfiguration | Where-Object {($_.TopLevelParent -eq 'AllNodes') -and ($null -ne $_.Values)})
    $templateFile = $templateFile -replace '%%NODEFILEPATH%%', ('{0}\{1}.yml' -f $Global:SRDSC.DatumModule.SourcePath, $nodeFilePath.ItemScriptPath)

    # Interpolate the Template File path
    $templateFile = $templateFile -replace '%%NODETEMPLATECONFIGURATION%%', $Global:SRDSC.ScriptRunner.NodeTemplateFile

    # Write the template file to the designated output file path.
    $templateFile | Out-File -FilePath $OutputFilePath -Force

}