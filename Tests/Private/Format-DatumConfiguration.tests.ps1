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

        #
        # Arrange

        $params = @{
            DatumConfiguration = [PSCustomObject]@{
                Name = 'Value'
            }
            NodeTemplateConfiguration = [PSCustomObject]@{
                Data = 'Value'
            }
        }

        #
        # Act

        $result = Format-DatumConfiguration @params

        #
        # Assert        
        $result.TemplateConfiguration | Should -Not -BeNullOrEmpty

    }

    it "Should return TemplateFilePath" {

        #
        # Arrange 

        $params = @{
            DatumConfiguration = [PSCustomObject]@{
                Name = 'Value'
            }
            NodeTemplateConfiguration = [PSCustomObject]@{
                Data = 'Value'
            }
        }

        #
        # Act

        $result = Format-DatumConfiguration @params

        #
        # Assert        
        $result.TemplateFilePath | Should -Not -BeNullOrEmpty

    }

    it "Should return TemplateFilePath" {

        #
        # Arrange        
        $params = @{
            DatumConfiguration = [PSCustomObject]@{
                Name = 'Value'
            }
            NodeTemplateConfiguration = [PSCustomObject]@{
                Data = 'Value'
            }
        }

        #
        # Act        
        $result = Format-DatumConfiguration @params

        #
        # Assert        
        $result.TemplateFilePath | Should -Not -BeNullOrEmpty

    }

    it "Should properties that contain" {

        #
        # Arrange        
        $params = @{
            DatumConfiguration = Import-MockData 'Read-DatumConfiguration'
            NodeTemplateConfiguration = Import-MockData 'Get-NodeTemplateConfigParams'
        }

        #
        # Act        
        $result = Format-DatumConfiguration @params

        #
        # Assert        
        $result.DatumConfiguration.Count | Should -Be 5
        $result.DatumConfiguration.ParameterValues.Count | Should -Be 19
        $result.DatumConfiguration.isOverwritten.Count | Should -Be 5

    }

}