<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>
function ConvertFrom-SecureStringToPlaintext {
    <#
    .SYNOPSIS
        Converts a SecureString to plaintext using platform-appropriate methods.

    .DESCRIPTION
        This function decrypts a SecureString to plaintext, using the most secure method
        available for the current platform:
        
        - Windows: Uses Marshal::SecureStringToBSTR with immediate ZeroFreeBSTR to minimize
          exposure in managed memory and prevent garbage collector relocation.
        
        - Linux/macOS: Uses PSCredential.GetNetworkCredential() as Marshal BSTR methods
          are not available. Note: plaintext remains in managed memory until garbage collection.

    .PARAMETER SecureString
        The SecureString to convert to plaintext.

    .EXAMPLE
        $plaintext = ConvertFrom-SecureStringToPlaintext -SecureString $MySecureString

    .NOTES
        Security Considerations:
        - Always set the returned plaintext variable to $null when done
        - On Linux/macOS, plaintext persists in managed memory until GC runs
        - For high-security scenarios on non-Windows, consider calling [GC]::Collect() after use
        
        The function uses try/finally to ensure memory is zeroed on Windows even if errors occur.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [SecureString]
        $SecureString
    )
    
    if ($IsWindows -or $PSVersionTable.PSEdition -eq 'Desktop') {
        
        # Windows: Use Marshal for maximum security
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
        
        try {
            
            [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
            
        } finally {
            
            # Always zero memory, even on errors
            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
            
        }
        
    } else {
        
        # Linux/macOS: Use NetworkCredential (best available option)
        # Note: Plaintext remains in managed memory until GC
        $Credential = [PSCredential]::new('dummy', $SecureString)
        $Credential.GetNetworkCredential().Password
        
    }
}
