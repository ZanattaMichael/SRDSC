#region ConvertTo-PlainText
function ConvertTo-PlainText {
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