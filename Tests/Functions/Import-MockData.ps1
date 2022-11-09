Function Import-MockData {
    [CmdletBinding()]
    param (
        # Mock Data
        [Parameter(Mandatory)]
        [String]
        $CommandName
    )

    $params = @{
        LiteralPath = "{0}\Tests\Mocks\{1}.clixml" -f $Global:TestRootPath, $CommandName
    }
    Import-Clixml @params

}