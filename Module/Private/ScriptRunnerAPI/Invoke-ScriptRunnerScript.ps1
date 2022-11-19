function Invoke-ScriptRunnerScript {
    [CmdletBinding(DefaultParameterSetName='Default')]
    param (
        [Parameter(Mandatory, ParameterSetName='Default')]
        [Parameter(Mandatory, ParameterSetName='Scheduling')]
        [String]
        $ScriptName,
        [Parameter(Mandatory, ParameterSetName='Default')]
        [Parameter(Mandatory, ParameterSetName='Scheduling')]
        [String]
        $ScriptRunnerServer      
    )
    
    $ErrorActionPreference = 'Stop'

    Write-Host "[Invoke-ScriptRunnerScript] Started:"

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
    # Create with Properties

    $actionParams = @{
        Uri = "{0}:8091/ScriptRunner/ActionContextItem{1}/Default.StartAction" -f $ScriptRunnerServer, $script.id
        Method = 'POST'
        Body = @{
            IDLIST_Targets = "-2"
            CredId = 0
            PreferMyUserCredential = $false
            TimeoutSecs = 0
            PSAuth = "Default"
            Verbose = $false
            ReportWidthLarge = $false
            ReportSizeLarge = $false
            Options = @("","")
            RunFlags = @()
            ScriptParameters = @()
            Values = @()
        } | ConvertTo-Json
        UseDefaultCredentials = $true
        ContentType = "application/json"
    }

    Write-Host "[Add-ScriptRunnerAction] Creating Script Runner Action: $($actionParams.URI)"

    $result = Invoke-RestMethod @actionParams

    #
    # Return to the caller.
    
    return (@{
        success = $true
    })

}