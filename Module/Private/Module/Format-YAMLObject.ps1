Function Format-YAMLObject {
<#
.Description
Format-YAMLObject indexes YAML Object's (Hashtables), by dynamically iterating through each
Keys and Arrays to generate a object cached stucture that's used to perform a direct lookup of the
object in the future. In each Key/Item it locates, it appends the object adding the _YAMLPath property
to the object. The _YAMLPath property, contains a PowerShell string representation of the .NET path
to resolve that property.

Why?

Format-YAMLObject was written to search and set object properties directly without needing to 
perform multiple recursive searches. It's used by New-VirtualMachine paramters to match the parameter
name to the exact .NET object property.

What does this look like?

Consider the following object structure:

$HashTable = @{
    Object = @{
        Array = @(
            @{
                Property = 'Value'
            }
        )
    }
}

To resolve this, in PowerShell would be:

$HashTable.Object.Array[0].Property

This function performs a similar process:

$property = $HashTable."Object"."Array"[0]."Property"
$value = 'Test123'

Note the double quotes wrapped around the properties. This is to ensure that object's or properties
that contains spaces are handled.

This string can then be parsed into a PowerShell ScriptBlock to Get/Set the value dynamically.
For Example, PowerShell will dynamically set 'Test123' to $HashTable:

[ScriptBlock]::Create(('{0} = "{1}"' -f $property, $value)).Invoke()

.PARAMETER YAMLObject
The Deseralized YAML object as [HashTable].

.PARAMETER YAMLLookupPath
Not used

.PARAMETER ObjectName
A string representation of the Object Name (include '$')

.EXAMPLE

    $FormattedYAMLTemplate | Format-YAML -Property $Global:SRDSC.DatumModule.YAMLSortOrder 

.SYNOPSIS
Iterates through the YAML file and create linking properties to the parent.
This is used to create a PowerShell Object property structure when searching for a PowerShell Key/Value
#>   
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