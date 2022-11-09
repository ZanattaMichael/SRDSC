Function Get-SRAction {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String]
        $XMLPath,
        # Parameter help description
        [Parameter(Mandatory)]
        [String]
        $ScriptName
    )

    $actionXPATH = '//entity[@ClassKey=''actioncontext'' and ./property[@name=''MyScriptProxy''] and ./property[contains(.,{0})]]'
    $scriptProxyXPATH = '//entity[@ClassKey=''scriptproxy'' and ./property[@name=''ExtRef''] and ./property[contains(.,''{0}'')]]' -f $ScriptName
    $paramProxyXPATH = '//entity[@ClassKey=''paramproxy'' and ./property[@name=''ExtRef''] and ./property[contains(.,''{0}'')]]' -f $ScriptName
    $scriptParamXPATH = '//entity[@ClassKey=''paramvalue'' and ./property[@name=''MyParamProxy''] and ./property[contains(.,{0})]]'

    [XML]$XML = Get-Content -LiteralPath $XMLPath

    $scriptProxy = $XML.SelectSingleNode($scriptProxyXPATH);

    $object = @{
        Action = $scriptProxy.SelectSingleNode($actionXPATH -f $scriptProxy.Id)
        ScriptProxy = $scriptProxy
        ParamProxy = @()
    }

    $XML.SelectNodes($paramProxyXPATH) | ForEach-Object
        $object.ParamProxy += @{
            Proxy = $_
            ParamValue = $XML.SelectNodes($scriptParamXPATH -f $_.id)
        }
    }

    $object

}
