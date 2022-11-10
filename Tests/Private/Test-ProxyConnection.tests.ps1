Describe "Testing Test-ProxyConnection" {

    it 'Should return $false - error creating the proxy object' {

        #
        # Arrange

        mock -CommandName 'New-Object' -MockWith {
            throw "MOCK ERROR"
        }

        mock -CommandName 'Write-Warning' -MockWith {}
        mock -CommandName 'Write-Host' -MockWith {}

        #
        # Act
        $result = Test-ProxyConnection

        #
        # Assert
        $result | Should -Be $false
        Assert-MockCalled -CommandName 'Write-Warning' -Exactly 1
        Assert-MockCalled -CommandName 'Write-Host' -Exactly 0
        Assert-MockCalled -CommandName 'New-Object' -Exactly 1

    }

    it 'Should return $false if no proxy was detected' {

        mock -CommandName 'New-Object' -MockWith {
            $obj = New-MockObject -Type 'System.Net.WebClient' -Properties @{
                Proxy = New-MockObject -Type 'System.Net.WebProxy' -Methods @{
                    GetProxies = {
                        param($uri)
                        return $null
                    }
                }
                Credentials = $null
            }
            return $obj
        }

        mock -CommandName 'Write-Warning' -MockWith {}
        mock -CommandName 'Write-Host' -MockWith {}

        #
        # Act
        $result = Test-ProxyConnection

        #
        # Assert
        $result | Should -Be $false
        Assert-MockCalled -CommandName 'Write-Warning' -Exactly 0
        Assert-MockCalled -CommandName 'Write-Host' -Exactly 1
        Assert-MockCalled -CommandName 'New-Object' -Exactly 1

    }

    it 'Should return $true if a proxy was detected' {

        mock -CommandName 'New-Object' -MockWith {
            $obj = New-MockObject -Type 'System.Net.WebClient' -Properties @{
                Proxy = New-MockObject -Type 'System.Net.WebProxy' -Methods @{
                    GetProxies = {
                        param($uri)
                        return ([URI]::New('https://mock.com'))
                    }
                }
                Credentials = $null
            }
            return $obj
        }

        mock -CommandName 'Write-Warning' -MockWith {}
        mock -CommandName 'Write-Host' -MockWith {}

        #
        # Act
        $result = Test-ProxyConnection

        #
        # Assert
        $result | Should -Be $true
        Assert-MockCalled -CommandName 'Write-Warning' -Exactly 1
        Assert-MockCalled -CommandName 'Write-Host' -Exactly 1
        Assert-MockCalled -CommandName 'New-Object' -Exactly 1

    }

    it 'Should return $false if a proxy was detected, however it coulden''t set the credentials' {

        mock -CommandName 'New-Object' -MockWith {
            $obj = New-MockObject -Type 'System.Net.WebClient' -Properties @{
                Proxy = New-MockObject -Type 'System.Net.WebProxy' -Methods @{
                    GetProxies = {
                        param($uri)
                        return ([URI]::New('https://mock.com'))
                    }
                }
                Credentials = $null
            }
            return $obj
        }
        
        mock -CommandName 'Get-DefaultNetworkCredentials' -MockWith { throw 'MOCK' }
        mock -CommandName 'Write-Warning' -MockWith {}
        mock -CommandName 'Write-Host' -MockWith {}

        #
        # Act
        $result = Test-ProxyConnection

        #
        # Assert
        $result | Should -Be $false
        Assert-MockCalled -CommandName 'Write-Warning' -Exactly 2
        Assert-MockCalled -CommandName 'Write-Host' -Exactly 0
        Assert-MockCalled -CommandName 'New-Object' -Exactly 1

    }    

}