function New-ScriptRunnerTarget {
    param(
        [Parameter(Mandatory)]
        [String]
        $ScriptRunnerServerURL,
        [Parameter(Mandatory)]
        [Object]
        $ScriptRunnerCredential
    )

    Write-Host "[New-ScriptRunnerTarget] Adding Script Runner Target:"

    #
    # Create the Target

    $params = @{
        Uri = "{0}:8091/ScriptRunner/TargetItem/Default.CreateTarget" -f $ScriptRunnerServerURL
        Method = 'POST'
        Body = @{
            Comment = ""
            ComputerName = ""
            DisplayName = "DSC Pull Services"
            OwnerID = 0
            TagNames = @(
                'DSC'
            )
        } | ConvertTo-Json
        UseDefaultCredentials = $true
        ContentType = "application/json"
    }

    # Create the Target
    $SRTarget = Invoke-RestMethod @params

    #
    # Set the Credential

    $credParams = @{
        Uri = "{0}:8091/ScriptRunner/Target({1})" -f $ScriptRunnerServerURL, $SRTarget.value.id
        Method = 'PATCH'
        Body = @{
            MyDefaultUserCredential_ID = $ScriptRunnerCredential.value.id
            TargetKind = "LOCAL"
        } | ConvertTo-Json
        UseDefaultCredentials = $true
        ContentType = "application/json"
    }

    Write-Host "[New-ScriptRunnerTarget] Setting Credential on Endpoint:"

    # Set the Password
    Invoke-RestMethod @credParams

    # Return the SRCredentialObject.
    return $SRTarget
    
}