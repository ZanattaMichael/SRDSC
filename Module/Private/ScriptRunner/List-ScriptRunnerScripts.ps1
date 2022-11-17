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
    
    Write-Host '[List-ScriptRunnerScript] Retriving Scripts from the Script Runner Server:'
    Write-Host "[List-ScriptRunnerScript] URL: $($getScriptListParams.URL)"

    return (Invoke-RestMethod @getScriptListParams).value

}