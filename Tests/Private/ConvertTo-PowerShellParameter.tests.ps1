Describe "Testing ConvertTo-PowerShellParameter" -Skip {

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
        
$expectedResult = @"
[Parameter(Mandatory)]
[ValidateSet('node1','node2')]
[String]
$NodeName,

[Parameter(Mandatory)]
#JSONData: {"Name":"VMName","LookupValue":"name"}
[ValidateNotNullOrEmpty()]
[String]
$VMName,

[Parameter(Mandatory)]
#JSONData: {"Name":"VMSize","LookupValue":"size"}
[ValidateNotNullOrEmpty()]
[String]
$VMSize,
"@
        
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

$expectedResult = @"
[Parameter(Mandatory)]
[ValidateSet('node1','node2')]
[String]
$NodeName,

[Parameter(Mandatory)]
#JSONData: {"Name":"VMName","LookupValue":"name"}
[ValidateNotNullOrEmpty()]
[String]
$VMName,
"@

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

$expectedResult = @"
[Parameter(Mandatory)]
[ValidateSet('node1','node2')]
[String]
$NodeName,

[Parameter(Mandatory)]
#JSONData: {"Name":"VMName","LookupValue":"name"}
[ValidateNotNullOrEmpty()]
[String]
$VMName,

[Parameter(Mandatory)]
#JSONData: {"Name":"VMSize","LookupValue":"size"}
[ValidatePattern('Standard_[A-Z]+')]
[String]
$VMSize,
"@

        $result = ConvertTo-PowerShellParameter -ConfigurationTemplates $formattedDatumConfig
        $result | Should -Be $expectedResult

    }

}