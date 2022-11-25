function Find-YamlValue {
<#
.Description
This function is used to find all the YAML object paths that contain a specific string.
In this case the script uses this function to searches the Node Template Configuration
for '%%' (Denoting static entries).

This function uses the _YAMLPath property on a Formatted YAML Object (Format-YAMLObject)
to return the object path. It performs the search by recursivly through the entire
YAML Object looking at the values, when a value is matched (using regex), it's value and 
it's property path (_YAMLPath) is returned to the caller.

.PARAMETER YAMLObject
The Input Yaml Object. This object MUST be formatted with Format-YamlObject
.PARAMETER ValueToFind
Regex search string
.EXAMPLE
Find-YamlValue -YAMLObject $FormattedYAMLTemplate -ValueToFind '%%' 
.SYNOPSIS
Performs a search in a deseralized formatted YAML Object for a value and returns the _YAMLPATH
to the caller.
#>

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