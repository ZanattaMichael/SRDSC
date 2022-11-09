Describe "Testing Get-ASTScriptParameters" {

    BeforeAll {

        Mock -CommandName "Get-Command" -MockWith {

            return @{
                ScriptBlock = @{
                    Ast = @{
                        ParamBlock = @{
                            Parameters = @{
                                Name = @{
                                    Extent = @{
                                        Text = 
'$Parameter1
$Parameter2
$Parameter3'
                                    }
                                }
                            }
                        }
                    }
                }
            }

            (Get-Command $ScriptPath).ScriptBlock.Ast.ParamBlock.Parameters.Name.Extent.Text
        }

        Mock -CommandName "Get-Content" -MockWith {
            return '
            #JSONData: {"MockProperty":"MockValue"}
            '          
        }

    }

    it "should return the correct data" {

        #
        # Arrange

        $Parameters = 
'$Parameter1
$Parameter2
$Parameter3'

        #
        # Act
        $result = Get-ASTScriptParameters -ScriptPath 'MOCK'

        #
        # Assert
        $result.Parameters | Should -be $Parameters
        $result.YAMLData.MockProperty | Should -be 'MockValue'

    }

}