#region ConvertTo-PlainText
function ConvertTo-PlainText {
<#
.Description
Converts [SecureString] into Plain Text ([String])
.PARAMETER SecureString
The Secure String to Decrypt
.EXAMPLE
$SecureString | ConvertTo-PlainText
.SYNOPSIS
Converts [SecureString] into Plain Text ([String])
#>

    param (
        [parameter(Mandatory, ValueFromPipeline)]
        [SecureString]
        $SecureString
    )

    $plainText = ""

    try {

        #Convert the secure string into a Binary String        
        $binaryString = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
        #Convert the Binary String to Plain Text
        $plainText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($binaryString)
        
    } catch {

        Write-Error $_

    }
   
    $plainText
}
#endregion ConvertTo-PlainText