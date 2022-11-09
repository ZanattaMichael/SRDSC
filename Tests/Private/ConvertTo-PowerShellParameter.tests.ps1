Describe "Testing ConvertTo-PowerShellParameter" {

    it "Should return a list of parameters" {

        #
        # Arrange

        $formattedDatumParams = @{
            DatumConfiguration = Import-MockData -CommandName 'Read-DatumConfiguration'
            NodeTemplateConfiguration = Import-MockData -CommandName 'Get-NodeTemplateConfigParams'
        }

        $parameterValues = @(
            'DSCFile01'
            'DSCFile02'
            'DSCFile03'
            'DSCWeb01'
            'DSCWeb02'
            'DSCWeb03'
            'SERVER01'
            'Dev'
            'Prod'
            'Test'
            'Frankfurt'
            'London'
            'Singapore'
            'Tokio'
            'DomainController'
            'FileServer'
            'WebServer'
            'Desktop'
            'Security'
        )

        #
        # Act

        $formattedDatumConfig = Format-DatumConfiguration @formattedDatumParams

        #
        # Assert

        $formattedDatumConfig.TemplateFilePath | Should -not -BeNullOrEmpty
        $formattedDatumConfig.DatumConfiguration | Should -not -BeNullOrEmpty
        $formattedDatumConfig.DatumConfiguration | Should -not -BeNullOrEmpty
        $formattedDatumConfig.DatumConfiguration.ParameterValues.Count | Should -be 19
        $formattedDatumConfig.DatumConfiguration.ParameterValues | Should -be $parameterValues

    }
    
}