Describe "Testing Get-NodeTemplateConfigParams" {

    it "Should return a list of properties" {

        #
        # Arrange
        
        Mock -CommandName 'Get-Content' -MockWith { return 'MOCK' }
        Mock -CommandName 'ConvertFrom-Yaml' -MockWith { return 'MOCK' }
        Mock -CommandName 'Format-YAMLObject' -MockWith { return 'MOCK' }
        Mock -CommandName 'ConvertYAMLPathTo-Parameter' -MockWith {
            return @{ ParameterLabel = 'MOCK' }
        }

        Mock -CommandName 'Find-YamlValue' -MockWith {
            return @(
                @{
                    Value = '%%Value%%'
                    Path = '$MOCK."Property1"'
                }
                @{
                    Value = '%%Value%%'
                    Path = '$MOCK."Property2"'
                }                
            )
        }


        #
        # Act
        $result = Get-NodeTemplateConfigParams -TemplateFilePath 'MOCK'

        #
        # Assert

        $result.Count | Should -be 2 
        $result.ParameterName | Should -be @('MOCK','MOCK')
        $result.YAMLValue | Should -be @('%%Value%%','%%Value%%')
        $result.YAMLPath | Should -be @('$MOCK."Property1"','$MOCK."Property2"')

    }

}