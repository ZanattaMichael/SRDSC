<#
function Find-YamlValue {
    [CmdletBinding()]
    param (
        [Object]$YAMLObject,
        [String]$ValueToFind,
        [String]$Parent
    )

    process {
        
        #
        # Iterate through each of the keys within the YAML file
        $type = 

        if ($YAMLObject -is [])

    }
    
}
#>


#
# Iterates through the YAML file and create linking properties to the parent.
# This is used to create a PowerShell Object property structure when serching for a PowerShell Key/Value

Function Format-YAMLObject {
    [CmdletBinding()]
    param (
        [Object]$YAMLObject,        
        [String]$ParentPropertyName,
        [String]$ParentTypeName,
        [Int]$ParentIndexValue = -1
    )

    # Create an HashTable, with property information that contains
    # object matching infomation that can be used
    # to construct a lookup string.

    switch ($YAMLObject) {

        #
        # If the YAMLObject is a hashtable, iterate through each of the properties and
        # prase the object in.

        {$YAMLObject.GetType().Name -eq 'Hashtable'} {

            #
            # Iterate through each of the key's and recursivly call the function
            $newYAMLObject = @{}
            $newYAMLObject = $newYAMLObject | Add-Member -MemberType NoteProperty -Name '_YAMLParentInfo' -Value @() -Force
            $newYAMLObject._YAMLParentInfo += $([PSCustomObject]@{
                ParentPropertyName = $ParentPropertyName
                ParentTypeName = $ParentTypeName
                ParentIndexValue = $ParentIndexValue
            })

            ForEach($Key in $YAMLObject.Keys) {

                $params = @{
                    YAMLObject = $YAMLObject[$Key]
                    ParentPropertyName = $Key
                    ParentTypeName = $YAMLObject.GetType().Name
                    ParentIndexValue = -1
                }

                Write-Host $Key
                $newYAMLObject."$Key" = Format-YAMLObject @params
                #$YAMLObject[$Key] = Format-YAMLObject @params

            }

            break;

        }

        #
        # If the YAML Object type is an array.
        # Iterate through each of the items in the array

        {$YAMLObject.GetType().Name -eq 'List`1'} {

            $newYAMLObject = @()
            #$newYAMLObject = [System.Collections.ArrayList]::new()

            #
            # Iterate through each of the index items and call them
            For($index = 0; $index -ne $YAMLObject.Count; $index++) {

                $params = @{
                    YAMLObject = $YAMLObject[$index]
                    ParentPropertyName = $ParentPropertyName
                    ParentTypeName = $YAMLObject.GetType().Name
                    ParentIndexValue = $index
                }

                #$newYAMLObject.Add((Format-YAMLObject @params))
                
                $YAMLObject[$index] = Format-YAMLObject @params 
                
                $YAMLObject[$index]._YAMLParentInfo += [PSCustomObject]@{
                    ParentPropertyName = $ParentPropertyName
                    ParentTypeName = $ParentTypeName
                    ParentIndexValue = $ParentIndexValue
                }

            }

        }

        default {

            $newYAMLObject = $YAMLObject
            $newYAMLObject = $newYAMLObject | Add-Member -MemberType NoteProperty -Name '_YAMLParentInfo' -Value $([PSCustomObject]@{
                ParentPropertyName = $ParentPropertyName
                ParentTypeName = $ParentTypeName
                ParentIndexValue = $ParentIndexValue
            }) -PassThru -Force 

        }

    }    

    return $newYAMLObject   

}