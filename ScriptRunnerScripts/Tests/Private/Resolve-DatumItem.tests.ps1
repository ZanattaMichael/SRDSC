Describe "Testing Resolve-DatumItem" {

    <#
        - AllNodes\$($Node.Environment)\$($Node.NodeName)
        - Environment\$($Node.Environment)
        - Locations\$($Node.Location)
        - Roles\$($Node.Role)
        - Baselines\Security
        - Baselines\Infrastructure\$($Node.Baseline)
        - Baselines\DscLcm
    #>

    it "Should return the correct properties" {

        $YamlItems = @(
            [PSCustomObject]@{
                ItemPath = '\First\Second\File'
                TopLevelParent = 'First'
                ItemName = 'File'
                Depth = 3
            }
        )                                
        
        $params = @{
            DatumPath = 'First\Second\File'
            YamlItems = $YamlItems
        }

        $result = Resolve-DatumItem @params

        $output = @(
            [PSCustomObject]@{
                ItemScriptPath = '\First\Second\File'
                values = $null
                isVar = $false
                TopLevelParent = 'First'
                ItemName = 'File'
                Depth = 3
                ItemPath = '\First\Second\File'
            }
            [PSCustomObject]@{
                ItemScriptPath = '\First\Second'
                values = $null
                isVar = $false
                TopLevelParent = 'First'
                ItemName = 'Second'
                Depth = 2
                ItemPath = '\First\Second'
            }
            [PSCustomObject]@{
                ItemScriptPath = '\First'
                values = $null
                isVar = $false
                TopLevelParent = 'First'
                ItemName = 'First'
                Depth = 1
                ItemPath = '\First'
            }                            
        ) | ConvertTo-Json

        $result | ConvertTo-Json | Should -Be $output

    }

    it "Should return values matched from the YAML when a variable is included in the file path" {

        $YamlItems = @(
            [PSCustomObject]@{
                ItemPath = '\First\Second'
                TopLevelParent = 'First'
                ItemName = 'Second'
                Depth = 2
            }
        )                                
        
        $params = @{
            DatumPath = 'First\$($Node.MockFile)\File'
            YamlItems = $YamlItems
        }    

        $result = Resolve-DatumItem @params | Where-Object {$_.isVar}
        
        $result.values | Should -Be $YamlItems

    }
    
}