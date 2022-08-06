function Get-ASTScriptParameters {
    param(
        # Parameter help description
        [Parameter(Mandatory)]
        [String]
        $ScriptPath
    )

    [PSCustomObject]@{
        Parameters = (Get-Command $ScriptPath).ScriptBlock.Ast.ParamBlock.Parameters.Name.Extent.Text
        YAML = 
    }
    

}