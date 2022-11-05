Set-ModuleParameters -DatumModulePath 'D:\Git\DSC-ScriptRunner\DSC-ScriptRunner' -ScriptRunnerModulePath 'D:\Git\DSC-ScriptRunner\DSC-ScriptRunner\ScriptRunnerScripts\Module' -ScriptRunnerServerPath 'C:\MOCK' -PullServerRegistrationKey 'MOCK' -ModulePath 'C:\MOCK'


$DatumConfiguration = Read-DatumConfiguration -DatumConfigurationFile $Global:SRDSC.DatumModule.ConfigurationFile -DatumConfigurationPath $Global:SRDSC.DatumModule.ConfigurationPath
$NodeTemplateConfiguration = Get-NodeTemplateConfigParams -TemplateFilePath $Global:SRDSC.ScriptRunner.NodeTemplateFile

$formattedDatumParams = @{
    DatumConfiguration = $DatumConfiguration
    NodeTemplateConfiguration = $NodeTemplateConfiguration
}

$formattedDatumConfig = Format-DatumConfiguration @formattedDatumParams

$DatumConfiguration

D:\Git\DSC-ScriptRunner\DSC-ScriptRunner\ScriptRunnerScripts\Template\NodeTemplateConfiguration.yml