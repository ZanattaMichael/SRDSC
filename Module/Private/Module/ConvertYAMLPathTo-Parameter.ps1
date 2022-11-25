function ConvertYAMLPathTo-Parameter {
<#
.Description
Paramters that are defined within the Node Template Configuration is dynamic.
This function dynamically generates parameters based on the _YAMLPath property 
('$MOCK."Array"[5]."Array"[1]."Property"') value, so it can be used within 
the New-VirtualMachine.ps1 script.

The function performs this task by performing the following logic:

1. Splitting out the _YAMLPath property value by periods ('.')
   '$MOCK."Array"[5]."Array"[1]."Property"' would be broken-down into:

        a) '$MOCK'
        b) "Array"[5]
        c) "Array"[1]
        d) "Property"

1. Iterate through each of these elements and:
    a. Try and identify if the element contains an array (i.e [1], [2]).
       If an array is found, then the array is appended to the 
    b. Otherwise the last property is added.

Note: Only the array items are appended to the paramter, subsequent properties are skipped.
For example:

'$MOCK."Object1"."Array"[1]."Object2"."Property"' will be: 'Array1Property'
That's because the logic will take the array item and then skip subsequent properties.

.PARAMETER Str
The value of _YAMLPath
.EXAMPLE
'$MOCK."Array"[5]."Array"[1]."Property"' | ConvertYAMLPathTo-Parameter
.SYNOPSIS
Converts _YAMLPath property values into a Dynamic Paramter.
#>    
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [String]
        $Str
    )

    $output = [PSCustomObject]@{
        String = $str
        ParameterLabel = ""
    }

    $Tester = [Regex]::New('"(?<name>\w+)"\[(?<index>\d+)\]')
    $splitString = ($str).Split(".")

    #
    # Attempt to locate any array index values and append them to the parameter name
    For ($index = 0; $index -ne $splitString.Count; $index++) {

        #
        # Perform the match for each line
        $result = $Tester.Match($splitString[$index])

        #
        # If no match was found, skip and move on.
        # However, if it's the last item in the array, add the last property.
        if (-not($result.Success)) { 

            # Add the last property to the list
            if ($index -eq ($splitString.Count - 1)) {
                $splitString[$index] -match '"(?<name>\w+)"'
                $output.ParameterLabel += $Matches["name"]
            }

            # Move on
            continue 
        }

        # Format the parameter label.
        $output.ParameterLabel += "{0}{1}" -f 
            $(
                (Get-Culture).TextInfo.ToTitleCase($result.groups["name"].value)
            ),
            $(
                if ([int]$result.groups["index"].value -eq 0) { $null }
                else { $result.groups["index"].value }
            )

    }

    # If there was no input. Throw an error.
    if ([String]::IsNullOrEmpty($output.ParameterLabel)) {
        Throw "[ConvertYAMLPathTo-Parameter] Error: No Parameter Label was generated for string ($($str))"
    }

    Write-Output $output

}