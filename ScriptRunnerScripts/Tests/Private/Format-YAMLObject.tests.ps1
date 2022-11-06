Describe "Testing Format-YAMLObject" {

    BeforeAll {
        
        # Mock Input Data
        # Must be seralized and deseralized from YAML
        $YAMLPSHashTable = @{
            TopLevelProperty = 'Value'
            TopLevelObject = @{
                SecondaryArray = @(
                    'Value',
                    'Value2',
                    'Value3'
                )
                NestedObject = @{
                    Property1 = 'Property1'
                    Property2 = 'Property2'
                }
            }
        } | ConvertTo-Yaml | ConvertFrom-Yaml

    }

    it "Should not throw errors" {

        $params = @{
            YAMLObject = $YAMLPSHashTable
            ObjectName = 'MOCK'
        }

        { Format-YAMLObject @params } | Should -Not -Throw

    }

    it "Should contain the correct PowerShell Path" {

        $params = @{
            YAMLObject = $YAMLPSHashTable
            ObjectName = 'MOCK'
        }

        $result = Format-YAMLObject @params

        $result.TopLevelProperty.'_YAMLPath' | Should -Be '$MOCK."TopLevelProperty"'
        $result.TopLevelObject.SecondaryArray[0].'_YAMLPath' | Should -Be '$MOCK."TopLevelObject"."SecondaryArray"[0]'
        $result.TopLevelObject.SecondaryArray[1].'_YAMLPath' | Should -Be '$MOCK."TopLevelObject"."SecondaryArray"[1]'
        $result.TopLevelObject.SecondaryArray[2].'_YAMLPath' | Should -Be '$MOCK."TopLevelObject"."SecondaryArray"[2]'
        $result.TopLevelObject.NestedObject.Property1.'_YAMLPath' | Should -Be '$MOCK."TopLevelObject"."NestedObject"."Property1"'

    }

}