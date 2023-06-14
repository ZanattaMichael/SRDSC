Describe "ConvertTo-PowerShellParameter" {

    BeforeAll {
        $configurationTemplates = @{
            DatumConfiguration = @(
                @{
                    ParameterName = "NodeName"
                    ParameterValues = "Node1", "Node2", "Node3"
                    isOverwritten = $false
                },
                @{
                    ParameterName = "IPAddress"
                    ParameterValues = "10.0.0.1", "10.0.0.2", "10.0.0.3"
                    isOverwritten = $true
                }
            )
            TemplateConfiguration = @(
                @{
                    ParameterName = "VMName"
                    YAMLPath = "VirtualMachine/Name"
                },
                @{
                    ParameterName = "VMSize"
                    YAMLPath = "VirtualMachine/Size"
                }
            )
        }
    }

    It "returns a string of PowerShell parameters" {
        $result = ConvertTo-PowerShellParameter -ConfigurationTemplates $configurationTemplates
        $result | Should -BeOfType [String]
    }

    Context "when given valid input" {
        It "returns a string with mandatory parameters" {
            $result = ConvertTo-PowerShellParameter -ConfigurationTemplates $configurationTemplates
            $result | Should -Match "`t\[Parameter\(Mandatory\)\]"
        }

        It "returns a string with ValidateSet attributes" {
            $result = ConvertTo-PowerShellParameter -ConfigurationTemplates $configurationTemplates
            $result | Should -Match "`t\[ValidateSet\('.+'\)\]*"
        }

        It "returns a string with String data type" {
            $result = ConvertTo-PowerShellParameter -ConfigurationTemplates $configurationTemplates
            $result | Should -Match "`t\[String\]"
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
