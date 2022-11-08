Describe "Testing Format-YAML" {

    #
    # Arrange

    $params = @(
        @{
            HashTable = @{
                Prop3 = 'Test3'
                Prop2 = 'Test2'  
                Prop1 = 'Test'                              
            }
            Properties = 'Prop1','Prop2','Prop3'
            Result = 'Prop1','Prop2','Prop3'
        },
        @{
            HashTable = @{
                Prop3 = 'Test3'
                Prop2 = 'Test2'  
                Prop1 = 'Test'                              
            }
            Properties = 'Prop1','Prop3'
            Result = 'Prop1','Prop3'
        },
        @{
            HashTable = @{
                Prop2 = 'Test2'  
                Prop1 = 'Test'                              
            }
            Properties = 'Prop2','Prop1'
            Result = 'Prop2','Prop1'
        }                
    )

    it "Properties (<Properties>) Should return (<Result>)" -TestCases $params {
        param($HashTable, $Properties, $Result)
        
        #
        # Act
        $output = Format-YAML -Table $HashTable -Property $Properties 

        #
        # Assert
        $output.PSObject.Properties.Name | Should -be $Result
    }

}