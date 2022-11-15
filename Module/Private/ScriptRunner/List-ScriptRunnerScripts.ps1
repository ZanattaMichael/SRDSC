function List-ScriptRunnerScript {
    [CmdletBinding()]
    param (
        # Script Runner Server URL
        [Parameter(Mandatory)]
        [String]
        $ScriptRunnerServerURL
    )
    
    $getScriptListParams = @{
        Uri = "{0}:8091/ScriptRunner/ScriptRef" -f $ScriptRunnerServerURL
        Method = 'Get'
        UseDefaultCredentials = $true
    }
    
    return (Invoke-RestMethod @getScriptListParams).value

}