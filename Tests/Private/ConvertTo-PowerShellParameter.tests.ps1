#This is a PowerShell script that tests the ConvertTo-PowerShellParameter function. 
#The script uses the Pester testing framework to define test cases for the function.
Describe "Testing ConvertTo-PowerShellParameter" {

    Context "when given a valid input" {

        it "should Generate the expected Parameters for a given input." {

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
    

        it "should handle duplicate parameters in the input." {
    
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
         
        it "should correctly include custom validation expressions for parameters that have them" {
    
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

    Context "when given invalid input" {
        It "throws an error when ConfigurationTemplates is null" {
            { ConvertTo-PowerShellParameter -ConfigurationTemplates $null } | Should -Throw
        }

        It "throws an error when DatumConfiguration is null" {
            $configurationTemplates.DatumConfiguration = $null
            { ConvertTo-PowerShellParameter -ConfigurationTemplates $configurationTemplates } | Should -Throw
        }

        It "throws an error when TemplateConfiguration is null" {
            $configurationTemplates.TemplateConfiguration = $null
            { ConvertTo-PowerShellParameter -ConfigurationTemplates $configurationTemplates } | Should -Throw
        }
    }

}
