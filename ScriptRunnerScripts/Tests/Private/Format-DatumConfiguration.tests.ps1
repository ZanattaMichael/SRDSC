Describe "Testing Format-DatumConfiguration" {

    BeforeAll {
        Backup-SRDSCState
        $Global:SRDSC = [PSCustomObject]@{
            ScriptRunner = @{
                NodeTemplateFile = 'MOCK'
            }
        }
    }

    AfterAll {
        Restore-SRDSCState
    }

    it "Should return TemplateConfiguration" {

        $params = @{
            DatumConfiguration = [PSCustomObject]@{
                Name = 'Value'
            }
            NodeTemplateConfiguration = [PSCustomObject]@{
                Data = 'Value'
            }
        }

        $result = Format-DatumConfiguration @params
        $result.TemplateConfiguration | Should -Not -BeNullOrEmpty

    }

    it "Should return TemplateFilePath" {

        $params = @{
            DatumConfiguration = [PSCustomObject]@{
                Name = 'Value'
            }
            NodeTemplateConfiguration = [PSCustomObject]@{
                Data = 'Value'
            }
        }

        $result = Format-DatumConfiguration @params
        $result.TemplateFilePath | Should -Not -BeNullOrEmpty

    }

    it "Should return TemplateFilePath" {

        $params = @{
            DatumConfiguration = [PSCustomObject]@{
                Name = 'Value'
            }
            NodeTemplateConfiguration = [PSCustomObject]@{
                Data = 'Value'
            }
        }

        $result = Format-DatumConfiguration @params
        $result.TemplateFilePath | Should -Not -BeNullOrEmpty

    }

    it "Should properties that contain" {

        $params = @{
            DatumConfiguration = Import-MockData 'Read-DatumConfiguration'
            NodeTemplateConfiguration = Import-MockData 'Get-NodeTemplateConfigParams'
        }

        $result = Format-DatumConfiguration @params

        $result.DatumConfiguration.Count | Should -Be 5
        $result.DatumConfiguration.ParameterValues.Count | Should -Be 19
        $result.DatumConfiguration.isOverwritten.Count | Should -Be 5

    }

}