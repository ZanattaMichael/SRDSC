Function New-DSCPullServer {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String]
        $DSCPullServer = 'localhost',
        [Parameter()]
        [String]
        $FilePath = $env:PROGRAMFILES

    )



    }

    #
    # Generate GUID
    $GUID = [guid]::newGuid().Guid

    # Kick off the DSC Configuration
    xDscWebServiceRegistration -NodeName $DSCPullServer -RegistrationKey $GUID -WebServerFilePath $FilePath

}


