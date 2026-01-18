<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
BeforeAll {
    # Import the module
    $ModulePath = Split-Path -Parent $PSScriptRoot
    Import-Module "$ModulePath\DattoRMM.Core.psd1" -Force

    # Mock authentication state
    $script:RMMAuth = @{
        AccessToken = 'fake-token'
        TokenType = 'Bearer'
        ExpiresAt = (Get-Date).AddHours(1)
        AutoRefresh = $false
        AuthHeader = @{Authorization = 'Bearer fake-token'}
    }
}

Describe 'Get-RMMVariable' {
    
    Context 'Global scope - All variables' {
        
        BeforeAll {
            # Mock the API response for global variables
            Mock Invoke-APIMethod {
                @(
                    [PSCustomObject]@{id = 1; name = 'GlobalVar1'; value = 'Value1'; masked = $false}
                    [PSCustomObject]@{id = 2; name = 'GlobalVar2'; value = 'Secret123'; masked = $true}
                )
            } -ParameterFilter {$Path -eq 'account/variables'}
        }

        It 'Returns all global variables when no parameters specified' {
            $Result = Get-RMMVariable
            $Result | Should -HaveCount 2
            $Result[0].Name | Should -Be 'GlobalVar1'
            $Result[0].Scope | Should -Be 'Global'
            $Result[0].IsGlobal() | Should -Be $true
        }

        It 'Calls the correct API endpoint' {
            Get-RMMVariable
            Should -Invoke Invoke-APIMethod -ParameterFilter {
                $Path -eq 'account/variables' -and
                $Paginate -eq $true -and
                $PageElement -eq 'variables'
            }
        }

        It 'Creates DRMMVariable objects with correct properties' {
            $Result = Get-RMMVariable
            $Result[0] | Should -BeOfType [DRMMVariable]
            $Result[0].Id | Should -Be 1
            $Result[0].Value | Should -Be 'Value1'
            $Result[0].IsSecret | Should -Be $false
        }

        It 'Handles masked secrets correctly' {
            $Result = Get-RMMVariable
            $Result[1].IsSecret | Should -Be $true
            $Result[1].Value | Should -Be 'Secret123'
        }
    }

    Context 'Global scope - Filter by Id' {
        
        BeforeAll {
            Mock Invoke-APIMethod {
                @(
                    [PSCustomObject]@{id = 1; name = 'GlobalVar1'; value = 'Value1'; masked = $false}
                    [PSCustomObject]@{id = 2; name = 'GlobalVar2'; value = 'Value2'; masked = $false}
                    [PSCustomObject]@{id = 3; name = 'GlobalVar3'; value = 'Value3'; masked = $false}
                )
            } -ParameterFilter {$Path -eq 'account/variables'}
        }

        It 'Filters by Id and returns single result' {
            $Result = Get-RMMVariable -Id 2
            $Result | Should -HaveCount 1
            $Result.Id | Should -Be 2
            $Result.Name | Should -Be 'GlobalVar2'
        }

        It 'Returns nothing when Id does not exist' {
            $Result = Get-RMMVariable -Id 999
            $Result | Should -BeNullOrEmpty
        }
    }

    Context 'Global scope - Filter by Name' {
        
        BeforeAll {
            Mock Invoke-APIMethod {
                @(
                    [PSCustomObject]@{id = 1; name = 'Database'; value = 'prod-db'; masked = $false}
                    [PSCustomObject]@{id = 2; name = 'ApiKey'; value = 'key123'; masked = $true}
                )
            } -ParameterFilter {$Path -eq 'account/variables'}
        }

        It 'Filters by Name correctly' {
            $Result = Get-RMMVariable -Name 'Database'
            $Result | Should -HaveCount 1
            $Result.Name | Should -Be 'Database'
            $Result.Value | Should -Be 'prod-db'
        }

        It 'Name matching is case-sensitive (PS default)' {
            $Result = Get-RMMVariable -Name 'database'
            $Result | Should -BeNullOrEmpty
        }
    }

    Context 'Site scope - Using DRMMSite object' {
        
        BeforeAll {
            $TestSiteUid = [guid]'12345678-1234-1234-1234-123456789abc'
            
            # Create a mock DRMMSite object
            $script:MockSite = [DRMMSite]::new()
            $script:MockSite.Uid = $TestSiteUid
            $script:MockSite.Name = 'Test Site'

            Mock Invoke-APIMethod {
                @(
                    [PSCustomObject]@{id = 10; name = 'SiteVar1'; value = 'SiteValue1'; masked = $false}
                    [PSCustomObject]@{id = 11; name = 'SiteVar2'; value = 'SiteValue2'; masked = $false}
                )
            } -ParameterFilter {$Path -eq "site/$TestSiteUid/variables"}
        }

        It 'Accepts DRMMSite from parameter' {
            $Result = Get-RMMVariable -Site $MockSite
            $Result | Should -HaveCount 2
            $Result[0].Scope | Should -Be 'Site'
            $Result[0].SiteUid | Should -Be $TestSiteUid
            $Result[0].IsSite() | Should -Be $true
        }

        It 'Accepts DRMMSite from pipeline' {
            $Result = $MockSite | Get-RMMVariable
            $Result | Should -HaveCount 2
            $Result[0].Name | Should -Be 'SiteVar1'
        }

        It 'Filters site variables by Id' {
            $Result = Get-RMMVariable -Site $MockSite -Id 11
            $Result | Should -HaveCount 1
            $Result.Id | Should -Be 11
            $Result.Name | Should -Be 'SiteVar2'
        }

        It 'Filters site variables by Name' {
            $Result = Get-RMMVariable -Site $MockSite -Name 'SiteVar1'
            $Result | Should -HaveCount 1
            $Result.Name | Should -Be 'SiteVar1'
        }

        It 'Calls the correct site-specific endpoint' {
            Get-RMMVariable -Site $MockSite
            Should -Invoke Invoke-APIMethod -ParameterFilter {
                $Path -eq "site/$TestSiteUid/variables"
            }
        }
    }

    Context 'Site scope - Using SiteUid directly' {
        
        BeforeAll {
            $TestSiteUid = [guid]'87654321-4321-4321-4321-cba987654321'

            Mock Invoke-APIMethod {
                @(
                    [PSCustomObject]@{id = 20; name = 'DirectVar'; value = 'DirectValue'; masked = $false}
                )
            } -ParameterFilter {$Path -eq "site/$TestSiteUid/variables"}
        }

        It 'Accepts SiteUid as parameter' {
            $Result = Get-RMMVariable -SiteUid $TestSiteUid
            $Result | Should -HaveCount 1
            $Result.SiteUid | Should -Be $TestSiteUid
        }

        It 'Accepts SiteUid from pipeline by property name' {
            $InputObject = [PSCustomObject]@{Uid = $TestSiteUid}
            $Result = $InputObject | Get-RMMVariable
            $Result | Should -HaveCount 1
            $Result.Name | Should -Be 'DirectVar'
        }

        It 'Works with SiteUid and Id filter' {
            $Result = Get-RMMVariable -SiteUid $TestSiteUid -Id 20
            $Result.Id | Should -Be 20
        }

        It 'Works with SiteUid and Name filter' {
            $Result = Get-RMMVariable -SiteUid $TestSiteUid -Name 'DirectVar'
            $Result.Name | Should -Be 'DirectVar'
        }
    }

    Context 'Parameter set validation' {
        
        It 'GlobalAll is the default parameter set' {
            $Command = Get-Command Get-RMMVariable
            $Command.DefaultParameterSet | Should -Be 'GlobalAll'
        }

        It 'Has correct parameter sets defined' {
            $Command = Get-Command Get-RMMVariable
            $Sets = $Command.ParameterSets.Name
            $Sets | Should -Contain 'GlobalAll'
            $Sets | Should -Contain 'GlobalById'
            $Sets | Should -Contain 'GlobalByName'
            $Sets | Should -Contain 'SiteAll'
            $Sets | Should -Contain 'SiteById'
            $Sets | Should -Contain 'SiteByName'
            $Sets | Should -Contain 'SiteAllUid'
            $Sets | Should -Contain 'SiteUidById'
            $Sets | Should -Contain 'SiteUidByName'
        }

        It 'Site parameter accepts pipeline input' {
            $Command = Get-Command Get-RMMVariable
            $SiteParam = $Command.Parameters['Site']
            $SiteParam.Attributes.ValueFromPipeline | Should -Contain $true
        }

        It 'SiteUid parameter accepts pipeline by property name' {
            $Command = Get-Command Get-RMMVariable
            $UidParam = $Command.Parameters['SiteUid']
            $UidParam.Attributes.ValueFromPipelineByPropertyName | Should -Contain $true
        }

        It 'SiteUid has Uid alias' {
            $Command = Get-Command Get-RMMVariable
            $UidParam = $Command.Parameters['SiteUid']
            $UidParam.Aliases | Should -Contain 'Uid'
        }
    }

    Context 'Edge cases and error handling' {
        
        BeforeAll {
            Mock Invoke-APIMethod {
                @()
            } -ParameterFilter {$Path -eq 'account/variables'}
        }

        It 'Handles empty result set gracefully' {
            $Result = Get-RMMVariable
            $Result | Should -BeNullOrEmpty
        }

        It 'Filter returns nothing when no match' {
            $Result = Get-RMMVariable -Name 'NonExistent'
            $Result | Should -BeNullOrEmpty
        }
    }
}

