<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function Get-RMMFilter {
    <#
    .SYNOPSIS
        Retrieves filters from the Datto RMM API.

    .DESCRIPTION
        The Get-RMMFilter function retrieves filters at different scopes: global (account-level) or site-level. Filters can be retrieved by ID, name, or all filters at a given scope.

        Filters in Datto RMM are used to group devices based on criteria and can be applied when retrieving devices with Get-RMMDevice.

        Filters are categorized as either "Default" (built-in system filters) or "Custom" (user-created filters).

    .PARAMETER Site
        A DRMMSite object to retrieve filters for. Accepts pipeline input from Get-RMMSite.

    .PARAMETER Id
        Retrieve a specific filter by its numeric ID.

    .PARAMETER Name
        Retrieve a filter by its name (exact match).

    .PARAMETER FilterType
        Filter the results by type. Valid values: 'All', 'Default', 'Custom'. Default is 'All'.
        Only applicable for global scope queries.

    .EXAMPLE
        Get-RMMFilter

        Retrieves all filters at the account level.

    .EXAMPLE
        Get-RMMFilter -FilterType Custom

        Retrieves only custom (user-created) filters.

    .EXAMPLE
        Get-RMMFilter -Id 12345

        Retrieves a specific filter by its ID.

    .EXAMPLE
        Get-RMMFilter -Name "Windows Servers"

        Retrieves a filter by exact name match.

    .EXAMPLE
        Get-RMMSite -Name "Main Office" | Get-RMMFilter

        Gets all filters for the "Main Office" site.

    .EXAMPLE
        Get-RMMFilter -Name "Production Servers" | Get-RMMDevice

        Retrieves a filter by name and pipes it to Get-RMMDevice to retrieve matching devices.
        Site-scoped filters automatically route to the correct site endpoint.

    .EXAMPLE
        Get-RMMFilter -Id 12345 | Get-RMMDevice

        Retrieves a filter by ID and pipes it to Get-RMMDevice.

    .INPUTS
        DRMMSite. You can pipe site objects from Get-RMMSite.

    .OUTPUTS
        DRMMFilter. Returns filter objects with the following properties:
        - Id: Numeric identifier
        - Name: Filter name
        - Description: Filter description
        - Type: 'rmm_default' or 'custom'
        - Scope: 'Global' or 'Site'
        - SiteUid: Site identifier (for site-scoped filters)
        - DateCreate: Creation date
        - LastUpdated: Last modification date

    .NOTES
        This function requires an active connection to the Datto RMM API.
        Use Connect-DattoRMM to authenticate before calling this function.

        Filter objects can be piped directly to Get-RMMDevice to retrieve matching devices.
        Site-scoped filters automatically route to the correct site endpoint.
        Alternatively, use Get-RMMDevice -FilterId to retrieve devices by numeric filter ID.

    .LINK
        https://github.com/TheShadowTek/DattoRMM.Core/blob/main/docs/commands/Filter/Get-RMMFilter.md

    .LINK
        about_DRMMFilter

    .LINK
        Get-RMMDevice

    .LINK
        Get-RMMSite
    #>
    [CmdletBinding(DefaultParameterSetName = 'GlobalAll')]
    param (
        [Parameter(
            ParameterSetName = 'SiteAll',
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [Parameter(
            ParameterSetName = 'SiteById',
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [Parameter(
            ParameterSetName = 'SiteByName',
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [DRMMSite]
        $Site,

        [Parameter(
            ParameterSetName = 'GlobalById',
            Mandatory = $true
        )]
        [Parameter(
            ParameterSetName = 'SiteById',
            Mandatory = $true
        )]
        [int]
        $Id,

        [Parameter(
            ParameterSetName = 'GlobalByName',
            Mandatory = $true
        )]
        [Parameter(
            ParameterSetName = 'SiteByName',
            Mandatory = $true
        )]
        [string]
        $Name,

        [Parameter(
            ParameterSetName = 'GlobalAll'
        )]
        [Parameter(
            ParameterSetName = 'GlobalById'
        )]
        [Parameter(
            ParameterSetName = 'GlobalByName'
        )]
        [ValidateSet('All', 'Default', 'Custom')]
        [string]
        $FilterType = 'All'
    )

    process {

        Write-Debug "Getting RMM filter(s) using parameter set: $($PSCmdlet.ParameterSetName)"

        if ($PSCmdlet.ParameterSetName -match '^Site') {

            $APIMethod = @{
                Path = "site/$($Site.Uid)/filters"
                Method = 'Get'
                Paginate = $true
                PageElement = 'filters'
            }

            switch ($PSCmdlet.ParameterSetName) {

                'SiteAll' {

                    Write-Debug "Getting all filters for site: $($Site.Name) (UID: $($Site.Uid))"
                    Invoke-ApiMethod @APIMethod | ForEach-Object {

                        [DRMMFilter]::FromAPIMethod($_, 'Site', $Site, $Script:SessionPlatform)

                    }
                }

                'SiteById' {

                    Write-Debug "Getting site filter by ID: $Id for site: $($Site.Name) (UID: $($Site.Uid))"
                    Invoke-ApiMethod @APIMethod | Where-Object {$_.id -eq $Id} | ForEach-Object {

                        [DRMMFilter]::FromAPIMethod($_, 'Site', $Site, $Script:SessionPlatform)

                    }
                }

                'SiteByName' {

                    Write-Debug "Getting site filter by Name: $Name for site: $($Site.Name) (UID: $($Site.Uid))"
                    Invoke-ApiMethod @APIMethod | Where-Object {$_.name -eq $Name} | ForEach-Object {

                        [DRMMFilter]::FromAPIMethod($_, 'Site', $Site, $Script:SessionPlatform)

                    }
                }
            }

        } else {

            # Global scope - handle Default, Custom, or All
            $Methods = @()

            switch ($FilterType) {

                'Default' {

                    $Methods += @{
                        Path = 'filter/default-filters'
                        Scope = 'Global'
                    }
                }

                'Custom' {

                    $Methods += @{
                        Path = 'filter/custom-filters'
                        Scope = 'Global'
                    }
                }

                'All' {

                    $Methods += @{
                        Path = 'filter/default-filters'
                        Scope = 'Global'
                    }
                    $Methods += @{
                        Path = 'filter/custom-filters'
                        Scope = 'Global'
                    }
                }
            }

            foreach ($Method in $Methods) {

                $APIMethod = @{
                    Path = $Method.Path
                    Method = 'Get'
                    Paginate = $true
                    PageElement = 'filters'
                }

                switch ($PSCmdlet.ParameterSetName) {

                    'GlobalAll' {

                        Write-Debug "Getting global filters from $($Method.Path)"
                        Invoke-ApiMethod @APIMethod | ForEach-Object {

                            [DRMMFilter]::FromAPIMethod($_, $Method.Scope, $null, $Script:SessionPlatform)

                        }
                    }

                    'GlobalById' {

                        Write-Debug "Getting global filter by ID: $Id from $($Method.Path)"
                        Invoke-ApiMethod @APIMethod | Where-Object {$_.id -eq $Id} | ForEach-Object {

                            [DRMMFilter]::FromAPIMethod($_, $Method.Scope, $null, $Script:SessionPlatform)

                        }
                    }

                    'GlobalByName' {

                        Write-Debug "Getting global filter by Name: $Name from $($Method.Path)"
                        Invoke-ApiMethod @APIMethod | Where-Object {$_.name -eq $Name} | ForEach-Object {

                            [DRMMFilter]::FromAPIMethod($_, $Method.Scope, $null, $Script:SessionPlatform)

                        }
                    }
                }
            }
        }
    }
}


# SIG # Begin signature block
# MIIcXwYJKoZIhvcNAQcCoIIcUDCCHEwCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBErhfX0nr7sI6D
# HdZ4KVgDiLEeysTnEBbwPfMPJBFle6CCFogwggNKMIICMqADAgECAhB464iXHfI6
# gksEkDDTyrNsMA0GCSqGSIb3DQEBCwUAMD0xFjAUBgNVBAoMDVJvYmVydCBGYWRk
# ZXMxIzAhBgNVBAMMGkRhdHRvUk1NLkNvcmUgQ29kZSBTaWduaW5nMB4XDTI2MDMz
# MTAwMTMzMFoXDTI4MDMzMTAwMjMzMFowPTEWMBQGA1UECgwNUm9iZXJ0IEZhZGRl
# czEjMCEGA1UEAwwaRGF0dG9STU0uQ29yZSBDb2RlIFNpZ25pbmcwggEiMA0GCSqG
# SIb3DQEBAQUAA4IBDwAwggEKAoIBAQChn1EpMYQgl1RgWzQj2+wp2mvdfb3UsaBS
# nxEVGoQ0gj96tJ2MHAF7zsITdUjwaflKS1vE6wAlOg5EI1V79tJCMxzM0bFpOdR1
# L5F2HE/ovIAKNkHxFUF5qWU8vVeAsOViFQ4yhHpzLen0WLF6vhmc9eH23dLQy5fy
# tELZQEc2WbQFa4HMAitP/P9kHAu6CUx5s4woLIOyyR06jkr3l9vk0sxcbCxx7+dF
# RrsSLyPYPH+bUAB8+a0hs+6qCeteBuUfLvGzpMhpzKAsY82WZ3Rd9X38i32dYj+y
# dYx+nx+UEMDLjDJrZgnVa8as4RojqVLcEns5yb/XTjLxDc58VatdAgMBAAGjRjBE
# MA4GA1UdDwEB/wQEAwIHgDATBgNVHSUEDDAKBggrBgEFBQcDAzAdBgNVHQ4EFgQU
# H+B0vf97dYXqdUX1YMcWhFsY6fcwDQYJKoZIhvcNAQELBQADggEBAJmD4EEGNmcD
# 1JtFoRGxuLJaTHxDwBsjqcRQRE1VPZNGaiwIm8oSQdHVjQg0oIyK7SEb02cs6n6Y
# NZbwf7B7WZJ4aKYbcoLug1k1x9SoqwBmfElECeJTKXf6dkRRNmrAodpGCixR4wMH
# KXqwqP5F+5j7bdnQPiIVXuMesxc4tktz362ysph1bqKjDQSCBpwi0glEIH7bv5Ms
# Ey9Gl3fe+vYC5W06d2LYVebEfm9+7766hsOgpdDVgdtnN+e6uwIJjG/6PTG6TMDP
# y+pr5K6LyUVYJYcWWUTZRBqqwBHiLGekPbxrjEVfxUY32Pq4QfLzUH5hhUCAk4HN
# XpF9pOzFLMUwggWNMIIEdaADAgECAhAOmxiO+dAt5+/bUOIIQBhaMA0GCSqGSIb3
# DQEBDAUAMGUxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAX
# BgNVBAsTEHd3dy5kaWdpY2VydC5jb20xJDAiBgNVBAMTG0RpZ2lDZXJ0IEFzc3Vy
# ZWQgSUQgUm9vdCBDQTAeFw0yMjA4MDEwMDAwMDBaFw0zMTExMDkyMzU5NTlaMGIx
# CzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3
# dy5kaWdpY2VydC5jb20xITAfBgNVBAMTGERpZ2lDZXJ0IFRydXN0ZWQgUm9vdCBH
# NDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAL/mkHNo3rvkXUo8MCIw
# aTPswqclLskhPfKK2FnC4SmnPVirdprNrnsbhA3EMB/zG6Q4FutWxpdtHauyefLK
# EdLkX9YFPFIPUh/GnhWlfr6fqVcWWVVyr2iTcMKyunWZanMylNEQRBAu34LzB4Tm
# dDttceItDBvuINXJIB1jKS3O7F5OyJP4IWGbNOsFxl7sWxq868nPzaw0QF+xembu
# d8hIqGZXV59UWI4MK7dPpzDZVu7Ke13jrclPXuU15zHL2pNe3I6PgNq2kZhAkHnD
# eMe2scS1ahg4AxCN2NQ3pC4FfYj1gj4QkXCrVYJBMtfbBHMqbpEBfCFM1LyuGwN1
# XXhm2ToxRJozQL8I11pJpMLmqaBn3aQnvKFPObURWBf3JFxGj2T3wWmIdph2PVld
# QnaHiZdpekjw4KISG2aadMreSx7nDmOu5tTvkpI6nj3cAORFJYm2mkQZK37AlLTS
# YW3rM9nF30sEAMx9HJXDj/chsrIRt7t/8tWMcCxBYKqxYxhElRp2Yn72gLD76GSm
# M9GJB+G9t+ZDpBi4pncB4Q+UDCEdslQpJYls5Q5SUUd0viastkF13nqsX40/ybzT
# QRESW+UQUOsxxcpyFiIJ33xMdT9j7CFfxCBRa2+xq4aLT8LWRV+dIPyhHsXAj6Kx
# fgommfXkaS+YHS312amyHeUbAgMBAAGjggE6MIIBNjAPBgNVHRMBAf8EBTADAQH/
# MB0GA1UdDgQWBBTs1+OC0nFdZEzfLmc/57qYrhwPTzAfBgNVHSMEGDAWgBRF66Kv
# 9JLLgjEtUYunpyGd823IDzAOBgNVHQ8BAf8EBAMCAYYweQYIKwYBBQUHAQEEbTBr
# MCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wQwYIKwYBBQUH
# MAKGN2h0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJ
# RFJvb3RDQS5jcnQwRQYDVR0fBD4wPDA6oDigNoY0aHR0cDovL2NybDMuZGlnaWNl
# cnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNybDARBgNVHSAECjAIMAYG
# BFUdIAAwDQYJKoZIhvcNAQEMBQADggEBAHCgv0NcVec4X6CjdBs9thbX979XB72a
# rKGHLOyFXqkauyL4hxppVCLtpIh3bb0aFPQTSnovLbc47/T/gLn4offyct4kvFID
# yE7QKt76LVbP+fT3rDB6mouyXtTP0UNEm0Mh65ZyoUi0mcudT6cGAxN3J0TU53/o
# Wajwvy8LpunyNDzs9wPHh6jSTEAZNUZqaVSwuKFWjuyk1T3osdz9HNj0d1pcVIxv
# 76FQPfx2CWiEn2/K2yCNNWAcAgPLILCsWKAOQGPFmCLBsln1VWvPJ6tsds5vIy30
# fnFqI2si/xK4VC0nftg62fC2h5b9W9FcrBjDTZ9ztwGpn1eqXijiuZQwgga0MIIE
# nKADAgECAhANx6xXBf8hmS5AQyIMOkmGMA0GCSqGSIb3DQEBCwUAMGIxCzAJBgNV
# BAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdp
# Y2VydC5jb20xITAfBgNVBAMTGERpZ2lDZXJ0IFRydXN0ZWQgUm9vdCBHNDAeFw0y
# NTA1MDcwMDAwMDBaFw0zODAxMTQyMzU5NTlaMGkxCzAJBgNVBAYTAlVTMRcwFQYD
# VQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBH
# NCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBTSEEyNTYgMjAyNSBDQTEwggIiMA0GCSqG
# SIb3DQEBAQUAA4ICDwAwggIKAoICAQC0eDHTCphBcr48RsAcrHXbo0ZodLRRF51N
# rY0NlLWZloMsVO1DahGPNRcybEKq+RuwOnPhof6pvF4uGjwjqNjfEvUi6wuim5ba
# p+0lgloM2zX4kftn5B1IpYzTqpyFQ/4Bt0mAxAHeHYNnQxqXmRinvuNgxVBdJkf7
# 7S2uPoCj7GH8BLuxBG5AvftBdsOECS1UkxBvMgEdgkFiDNYiOTx4OtiFcMSkqTtF
# 2hfQz3zQSku2Ws3IfDReb6e3mmdglTcaarps0wjUjsZvkgFkriK9tUKJm/s80Fio
# cSk1VYLZlDwFt+cVFBURJg6zMUjZa/zbCclF83bRVFLeGkuAhHiGPMvSGmhgaTzV
# yhYn4p0+8y9oHRaQT/aofEnS5xLrfxnGpTXiUOeSLsJygoLPp66bkDX1ZlAeSpQl
# 92QOMeRxykvq6gbylsXQskBBBnGy3tW/AMOMCZIVNSaz7BX8VtYGqLt9MmeOreGP
# RdtBx3yGOP+rx3rKWDEJlIqLXvJWnY0v5ydPpOjL6s36czwzsucuoKs7Yk/ehb//
# Wx+5kMqIMRvUBDx6z1ev+7psNOdgJMoiwOrUG2ZdSoQbU2rMkpLiQ6bGRinZbI4O
# Lu9BMIFm1UUl9VnePs6BaaeEWvjJSjNm2qA+sdFUeEY0qVjPKOWug/G6X5uAiynM
# 7Bu2ayBjUwIDAQABo4IBXTCCAVkwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHQ4E
# FgQU729TSunkBnx6yuKQVvYv1Ensy04wHwYDVR0jBBgwFoAU7NfjgtJxXWRM3y5n
# P+e6mK4cD08wDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQMMAoGCCsGAQUFBwMIMHcG
# CCsGAQUFBwEBBGswaTAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQu
# Y29tMEEGCCsGAQUFBzAChjVodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGln
# aUNlcnRUcnVzdGVkUm9vdEc0LmNydDBDBgNVHR8EPDA6MDigNqA0hjJodHRwOi8v
# Y3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkUm9vdEc0LmNybDAgBgNV
# HSAEGTAXMAgGBmeBDAEEAjALBglghkgBhv1sBwEwDQYJKoZIhvcNAQELBQADggIB
# ABfO+xaAHP4HPRF2cTC9vgvItTSmf83Qh8WIGjB/T8ObXAZz8OjuhUxjaaFdleMM
# 0lBryPTQM2qEJPe36zwbSI/mS83afsl3YTj+IQhQE7jU/kXjjytJgnn0hvrV6hqW
# Gd3rLAUt6vJy9lMDPjTLxLgXf9r5nWMQwr8Myb9rEVKChHyfpzee5kH0F8HABBgr
# 0UdqirZ7bowe9Vj2AIMD8liyrukZ2iA/wdG2th9y1IsA0QF8dTXqvcnTmpfeQh35
# k5zOCPmSNq1UH410ANVko43+Cdmu4y81hjajV/gxdEkMx1NKU4uHQcKfZxAvBAKq
# MVuqte69M9J6A47OvgRaPs+2ykgcGV00TYr2Lr3ty9qIijanrUR3anzEwlvzZiiy
# fTPjLbnFRsjsYg39OlV8cipDoq7+qNNjqFzeGxcytL5TTLL4ZaoBdqbhOhZ3ZRDU
# phPvSRmMThi0vw9vODRzW6AxnJll38F0cuJG7uEBYTptMSbhdhGQDpOXgpIUsWTj
# d6xpR6oaQf/DJbg3s6KCLPAlZ66RzIg9sC+NJpud/v4+7RWsWCiKi9EOLLHfMR2Z
# yJ/+xhCx9yHbxtl5TPau1j/1MIDpMPx0LckTetiSuEtQvLsNz3Qbp7wGWqbIiOWC
# nb5WqxL3/BAPvIXKUjPSxyZsq8WhbaM2tszWkPZPubdcMIIG7TCCBNWgAwIBAgIQ
# CoDvGEuN8QWC0cR2p5V0aDANBgkqhkiG9w0BAQsFADBpMQswCQYDVQQGEwJVUzEX
# MBUGA1UEChMORGlnaUNlcnQsIEluYy4xQTA/BgNVBAMTOERpZ2lDZXJ0IFRydXN0
# ZWQgRzQgVGltZVN0YW1waW5nIFJTQTQwOTYgU0hBMjU2IDIwMjUgQ0ExMB4XDTI1
# MDYwNDAwMDAwMFoXDTM2MDkwMzIzNTk1OVowYzELMAkGA1UEBhMCVVMxFzAVBgNV
# BAoTDkRpZ2lDZXJ0LCBJbmMuMTswOQYDVQQDEzJEaWdpQ2VydCBTSEEyNTYgUlNB
# NDA5NiBUaW1lc3RhbXAgUmVzcG9uZGVyIDIwMjUgMTCCAiIwDQYJKoZIhvcNAQEB
# BQADggIPADCCAgoCggIBANBGrC0Sxp7Q6q5gVrMrV7pvUf+GcAoB38o3zBlCMGMy
# qJnfFNZx+wvA69HFTBdwbHwBSOeLpvPnZ8ZN+vo8dE2/pPvOx/Vj8TchTySA2R4Q
# KpVD7dvNZh6wW2R6kSu9RJt/4QhguSssp3qome7MrxVyfQO9sMx6ZAWjFDYOzDi8
# SOhPUWlLnh00Cll8pjrUcCV3K3E0zz09ldQ//nBZZREr4h/GI6Dxb2UoyrN0ijtU
# DVHRXdmncOOMA3CoB/iUSROUINDT98oksouTMYFOnHoRh6+86Ltc5zjPKHW5KqCv
# pSduSwhwUmotuQhcg9tw2YD3w6ySSSu+3qU8DD+nigNJFmt6LAHvH3KSuNLoZLc1
# Hf2JNMVL4Q1OpbybpMe46YceNA0LfNsnqcnpJeItK/DhKbPxTTuGoX7wJNdoRORV
# bPR1VVnDuSeHVZlc4seAO+6d2sC26/PQPdP51ho1zBp+xUIZkpSFA8vWdoUoHLWn
# qWU3dCCyFG1roSrgHjSHlq8xymLnjCbSLZ49kPmk8iyyizNDIXj//cOgrY7rlRyT
# laCCfw7aSUROwnu7zER6EaJ+AliL7ojTdS5PWPsWeupWs7NpChUk555K096V1hE0
# yZIXe+giAwW00aHzrDchIc2bQhpp0IoKRR7YufAkprxMiXAJQ1XCmnCfgPf8+3mn
# AgMBAAGjggGVMIIBkTAMBgNVHRMBAf8EAjAAMB0GA1UdDgQWBBTkO/zyMe39/dfz
# kXFjGVBDz2GM6DAfBgNVHSMEGDAWgBTvb1NK6eQGfHrK4pBW9i/USezLTjAOBgNV
# HQ8BAf8EBAMCB4AwFgYDVR0lAQH/BAwwCgYIKwYBBQUHAwgwgZUGCCsGAQUFBwEB
# BIGIMIGFMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wXQYI
# KwYBBQUHMAKGUWh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRy
# dXN0ZWRHNFRpbWVTdGFtcGluZ1JTQTQwOTZTSEEyNTYyMDI1Q0ExLmNydDBfBgNV
# HR8EWDBWMFSgUqBQhk5odHRwOi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRU
# cnVzdGVkRzRUaW1lU3RhbXBpbmdSU0E0MDk2U0hBMjU2MjAyNUNBMS5jcmwwIAYD
# VR0gBBkwFzAIBgZngQwBBAIwCwYJYIZIAYb9bAcBMA0GCSqGSIb3DQEBCwUAA4IC
# AQBlKq3xHCcEua5gQezRCESeY0ByIfjk9iJP2zWLpQq1b4URGnwWBdEZD9gBq9fN
# aNmFj6Eh8/YmRDfxT7C0k8FUFqNh+tshgb4O6Lgjg8K8elC4+oWCqnU/ML9lFfim
# 8/9yJmZSe2F8AQ/UdKFOtj7YMTmqPO9mzskgiC3QYIUP2S3HQvHG1FDu+WUqW4da
# IqToXFE/JQ/EABgfZXLWU0ziTN6R3ygQBHMUBaB5bdrPbF6MRYs03h4obEMnxYOX
# 8VBRKe1uNnzQVTeLni2nHkX/QqvXnNb+YkDFkxUGtMTaiLR9wjxUxu2hECZpqyU1
# d0IbX6Wq8/gVutDojBIFeRlqAcuEVT0cKsb+zJNEsuEB7O7/cuvTQasnM9AWcIQf
# VjnzrvwiCZ85EE8LUkqRhoS3Y50OHgaY7T/lwd6UArb+BOVAkg2oOvol/DJgddJ3
# 5XTxfUlQ+8Hggt8l2Yv7roancJIFcbojBcxlRcGG0LIhp6GvReQGgMgYxQbV1S3C
# rWqZzBt1R9xJgKf47CdxVRd/ndUlQ05oxYy2zRWVFjF7mcr4C34Mj3ocCVccAvlK
# V9jEnstrniLvUxxVZE/rptb7IRE2lskKPIJgbaP5t2nGj/ULLi49xTcBZU8atufk
# +EMF/cWuiC7POGT75qaL6vdCvHlshtjdNXOCIUjsarfNZzGCBS0wggUpAgEBMFEw
# PTEWMBQGA1UECgwNUm9iZXJ0IEZhZGRlczEjMCEGA1UEAwwaRGF0dG9STU0uQ29y
# ZSBDb2RlIFNpZ25pbmcCEHjriJcd8jqCSwSQMNPKs2wwDQYJYIZIAWUDBAIBBQCg
# gYQwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYB
# BAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0B
# CQQxIgQgk/XgHPJpR+4oSMKecDLOgKAwi6zk0QCNqp4RFZWM0nYwDQYJKoZIhvcN
# AQEBBQAEggEAbUbC9eQTaB8ElPEP9lk5Vzg5JtxszTTa/A60urDrpKF4Wx+2gMPV
# gxCsi0IscAc/RSPZtWoFKLrt1FpxD/Gl4JtTsZNAmqBRzqvVVGd6XJXqWdFyZ/b8
# Bt7NRx7VhTx6GpadaQW6bv23Ocww7RdpTNl9HtaFh26MfoQenJfKXue4nSxdmqkW
# OTy/UKFRBDvYuQaoY5yI4rQC8m804qP8yFrp9lIOHHD6EQYJ0vNenL99De8PMII0
# tM7O+BvVdn13VQEH5ix6SWB3POrlLNT9UuxZkrCqhSJt1wErMpXGsnBeVxYadnHA
# 4+kuibacxXc0Wcihkw+L58X8X5Qmpm05yKGCAyYwggMiBgkqhkiG9w0BCQYxggMT
# MIIDDwIBATB9MGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5j
# LjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNB
# NDA5NiBTSEEyNTYgMjAyNSBDQTECEAqA7xhLjfEFgtHEdqeVdGgwDQYJYIZIAWUD
# BAIBBQCgaTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEP
# Fw0yNjAzMzEwMDMwMzdaMC8GCSqGSIb3DQEJBDEiBCAadCCc34NeT6xKFV3POOlg
# UofprhcQH9sSW9dPQ0XeVjANBgkqhkiG9w0BAQEFAASCAgBIa9NHTe3t1CFYEgia
# XP2eEH4xVvkKxI3jK4VBVY11qys7KmwPJcEqG7YYBRP4lhFBhBQCDfJlOGBMa0mw
# xTpvR85SovfMeH1Fc6yR95WJEDxfArXY9SXvJKkdXx6RvR/D276f3iXEmwpzxVUi
# x2d+7JFAF6+sj6B04zCC9jBa6DSwMzP33waGzQ3Qg3Bqjccufs6/2vYdzynjpo0T
# mmeMq6Qls2FLOu/xnRYGl9/LsehzuqmxeAdcnxNJst4uHyQNcfcq2fsiOH8KwPv+
# diD8cJIqZ4r1TkjOvbyWGkId4mPeax7/ResSG0k3LHVXB8GpXYwGv5Jb4JjOvw+F
# iavqruMTRhwRXwJfySqHUTsM1M1SuJuAS8kFqhMbKLIDGkEmcj6LYqKZZqal7hHY
# BcdFCVvT/QKzMHtljq6QcccOFyMPiWIC3RLDwzEVYavre99TTpShLmg/2hAQ55FT
# XqdD40U618O91O4BJHbBto/28bg/uOrxUVZfA8CxpK0rkTebEBw+1MIUEFoc/Cq+
# iKIZpg8Pb6Ghz9zBCLYhg1Jq9vKTcwxjYqySYmRYHclStx6UKoBI5gboYQP4FRy0
# ddM+Uzgnoj8Vp9X2LuJEbNuHprjCyG1CLnQDNUifM6P4cVlsMl791oTiY2Cubu24
# 0C3sFma0dIx6ezmIS2Wd81pI3Q==
# SIG # End signature block
