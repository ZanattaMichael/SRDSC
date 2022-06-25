
Function Get-SRAction($ScriptName) {

    $SRActionParams = @{
        Uri = "http://scriptrunner01.contoso.local:8091/ScriptRunner/ActionContextItem"
        UseDefaultCredentials = $true
    }

    $SRActions = Invoke-RestMethod @SRActionParams
    $Action = ($SRActions.value | Where-Object {$_.RT_ScriptName -like "*$ScriptName"})

    $SRGetParamValueParams = @{
        Uri = "http://scriptrunner01.contoso.local:8091/ScriptRunner/ActionContextItem({0})/Default.GetAllActionValues" -f $Action.ID
        UseDefaultCredentials = $true
        Method = "POST"
    }

    $SRAction = @{
        Action = $Action
        Arguments = (Invoke-RestMethod @SRGetParamValueParams).Value
        QueryReferences = $null
    }

    Write-Output $SRAction

}
