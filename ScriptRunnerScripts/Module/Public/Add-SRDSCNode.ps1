function Add-SRDSCNode {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String]
        $NodeName,
        [Parameter(Mandatory)]
        [String]
        $DSCPullServer        
    )

    #
    # Onboard the machine into DSC and Return the LCM Configuration
    $RegistrationKey = [guid]::NewGuid().Guid

    # Load the DSC Server Configuration Data
    $NodeDSCLCMConfiguration = Invoke-Command -ArgumentList $DSCPullServer,$RegistrationKey -ComputerName $NodeName -ScriptBlock {
        param($DSCPullServer,$RegistrationKey)

        # Test if DSC has been configured on the endpoint.
        if ($null -ne (Get-DscConfigurationStatus -ErrorAction SilentlyContinue)) {
            # Otherwise return the DSC Configuration with Configuration ID
            return Get-DscLocalConfigurationManager            
        }
        
        [DSCLocalConfigurationManager()]
        configuration PullClientConfigNames
        {

            Node localhost
            {
                Settings
                {
                    RefreshMode = 'Pull'
                    RefreshFrequencyMins = 30
                    RebootNodeIfNeeded = $true
                }
        
                ConfigurationRepositoryWeb CONTOSO-PullSrv
                {
                    ServerURL = 'https://{0}:8080/PSDSCPullServer.svc' -f $DSCPullServer
                    RegistrationKey = $RegistrationKey
                }
        
                ReportServerWeb CONTOSO-PullSrv
                {
                    ServerURL = 'https://CONTOSO-PullSrv:8080/PSDSCPullServer.svc'
                    RegistrationKey = $RegistrationKey
                }
            }
        }

        # Generate the Configuration MOF File
        PullClientConfigNames -OutputPath C:\Windows\Temp\DSC\
        # Set the LocalConfiguration
        Set-DscLocalConfigurationManager -Path C:\Windows\Temp\DSC\
        # Retrive the ConfigurationID ID
        Write-Output (Get-DscLocalConfigurationManager)
    }

    #
    # The LCM Configuration is needed to register the ConfigurationID.
    # This is used by the datum configuration to rename the mof files
    $DatumLCMConfiguration = @()

    if (Test-Path -LiteralPath $Global:SRDSC.DatumModule.NodeRegistrationFile) {
        $NodeRegistrationFile += Import-Clixml -LiteralPath $Global:SRDSC.DatumModule.NodeRegistrationFile
        # Filter out the existing node node. This enable rewrites
        $DatumLCMConfiguration = @()
        $DatumLCMConfiguration += $NodeRegistrationFile | Where-Object {$_.NodeName -ne $NodeName}
    }
    
    $DatumLCMConfiguration += [PSCustomObject]@{
        NodeName = $NodeName
        ConfigurationID = $RegistrationKey | ConvertTo-SecureString -AsPlainText -Force
    }

    # Export it again
    $DatumLCMConfiguration | Export-Clixml -LiteralPath $Global:SRDSC.DatumModule.NodeRegistrationFile

}

Export-ModuleMember -Function Add-SRDSCNode