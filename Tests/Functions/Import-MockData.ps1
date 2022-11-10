Function Import-MockData {
    [CmdletBinding()]
    param (
        # Mock Data
        [Parameter(Mandatory)]
        [String]
        $CommandName
    )

    if ([String]::IsNullOrEmpty($Global:TestRootPath)) {
        Wait-Debugger
    }

    $params = @{
        LiteralPath = "{0}\Mocks\{1}.clixml" -f $Global:TestRootPath, $CommandName
    }
    Import-Clixml @params

}