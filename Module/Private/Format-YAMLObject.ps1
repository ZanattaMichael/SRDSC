

#
# Iterates through the YAML file and create linking properties to the parent.
# This is used to create a PowerShell Object property structure when serching for a PowerShell Key/Value

Function Format-YAMLObject {
    [CmdletBinding()]
    param (
        [Object]$YAMLObject,        
        [String]$YAMLLookupPath = "",
        [String]$ObjectName
    )

    #
    # Format the Parent Path

    $ParentPath = $(

        #
        # Top-Level Object
        if ([String]::IsNullOrEmpty($YAMLLookupPath)) {
            # Object name must exist if $YAMLLookupPath is null
            if ([String]::IsNullOrEmpty($ObjectName)) { Throw "Error... ObjectName, must be defined!" }
            '${0}' -f $ObjectName
        } else {
            '{0}' -f $YAMLLookupPath
        }

    )

    # Create an HashTable, with property information that contains
    # object matching infomation that can be used
    # to construct a lookup string.

    switch ($YAMLObject) {

        #
        # If the YAMLObject is a hashtable, iterate through each of the properties and
        # prase the object in.

        {$YAMLObject.GetType().Name -eq 'Hashtable'} {

            $newYAMLObject = @{}            
            ForEach($Key in $YAMLObject.Keys) {

                $params = @{
                    YAMLObject = $YAMLObject[$Key]
                    YAMLLookupPath = '{0}."{1}"' -f $ParentPath, $Key
                }

                $newYAMLObject."$Key" = Format-YAMLObject @params

            }

            break;

        }

        #
        # If the YAML Object type is an array.
        # Iterate through each of the items in the array

        {$YAMLObject.GetType().Name -eq 'List`1'} {

            $newYAMLObject = @()
            #$newYAMLObject = [System.Collections.Generic.List[Object]]::new()

            #
            # Iterate through each of the index items and call them
            For($index = 0; $index -ne $YAMLObject.Count; $index++) {

                $params = @{
                    YAMLObject = $YAMLObject[$index]
                    YAMLLookupPath = '{0}[{1}]' -f $ParentPath, $index
                }

                $newYAMLObject += Format-YAMLObject @params

            }

        }

        #
        # These are property types. (String, Int, DateTime)
        
        default {

            $newYAMLObject = $YAMLObject
            $newYAMLObject = $newYAMLObject | Add-Member -MemberType NoteProperty -Name '_YAMLPath' -Value $ParentPath -Force -PassThru

        }

    }    

    return $newYAMLObject   

}