<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
BeforeAll {
    # Import the module
    $ModulePath = Split-Path -Parent $PSScriptRoot
    Import-Module "$ModulePath\DattoRMM.Core.psd1" -Force
}

Describe 'Connect-DattoRMM' {
    
    BeforeEach {
        # Clear auth state before each test
        $script:RMMAuth = $null
        $script:APIUrl = $null
        $script:API = $null
    }

    Context 'Authentication with Key and Secret' {
        
        BeforeAll {
            # Mock the OAuth token endpoint
            Mock Invoke-RestMethod {
                [PSCustomObject]@{
                    access_token = 'test-access-token-12345'
                    token_type = 'Bearer'
                    expires_in = 360000
                }
            } -ParameterFilter {$Uri -like '*/auth/oauth/token'}

            # Mock the pagination endpoint test
            Mock Invoke-APIMethod {
                [PSCustomObject]@{max = 100}
            } -ParameterFilter {$Path -eq 'system/pagination'}
        }

        It 'Connects successfully with Key and Secret parameters' {
            $Secret = ConvertTo-SecureString 'test-secret' -AsPlainText -Force
            {Connect-DattoRMM -Key 'test-key' -Secret $Secret} | Should -Not -Throw
        }

        It 'Sets script:RMMAuth with token data' {
            $Secret = ConvertTo-SecureString 'test-secret' -AsPlainText -Force
            Connect-DattoRMM -Key 'test-key' -Secret $Secret
            
            $script:RMMAuth | Should -Not -BeNullOrEmpty
            $script:RMMAuth.AccessToken | Should -Be 'test-access-token-12345'
            $script:RMMAuth.TokenType | Should -Be 'Bearer'
            $script:RMMAuth.ExpiresAt | Should -BeOfType [datetime]
        }

        It 'Creates authorization header correctly' {
            $Secret = ConvertTo-SecureString 'test-secret' -AsPlainText -Force
            Connect-DattoRMM -Key 'test-key' -Secret $Secret
            
            $script:RMMAuth.AuthHeader.Authorization | Should -Be 'Bearer test-access-token-12345'
        }

        It 'Sets AutoRefresh to false by default' {
            $Secret = ConvertTo-SecureString 'test-secret' -AsPlainText -Force
            Connect-DattoRMM -Key 'test-key' -Secret $Secret
            
            $script:RMMAuth.AutoRefresh | Should -Be $false
            $script:RMMAuth.Keys.Contains('Key') | Should -Be $false
            $script:RMMAuth.Keys.Contains('Secret') | Should -Be $false
        }

        It 'Stores credentials when AutoRefresh is enabled' {
            $Secret = ConvertTo-SecureString 'test-secret' -AsPlainText -Force
            Connect-DattoRMM -Key 'test-key' -Secret $Secret -AutoRefresh
            
            $script:RMMAuth.AutoRefresh | Should -Be $true
            $script:RMMAuth.Key | Should -Be 'test-key'
            $script:RMMAuth.Secret | Should -BeOfType [securestring]
        }

        It 'Calls OAuth endpoint with correct parameters' {
            $Secret = ConvertTo-SecureString 'test-secret' -AsPlainText -Force
            Connect-DattoRMM -Key 'test-key' -Secret $Secret
            
            Should -Invoke Invoke-RestMethod -ParameterFilter {
                $Uri -like '*/auth/oauth/token' -and
                $Method -eq 'Post' -and
                $Body -like '*grant_type=password*' -and
                $ContentType -eq 'application/x-www-form-urlencoded'
            }
        }

        It 'Tests connection by fetching pagination settings' {
            $Secret = ConvertTo-SecureString 'test-secret' -AsPlainText -Force
            Connect-DattoRMM -Key 'test-key' -Secret $Secret
            
            Should -Invoke Invoke-APIMethod -ParameterFilter {
                $Path -eq 'system/pagination'
            }
        }

        It 'Sets PageSize from API response' {
            $Secret = ConvertTo-SecureString 'test-secret' -AsPlainText -Force
            Connect-DattoRMM -Key 'test-key' -Secret $Secret
            
            $script:PageSize | Should -Be 100
        }
    }

    Context 'Authentication with PSCredential' {
        
        BeforeAll {
            Mock Invoke-RestMethod {
                [PSCustomObject]@{
                    access_token = 'cred-token-67890'
                    token_type = 'Bearer'
                    expires_in = 360000
                }
            } -ParameterFilter {$Uri -like '*/auth/oauth/token'}

            Mock Invoke-APIMethod {
                [PSCustomObject]@{max = 100}
            } -ParameterFilter {$Path -eq 'system/pagination'}
        }

        It 'Accepts PSCredential parameter' {
            $Cred = [PSCredential]::new('api-key', (ConvertTo-SecureString 'api-secret' -AsPlainText -Force))
            {Connect-DattoRMM -Credential $Cred} | Should -Not -Throw
        }

        It 'Extracts key and secret from credential correctly' {
            $Cred = [PSCredential]::new('my-key', (ConvertTo-SecureString 'my-secret' -AsPlainText -Force))
            Connect-DattoRMM -Credential $Cred
            
            Should -Invoke Invoke-RestMethod -ParameterFilter {
                $Body -like '*username=my-key*' -and
                $Body -like '*password=my-secret*'
            }
        }

        It 'Supports Cred alias for Credential parameter' {
            $Command = Get-Command Connect-DattoRMM
            $CredParam = $Command.Parameters['Credential']
            $CredParam.Aliases | Should -Contain 'Cred'
        }
    }

    Context 'Platform selection' {
        
        BeforeAll {
            Mock Invoke-RestMethod {
                [PSCustomObject]@{
                    access_token = 'platform-token'
                    token_type = 'Bearer'
                    expires_in = 360000
                }
            }

            Mock Invoke-APIMethod {
                [PSCustomObject]@{max = 100}
            }
        }

        It 'Uses Pinotage platform by default' {
            $Secret = ConvertTo-SecureString 'test-secret' -AsPlainText -Force
            Connect-DattoRMM -Key 'test-key' -Secret $Secret
            
            $script:APIUrl | Should -Be 'https://pinotage-api.centrastage.net'
            $script:API | Should -Be 'https://pinotage-api.centrastage.net/api/v2'
        }

        It 'Accepts different platform values' {
            $Secret = ConvertTo-SecureString 'test-secret' -AsPlainText -Force
            Connect-DattoRMM -Key 'test-key' -Secret $Secret -Platform Merlot
            
            $script:APIUrl | Should -Be 'https://merlot-api.centrastage.net'
        }

        It 'Sets API base URL correctly for selected platform' {
            $Secret = ConvertTo-SecureString 'test-secret' -AsPlainText -Force
            Connect-DattoRMM -Key 'test-key' -Secret $Secret -Platform Concord
            
            Should -Invoke Invoke-RestMethod -ParameterFilter {
                $Uri -eq 'https://concord-api.centrastage.net/auth/oauth/token'
            }
        }
    }

    Context 'Error handling' {
        
        BeforeAll {
            Mock Invoke-RestMethod {
                throw [System.Net.WebException]::new('Unauthorized')
            } -ParameterFilter {$Uri -like '*/auth/oauth/token'}
        }

        It 'Throws error when authentication fails' {
            $Secret = ConvertTo-SecureString 'bad-secret' -AsPlainText -Force
            {Connect-DattoRMM -Key 'bad-key' -Secret $Secret} | Should -Throw
        }

        It 'Does not set RMMAuth when authentication fails' {
            $Secret = ConvertTo-SecureString 'bad-secret' -AsPlainText -Force
            try {
                Connect-DattoRMM -Key 'bad-key' -Secret $Secret
            } catch {}
            
            $script:RMMAuth | Should -BeNullOrEmpty
        }
    }

    Context 'Token expiration calculation' {
        
        BeforeAll {
            Mock Invoke-RestMethod {
                [PSCustomObject]@{
                    access_token = 'expiry-token'
                    token_type = 'Bearer'
                    expires_in = 3600
                }
            } -ParameterFilter {$Uri -like '*/auth/oauth/token'}

            Mock Invoke-APIMethod {
                [PSCustomObject]@{max = 100}
            }
        }

        It 'Calculates ExpiresAt from expires_in' {
            $Before = Get-Date
            $Secret = ConvertTo-SecureString 'test-secret' -AsPlainText -Force
            Connect-DattoRMM -Key 'test-key' -Secret $Secret
            $After = Get-Date
            
            $script:RMMAuth.ExpiresAt | Should -BeGreaterThan $Before.AddSeconds(3500)
            $script:RMMAuth.ExpiresAt | Should -BeLessThan $After.AddSeconds(3700)
        }

        It 'Token should not be expired immediately after connect' {
            $Secret = ConvertTo-SecureString 'test-secret' -AsPlainText -Force
            Connect-DattoRMM -Key 'test-key' -Secret $Secret
            
            $script:RMMAuth.ExpiresAt | Should -BeGreaterThan (Get-Date)
        }
    }

    Context 'Parameter sets' {
        
        It 'Has Key parameter set' {
            $Command = Get-Command Connect-DattoRMM
            $Command.ParameterSets.Name | Should -Contain 'Key'
        }

        It 'Has Cred parameter set' {
            $Command = Get-Command Connect-DattoRMM
            $Command.ParameterSets.Name | Should -Contain 'Cred'
        }

        It 'Key is default parameter set' {
            $Command = Get-Command Connect-DattoRMM
            $Command.DefaultParameterSet | Should -Be 'Key'
        }

        It 'Key and Secret are mandatory in Key set' {
            $Command = Get-Command Connect-DattoRMM
            $KeyParam = $Command.Parameters['Key'].Attributes | Where-Object {$_.ParameterSetName -eq 'Key'}
            $SecretParam = $Command.Parameters['Secret'].Attributes | Where-Object {$_.ParameterSetName -eq 'Key'}
            
            $KeyParam.Mandatory | Should -Be $true
            $SecretParam.Mandatory | Should -Be $true
        }

        It 'Credential is mandatory in Cred set' {
            $Command = Get-Command Connect-DattoRMM
            $CredParam = $Command.Parameters['Credential'].Attributes | Where-Object {$_.ParameterSetName -eq 'Cred'}
            
            $CredParam.Mandatory | Should -Be $true
        }
    }

    Context 'Verbose and Debug output' {
        
        BeforeAll {
            Mock Invoke-RestMethod {
                [PSCustomObject]@{
                    access_token = 'verbose-token'
                    token_type = 'Bearer'
                    expires_in = 360000
                }
            } -ParameterFilter {$Uri -like '*/auth/oauth/token'}

            Mock Invoke-APIMethod {
                [PSCustomObject]@{max = 100}
            }
        }

        It 'Outputs verbose message on successful connection' {
            $Secret = ConvertTo-SecureString 'test-secret' -AsPlainText -Force
            $VerboseOutput = Connect-DattoRMM -Key 'test-key' -Secret $Secret -Verbose 4>&1
            
            $VerboseOutput | Should -Match 'Successfully authenticated'
        }
    }
}

