Function Import-MockData {
    [CmdletBinding()]
    param (
        # Mock Data
        [Parameter(Mandatory)]
        [String]
        $CommandName
    )

    $params = @{
        LiteralPath = "{0}\Tests\Mocks\{1}.clixml" -f $GLOBAL:SRDSCTESTPATH, $CommandName
    }
    Import-Clixml @params

}