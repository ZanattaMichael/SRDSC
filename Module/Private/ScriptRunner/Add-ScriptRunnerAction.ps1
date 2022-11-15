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
        [Parameter(Mandatory, ParameterSetName='Scheduling')]
        [Switch]
        $useScheduling,
        [Parameter(Mandatory, ParameterSetName='Scheduling')]
        [Int]
        $RepeatMins        
    )
    
    $ErrorActionPreference = 'Stop'

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

    $actionObject = Invoke-RestMethod @actionParams

    if ($useScheduling.IsPresent) {

        #
        # Set Execution Location to the Script Runner Server

        $actionSchedulingParams = @{
            Uri = "{0}:8091/ScriptRunner/ActionContext({1})" -f $ScriptRunnerServer, $actionObject.value.id
            Method = 'PATCH'
            Body = @{
                IsScheduled = $true
                RT_IDLIST_Targets = "-2"
                RT_LIST_TargetNames = "Direct Service Execution"
                Schedule = "M;{0}" -f $RepeatMins
                ScheduleEnd = "1999-01-01T00:00:00.000Z"
            } | ConvertTo-Json
            UseDefaultCredentials = $true
            ContentType = "application/json"
        }

        $null = Invoke-RestMethod @actionSchedulingParams

    }

    #
    # Return to the caller.
    
    return (@{
        success = $true
    })

}