function Get-RMMNetMapping {
    [CmdletBinding()]
    param ()

    process {

        Write-Debug "Getting RMM Datto Networking site mappings"

        $APIMethod = @{
            Path = 'account/dnet-site-mappings'
            Method = 'Get'
            Paginate = $true
            PageElement = 'dnetSiteMappings'
        }

        Invoke-APIMethod @APIMethod | Where-Object {try {[void][guid]$_.uid; $true} catch {$false}} | ForEach-Object {

            [DRMMNetMapping]::FromAPIMethod($_)

        }

    }
}
