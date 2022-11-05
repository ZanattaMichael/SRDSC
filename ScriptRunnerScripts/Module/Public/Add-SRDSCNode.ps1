function Add-SRDSCNode {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String]
        $NodeName,
        [Parameter(Mandatory)]
        [String]
        $DSCPullServer,
        [Parameter()]
        [Switch]
        $UseConfigurationIDs,        
        [Switch]
        $Force
    )

    Write-Host "[Add-SRDSCNode] Onboarding $NodeName into $DSCPullServer"
    Write-Host "[Add-SRDSCNode] PowerShell Remoting to $NodeName to Register LCM to $DSCPullServer"

    $RegistrationKey = $Global:SRDSC.DSCPullServer.PullServerRegistrationKey

    # Load the DSC Server Configuration Data
    $NodeDSCLCMConfiguration = Invoke-Command -ArgumentList $DSCPullServer,$Force,$RegistrationKey,$UseConfigurationIDs -ComputerName $NodeName -ScriptBlock {
        param($DSCPullServer, $Force, $RegistrationKey, $UseConfigurationIDs)

        #
        # Functions
        #

        function Get-DscSplattedResource {
            [CmdletBinding()]
            Param(
                [String]
                $ResourceName,
        
                [String]
                $ExecutionName,
        
                [hashtable]
                $Properties
            )
            
            $stringBuilder = [System.Text.StringBuilder]::new()
            $null = $stringBuilder.AppendLine("Param([hashtable]`$Parameters)")
            $null = $stringBuilder.AppendLine(" $ResourceName $ExecutionName { ")
            foreach($PropertyName in $Properties.keys) {
                $null = $stringBuilder.AppendLine("$PropertyName = `$(`$Parameters['$PropertyName'])")
            }
            $null = $stringBuilder.AppendLine("}")
            Write-Debug ("Generated Resource Block = {0}" -f $stringBuilder.ToString())
            
            [scriptblock]::Create($stringBuilder.ToString()).Invoke($Properties)
        }
        Set-Alias –Name x –Value Get-DscSplattedResource

        #
        # Main Code Block
        #

        # Test if DSC has been configured on the endpoint.
        if ((-not($Force.IsPresent)) -and ($null -ne (Get-DscConfigurationStatus -ErrorAction SilentlyContinue))) {
            # Otherwise return the DSC Configuration with Configuration ID
            return Get-DscLocalConfigurationManager            
        }

        
        #
        # Compile the DSC Resource
        #

        #
        # Settings Resource       

        $DSCResourceSettings = @{
            RefreshMode = 'Pull'
            RefreshFrequencyMins = 30
            RebootNodeIfNeeded = $true          
        }

        #
        # ConfigurationRepositoryWeb Resource

        $DSCResourceConfigurationRepositoryWeb = @{
            ServerURL = 'https://{0}:8080/PSDSCPullServer.svc' -f $DSCPullServer            
        }

        #
        # Apply Logic. If Configuration ID's are set, use Configuration Id's
        # Otherwise use registration.

        # If ConfigurationID's have been specified. Add them in!
        if ($UseConfigurationIDs.IsPresent) {
            $DSCResourceSettings.ConfigurationID = [guid]::NewGuid().Guid  
        } else {
            $DSCResourceConfigurationRepositoryWeb.RegistrationKey = $RegistrationKey
            $DSCResourceConfigurationRepositoryWeb.ConfigurationNames = @($ENV:COMPUTERNAME)  
        }

        #
        # Define the Configuration
        #

        [DSCLocalConfigurationManager()]
        configuration PullClientConfigNames
        {

            Node localhost
            {
                    
                #
                # Onboard the machine into DSC and Return the LCM Configuration
                x 'Settings' -Properties $DSCResourceSettings
                x 'ConfigurationRepositoryWeb' 'PullSrv' $DSCResourceConfigurationRepositoryWeb

                ReportServerWeb PullSrv
                {
                    ServerURL = 'https://{0}:8080/PSDSCPullServer.svc' -f $DSCPullServer
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

    Write-Host "[Add-SRDSCNode] PowerShell Remoting Completed."
    Write-Host "[Add-SRDSCNode] LCM Configuration: $($NodeDSCLCMConfiguration | ConvertTo-Json)"


    if ($UseConfigurationIDs.IsPresent) {

        Write-Host "[Add-SRDSCNode] Writing ConfigurationID of Node as [SecureString]"

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
            ConfigurationID = [String]$NodeDSCLCMConfiguration.ConfigurationID | ConvertTo-SecureString -AsPlainText -Force
        }
    
        # Export it again
        $DatumLCMConfiguration | Export-Clixml -LiteralPath $Global:SRDSC.DatumModule.NodeRegistrationFile
    
    }

    Write-Host "[Add-SRDSCNode] Onboarded."

}

if ($isModule) { Export-ModuleMember -Function Add-SRDSCNode }