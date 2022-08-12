function Get-ASTScriptParameters {
    param(
        # Parameter help description
        [Parameter(Mandatory)]
        [String]
        $ScriptPath
    )

    [PSCustomObject]@{
        Parameters = (Get-Command $ScriptPath).ScriptBlock.Ast.ParamBlock.Parameters.Name.Extent.Text
        YAMLData = Get-Content $ScriptPath | Where-Object {$_ -like '*#JSONData:*'} | ForEach-Object {
            if (-not($_ -match '\#(JSONData:?)(?<json>.+)')) { return }
            $Matches['json'] | ConvertFrom-Json
        }
    }
    

}

Export-ModuleMember -Function Get-ASTScriptParameters