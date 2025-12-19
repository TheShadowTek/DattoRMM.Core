function Get-RMMVariable {
    [CmdletBinding(DefaultParameterSetName = 'Site')]

    param (
        [Parameter(
            ParameterSetName = 'Site',
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [DRMMSite]
        $Site,

        [Parameter(
            ParameterSetName = 'Uid',
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('SiteUid')]
        [guid]
        $Uid,

        [Parameter(
            Mandatory = $false
        )]
        [RMMScope]
        $Scope = [RMMScope]::Global
    )
    
    begin {
        
    }
    
    process {
        
    }
    
    end {
        
    }
}