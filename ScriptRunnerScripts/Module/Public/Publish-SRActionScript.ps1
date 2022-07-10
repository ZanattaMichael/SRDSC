
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
        DatumConfigurationFile = $Global:SRDatum.DatumConfigurationFile
        DatumConfigurationPath = $Global:SRDatum.DatumConfigurationPath
    }

    #
    # Format the Datum Configuration and include the content from the template configuration file.
    $formattedDatumParams = @{
        DatumConfiguration = Read-DatumConfiguration @params
        NodeTemplateConfiguration = Get-NodeTemplateConfigParams -TemplateFilePath $Global:SRDatum.NodeTemplateFile
    }

    $formattedDatumConfig = Format-DatumConfiguration @formattedDatumParams

    # Invokes-Onboarding of the machine into DSC
    # Get's GUID
    # Write-s GUID to seperate configuration database storing names with registration ID's (clixml)
    # This is needed so when the mof files are generated, they can be renamed and copied to the SRDSC Pull Server

    # TODO: Also add SR module deploy script as well.



    #
    # Items that are specificed in the NodeTemplateConfiguration, with SR_PARAM_OVERRIDE have higher precidence
    # then datum configuration items.
    # A notable example of this is NodeName, which needs to be prompted for since it pertains to existing items.
        
    #TODO: Finish creating DSC script.
    

}