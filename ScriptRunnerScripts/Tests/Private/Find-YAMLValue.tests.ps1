Describe "Find-YamlValue" {

    it "Should return the correct values" {

        # Create a YAML Object
        $mockObject = @{
            SecondaryLevel = @{
                Array = @(
                    'First'
                    'Second'
                )
            }
            Property = 'Property'
        } | ConvertTo-Yaml | ConvertFrom-Yaml

        $params = @{
            YAMLObject = $mockObject
            ObjectName = 'MOCK'
        }

        $formattedObject = Format-YAMLObject @params 
      
        [Array]$result = Find-YamlValue -YamlObject $formattedObject -ValueToFind 'First'

        $result.Count | Should -be 1
        $result.Value | Should -be 'First'
        $result.Path | Should -be '$MOCK."SecondaryLevel"."Array"[0]'

    }

    it "Should return a list of all properties that are wrapped in a double '%%'" {


        # Create a YAML Object
        $mockObject = @{
            Property = 'Property'
            Property2 = '%%Value%%'
            Property3 = '%%Value%%'
        } | ConvertTo-Yaml | ConvertFrom-Yaml

        $params = @{
            YAMLObject = $mockObject
            ObjectName = 'MOCK'
        }

        $formattedObject = Format-YAMLObject @params 
      
        [Array]$result = Find-YamlValue -YamlObject $formattedObject -ValueToFind '%%'
        $result.Count | Should -be 2 

    }
    
}