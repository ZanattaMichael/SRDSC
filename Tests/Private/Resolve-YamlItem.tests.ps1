
Describe "Testing Resolve-YamlItem" {

    Mock -CommandName "Get-ChildItem" -MockWith {

        #
        # Arrange

        return @(
            New-MockFilePath 'MOCK:TopLevel\Second Level\Third Level\File.yml'
        )

    }

    it "Should return the correct properties" {

        #
        # Arrange

        Mock -CommandName "Get-ChildItem" -MockWith {
            return @(
                New-MockFilePath 'MOCK:TopLevel\Second Level\Third Level\File.yml'
            )
        } 

        #
        # Act        

        $result = Resolve-YamlItem 'MOCK:TopLevel'

        #
        # Assert

        $result.ItemPath | Should -not -BeNullOrEmpty
        $result.TopLevelParent | Should -not -BeNullOrEmpty
        $result.ItemName | Should -not -BeNullOrEmpty
        $result.Depth | Should -not -BeNullOrEmpty

    }

    it "A singular item should return the correct values" {

        #
        # Arrange

        Mock -CommandName "Get-ChildItem" -MockWith {
            return @(
                New-MockFilePath 'MOCK:Top\Second\Third\File.yml'
            )
        } 

        #
        # Act

        $result = Resolve-YamlItem 'MOCK:Top'

        #
        # Assert
                
        $result.ItemPath | Should -be '\Second\Third\File'
        $result.TopLevelParent | Should -be 'Second'
        $result.ItemName | Should -be 'File'
        $result.Depth | Should -be 3     

    }

}