function Add-SRDSCNode {
    <#
    .Description
    Onboards an Datum Node Endpoint into the DSC Pull Server.
    The calling process uses PowerShell remoting to configure the endpoint (ensure that PowerShell Remoting is enabled on the endpoint).
    The command supports ConfigurationID and Registration Key (Preferred).
    If using a ConfigurationID upon registration, will capture and store the Configuration ID locally on the Pull Server, so the build script can associate the NODE to it's Configuration ID.
    The Registration Key is the preferred way. It onboard the endpoint node and set's the Configuation Name to the  .
    
    If a Pull Server has already been configured on the LCM endpoint, the process won't perform the onboarding process, however it will still return the ConfigurationID.
    
    .PARAMETER NodeName
    The ComputerName Endpoint.
    
    .PARAMETER DSCPullServer
    The PullServer URL Location
    
    .PARAMETER UseConfigurationIDs
    A switch to register the endpoint using ConfigurationIDs, instead of a Pull Server Registration Key.
    
    .PARAMETER Force
    Overwrite any existing LCM configuration and onboard the Node onto the new DSC Pull Server.
    
    .EXAMPLE
    
    Add-SRDSCNode -NodeName 'NODE01' -DSCPullServer 'HTTP://DSCPULLSERVER01' -Force
    
    Forcibly Adds 'NODE01' to the DSCPullServer 'HTTP://DSCPULLSERVER01'
    
    .EXAMPLE
    
    Add-SRDSCNode -NodeName 'NODE01' -DSCPullServer 'HTTP://DSCPULLSERVER01'
    
    Adds 'NODE01' to the DSCPullServer 'HTTP://DSCPULLSERVER01'. If an LCM configuration already exists, stop.
    
    .SYNOPSIS
    Onboards an Endpoint Node into the DSC Pull Server.
    #>
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

        $invokeCommandParams = @{
            ArgumentList = $DSCPullServer,$Force,$RegistrationKey,$UseConfigurationIDs
            ComputerName = $NodeName
            ErrorAction = 'Stop'
        }

        $NodeDSCLCMConfiguration = Invoke-Command @invokeCommandParams -ScriptBlock {
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
            Set-Alias -Name x -Value Get-DscSplattedResource
    
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
                ConfigurationMode = 'ApplyAndAutoCorrect'        
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
                    x -ResourceName 'Settings' -Properties $DSCResourceSettings
                    x -ResourceName 'ConfigurationRepositoryWeb' -ExecutionName 'PullSrv' -Properties $DSCResourceConfigurationRepositoryWeb
    
                    ReportServerWeb PullSrv
                    {
                        ServerURL = 'https://{0}:8080/PSDSCPullServer.svc' -f $DSCPullServer
                    }
    
                }
            }
    
            # Generate the Configuration MOF File
            PullClientConfigNames -OutputPath C:\Windows\Temp\DSC\ -ErrorAction Stop
            # Set the LocalConfiguration
            Set-DscLocalConfigurationManager -Path C:\Windows\Temp\DSC\ -Verbose -ErrorAction Stop
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