
Describe "Testing Read-DatumConfiguration" {

    BeforeAll {
        Mock -CommandName 'Get-Content' -MockWith { return "MOCK" }
        Mock -CommandName 'Test-Path' -MockWith { return $true }
        Mock -CommandName 'ConvertFrom-Yaml' -MockWith { 
            [PSCustomObject]@{
                ResolutionPrecedence = @('MOCK','MOCK')
            }
        }
        Mock -CommandName 'Resolve-DatumItem' -MockWith { 
            return 'MOCK'
        }
        Mock -CommandName 'Resolve-YamlItem' -MockWith { return 'MOCK' }

    }

    it 'Should return a response' {

        $params = @{
            DatumConfigurationFile = 'MOCK'
            DatumConfigurationPath = 'MOCK'
        }
        Read-DatumConfiguration @params | Should -Not -BeNullOrEmpty

    }

}