Function New-ScriptRunnerCredential {
    param(
        [Parameter(Mandatory)]
        [String]
        $ScriptRunnerServerURL,
        [Parameter(Mandatory)]
        [pscredential]
        $Credential
    )

    Write-Host "[New-ScriptRunnerCredential] Adding DSC Service Credentials:"

    #
    # Create the Credential
    $params = @{
        Uri = "{0}:8091/ScriptRunner/UserCredentials/Default.CreateUserCredentials" -f $ScriptRunnerServerURL
        Method = 'POST'
        Body = @{
            CredManKey = ""
            DisplayName = "DSC Pull Services"
            Domain = ""
            OwnerID = 0
            RT_Password = ""
            RT_Tags = "DSC"
            Username = $Credential.UserName
        } | ConvertTo-Json
        UseDefaultCredentials = $true
        ContentType = "application/json"
    }

    Write-Host "[New-ScriptRunnerCredential] UserName: $($Credential.UserName)"

    # Create the Credential
    $SRCredential = Invoke-RestMethod @params

    #
    # Set the Password

    $passwordParams = @{
        Uri = "{0}:8091/ScriptRunner/UserCredentials({1})" -f $ScriptRunnerServerURL, $SRCredential.value.id
        Method = 'PATCH'
        Body = @{
            RT_Password = $Credential.Password | ConvertTo-PlainText
            StoreMode = "CredMan"
        } | ConvertTo-Json
        UseDefaultCredentials = $true
        ContentType = "application/json"
    }

    Write-Host "[New-ScriptRunnerCredential] Setting Password:"

    # Set the Password
    Invoke-RestMethod @passwordParams

    # Return the SRCredentialObject.
    return $SRCredential

}

