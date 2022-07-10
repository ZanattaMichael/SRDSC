function Get-ASTScriptParameters {
    param(
        # Parameter help description
        [Parameter(Mandatory)]
        [String]
        $ScriptPath
    )

    (Get-Command $ScriptPath).ScriptBlock.Ast.ParamBlock.Parameters.Name.Extent.Text

}