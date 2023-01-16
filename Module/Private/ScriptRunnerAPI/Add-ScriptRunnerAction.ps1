function Add-ScriptRunnerAction {
    [CmdletBinding(DefaultParameterSetName='Default')]
    param (
        [Parameter(Mandatory, ParameterSetName='Default')]
        [Parameter(Mandatory, ParameterSetName='Scheduling')]
        [String]
        $ScriptName,
        [Parameter(Mandatory, ParameterSetName='Default')]
        [Parameter(Mandatory, ParameterSetName='Scheduling')]
        [String]
        $ScriptRunnerServer,
        [Parameter(Mandatory, ParameterSetName='Default')]
        [Parameter(Mandatory, ParameterSetName='Scheduling')]
        [Object]
        $ScriptRunnerTarget,        
        [Parameter(Mandatory, ParameterSetName='Scheduling')]
        [Switch]
        $useScheduling,
        [Parameter(Mandatory, ParameterSetName='Scheduling')]
        [Int]
        $RepeatMins,
        [Switch]
        $FailNonTerminatingErrors
    )
    
    $ErrorActionPreference = 'Stop'

    Write-Host "[Add-ScriptRunnerAction] Started:"

    #
    # Locate the Script Name

    $params = @{
        ScriptRunnerServer = $ScriptRunnerServer
    }

    # Locate the Script Object
    [Array]$script = List-ScriptRunnerScript @params | Where-Object {
        $_.DisplayName -eq $ScriptName
    }

    if ($script.count -ne 1) { 
        Throw "[Add-ScriptRunnerAction] There was a problem attempting to locate $ScriptName on the ScriptRunner server"
        return
    }

    #
    # Create the Action with Properties

    $actionParams = @{
        Uri = "{0}:8091/ScriptRunner/ActionContextItem/Default.CreateAction" -f $ScriptRunnerServer
        Method = 'POST'
        Body = @{
            Title = $script.DisplayName.Replace('.ps1','')
            OwnerID = 0
            Comment = ""
            ScriptID = $script.ID
            IDLIST_Tags = $script.IDLIST_Tags
        } | ConvertTo-Json
        UseDefaultCredentials = $true
        ContentType = "application/json"
    }

    Write-Host "[Add-ScriptRunnerAction] Creating Script Runner Action: $($actionParams.URI)"

    $actionObject = Invoke-RestMethod @actionParams

    #
    # Set Execution Location to the Script Runner Server

    $actionContextParams = @{
        Uri = "{0}:8091/ScriptRunner/ActionContext({1})" -f $ScriptRunnerServer, $actionObject.value.id
        Method = 'PATCH'
        Body = @{
            IsScheduled = $false
            RT_IDLIST_Targets = [String]$ScriptRunnerTarget.value.ID
            RT_LIST_TargetNames = $ScriptRunnerTarget.value.DisplayName
            ScheduleEnd = "1999-01-01T00:00:00.000Z"
            Insensitive = -not($FailNonTerminatingErrors.IsPresent)
        }
        UseDefaultCredentials = $true
        ContentType = "application/json"
    }

    #
    # If scheduling was enabled, append the HTTP body.

    if ($useScheduling.IsPresent) {
        $actionContextParams.Body.IsScheduled = $true
        $actionContextParams.Body.Schedule = "M;{0}" -f $RepeatMins
    }

    # Convert the body to JSON and invoke the REST method.
    $actionContextParams.Body = $actionContextParams.Body | ConvertTo-Json
    $null = Invoke-RestMethod @actionContextParams

    #
    # Return to the caller.
    
    return (@{
        success = $true
    })

}