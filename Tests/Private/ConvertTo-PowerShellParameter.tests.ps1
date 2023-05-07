Describe "Testing ConvertTo-PowerShellParameter" {

     it "Should returns an empty string when no input is provided" {

        $configurationTemplates = @()
        $result = ConvertTo-PowerShellParameter -ConfigurationTemplates $configurationTemplates
        $result | Should -Be ""
        
     } 

     it "Should generate the expected Parameters for a given input." {

        $configurationTemplates = @{
            DatumConfiguration = @(
                @{
                    ParameterName = "NodeName"
                    ParameterValues = @("node1", "node2")
                    IsOverwritten = $false
                }
            )
            TemplateConfiguration = @(
                @{
                    ParameterName = "VMName"
                    YAMLPath = "name"
                    ParameterExpression = ""
                },
                @{
                    ParameterName = "VMSize"
                    YAMLPath = "size"
                    ParameterExpression = "[ValidateNotNullOrEmpty()]"
                }
            )
        }
        $formattedDatumConfig = New-Object PSObject -Property $configurationTemplates
        $expectedResult = Import-MockData -CommandName 'ConvertTo-PowerShellParameter.test.2'
        
        $result = ConvertTo-PowerShellParameter -ConfigurationTemplates $formattedDatumConfig        
        $result | Should -Be $expectedResult

     }

    it "Test case checks if the function correctly handles duplicate parameters in the input." {

        $configurationTemplates = @{
            DatumConfiguration = @(
                @{
                    ParameterName = "NodeName"
                    ParameterValues = @("node1", "node2")
                    IsOverwritten = $false
                }
            )
            TemplateConfiguration = @(
                @{
                    ParameterName = "VMName"
                    YAMLPath = "name"
                    ParameterExpression = ""
                },
                @{
                    ParameterName = "NodeName"
                    YAMLPath = "name"
                    ParameterExpression = ""
                }
            )
        }
        $formattedDatumConfig = New-Object PSObject -Property $configurationTemplates
        $expectedResult = Import-MockData -CommandName 'ConvertTo-PowerShellParameter.test.3'

        $result = ConvertTo-PowerShellParameter -ConfigurationTemplates $formattedDatumConfig
        $result | Should -be $expectedResult

    }
     
    it "This test case checks if the function correctly includes custom validation expressions for parameters that have them" {

        $configurationTemplates = @{
            DatumConfiguration = @(
                @{
                    ParameterName = "NodeName"
                    ParameterValues = @("node1", "node2")
                    IsOverwritten = $false
                }
            )
            TemplateConfiguration = @(
                @{
                    ParameterName = "VMName"
                    YAMLPath = "name"
                    ParameterExpression = ""
                },
                @{
                    ParameterName = "VMSize"
                    YAMLPath = "size"
                    ParameterExpression = "[ValidatePattern('Standard_[A-Z]+')]"
                }
            )
        }
        $formattedDatumConfig = New-Object PSObject -Property $configurationTemplates
        $expectedResult = Import-MockData -CommandName 'ConvertTo-PowerShellParameter.test.4'

        $result = ConvertTo-PowerShellParameter -ConfigurationTemplates $formattedDatumConfig
        $result | Should -Be $expectedResult

    }

}