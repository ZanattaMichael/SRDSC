describe "Testing ConvertYAMLPathTo-Parameter" {

    $testCases = @(
        @{
            Name = 'Testing Nested Arrays (Index Entry other then Zero)'
            Path = '$MOCK."Property"."Array"[0]."SecondArray"[1]'
            expectedResult = @{
                String = $null
                ParameterLabel = 'ArraySecondArray1'
            }        
        }
        @{
            Name = 'Testing Single Property (No Array)'
            Path = '$MOCK."Property"'
            expectedResult = @{
                String = $null
                ParameterLabel = 'Property'
            }       
        }
        @{
            Name = 'Testing Single Array Property (Zero Index)'
            Path = '$MOCK."Property"."Array"[0]."Property"'
            expectedResult = @{
                String = $null
                ParameterLabel = 'ArrayProperty'
            }       
        }
        @{
            Name = 'Testing Single Array Property (First Index)'
            Path = '$MOCK."Property"."Array"[1]."Property"'
            expectedResult = @{
                String = $null
                ParameterLabel = 'Array1Property'
            }       
        }    
        @{
            Name = 'Testing Single Array 2 Property'
            Path = '$MOCK."Object1"."Array"[1]."Object2"."Property"'
            expectedResult = @{
                String = $null
                ParameterLabel = 'Array1Property'
            }       
        }              
        @{
            Name = 'Testing Single Array Property (Multiple Index)'
            Path = '$MOCK."Array"[5]."Array"[1]."Property"'
            expectedResult = @{
                String = $null
                ParameterLabel = 'Array5Array1Property'
            }       
        }  
        @{
            Name = 'Testing Nested Object Property'
            Path = '$MOCK."Object1"."Object2"."Property"'
            expectedResult = @{
                String = $null
                ParameterLabel = 'Property'
            }       
        }         
        @{
            Name = 'Testing Single Property (with double periods - slightly malformed)'
            Path = '$MOCK."Array"[1].."Property"'
            expectedResult = @{
                String = $null
                ParameterLabel = 'Array1Property'
            }       
        }         
    )

    it "<name>" -TestCases $testCases {
        param($Name, $Path, $expectedResult)

        #
        # Arrange
        
        # Set the Path to be the return string. They are the same.
        $expectedResult.String = $Path

        #
        # Act
        $testResult = $Path | ConvertYAMLPathTo-Parameter
        #
        # Assert
        $testResult.String | Should -be $Path
        $testResult.ParameterLabel | Should -be $expectedResult.ParameterLabel

    }

    it "throw an error, with malformed input" {

        #
        # Act and Assert

        { '$MOCK."Array[5].Array[1].Property"' | ConvertYAMLPathTo-Parameter } | Should -Throw

    }

}