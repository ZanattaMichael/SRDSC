#
# Uses PowerShell remoting to onboard the server into the DSC pull server

# Returns the GUID back to the 

function Invoke-Onboarding {
    param(
        # Parameter help description
        [Parameter(Mandatory)]
        [String]
        $NodeName
    )

    $RegistrationKey = [guid]::NewGuid().Guid

    # Load the DSC Server Configuration Data

    Invoke-Command -ArgumentList $DSCPullServer,$RegistrationKey -ComputerName $NodeName -ScriptBlock {
        param($DSCPullServer,$RegistrationKey)

        # Test if DSC has been configured on the endpoint.
        if ($null -ne (Get-DscConfigurationStatus -ErrorAction SilentlyContinue)) {
            # If the DSC pull services arn't the pull-server, override
            # Otherwise return the DSC Configuration with registration key            
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
        PullClientConfigNames

    }

}