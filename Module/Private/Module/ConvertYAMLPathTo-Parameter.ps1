function ConvertYAMLPathTo-Parameter {
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