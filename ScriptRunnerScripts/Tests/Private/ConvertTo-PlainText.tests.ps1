Describe "Testing ConvertTo-PlainText" {

    it "Should return a String" {

        #
        # Arrange
        $password = 'password'
        #
        # Act
        $secureString = $password | ConvertTo-SecureString -AsPlainText -Force
        $result = $secureString | ConvertTo-PlainText 

        #
        # Assert
        $result | Should -Be $password

    }

}