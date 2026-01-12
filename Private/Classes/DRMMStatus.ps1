using module '.\DRMMObject.psm1'

class DRMMStatus : DRMMObject {

    [string]$Version
    [string]$Status
    [Nullable[datetime]]$Started

    DRMMStatus() : base() {

    }

    static [DRMMStatus] FromAPIMethod([pscustomobject]$Response) {

        if ($null -eq $Response) {
            
            return $null
        
        }

        $Result = [DRMMStatus]::new()
        $Result.Version = [DRMMObject]::GetValue($Response, 'version')
        $Result.Status = [DRMMObject]::GetValue($Response, 'status')
        
        $StartedValue = [DRMMObject]::GetValue($Response, 'started')

        if ($null -ne $StartedValue) {
            
            try {

                $Result.Started = [datetime]::Parse($StartedValue)

            } catch {

                $Result.Started = $null

            }
        }

        return $Result

    }
}
