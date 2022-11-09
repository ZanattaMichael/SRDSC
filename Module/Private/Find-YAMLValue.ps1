function Find-YamlValue {
    [CmdletBinding()]
    param (
        [Object]$YAMLObject,
        [String]$ValueToFind
    )

    Start-YamlSearch @PSBoundParameters | Sort-Object -Unique -Property Path

}

Function Start-YamlSearch {

    [CmdletBinding()]
    param (
        [Object]$YAMLObject,
        [String]$ValueToFind
    )

    switch ($YAMLObject) {

        #
        # If the YAMLObject is a hashtable, iterate through each of the properties and
        # prase the object in.

        {$YAMLObject.GetType().Name -eq 'Hashtable'} {
    
            ForEach($Key in $YAMLObject.Keys) {

                $params = @{
                    YAMLObject = $YAMLObject[$Key]
                    ValueToFind = $ValueToFind
                }

                Start-YamlSearch @params

            }

            break;

        }

        #
        # If the YAML Object type is an array.
        # Iterate through each of the items in the array

        {$YAMLObject.GetType().BaseType.Name -eq 'Array'} {

            $newYAMLObject = @()
            #
            # Iterate through each of the index items and call them
            For($index = 0; $index -ne $YAMLObject.Count; $index++) {

                $params = @{
                    YAMLObject = $YAMLObject[$index]
                    ValueToFind = $ValueToFind
                }

                Start-YamlSearch @params 
    
            }

        }

        #
        # These are property types. (String, Int, DateTime)
        
        default {

            if ($YAMLObject.ToString() -match $ValueToFind) {
                [PSCustomObject]@{
                    Value = $YAMLObject
                    Path = $YAMLObject._YAMLPath
                }
            }

        }

    }

}