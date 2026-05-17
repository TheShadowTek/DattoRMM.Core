<#
    PII-Safe Output Pack — Export Transforms
    DattoRMM.Core user-defined ExportTransforms.psd1

    Overrides the built-in Default export transform for DRMMUser and DRMMDevice
    so that PII-bearing fields are replaced by their masked equivalents in all
    CSV output from Export-RMMObjectCsv.

    IMPORTANT: This file depends on DattoRMM.Core.PII-Safe.Types.ps1xml being
    installed in the same profile folder. The masked ScriptProperty members
    (MaskedEmail, MaskedLastLoggedInUser, MaskedUdf5, etc.) must exist on the
    objects before the export transform can reference them via Path.

    Installation:
        Copy to: $HOME\.DattoRMM.Core\ExportTransforms.psd1
        The module merges this file with the built-in transforms on import.
        Entries with the same class/transform name override the built-in version.

    Customisation — UDF masking:
        To mask a different UDF, add an entry using the ScriptProperty name you
        defined in DattoRMM.Core.PII-Safe.Types.ps1xml:

            @{Name = 'Udf12'; Path = 'MaskedUdf12'}

        To include a UDF in raw (unmasked) form without the -Udf parameter:

            @{Name = 'Udf1'; Path = 'Udfs.Udf1'}

        Note: the built-in -IncludeUdf and -Udf parameters on Export-RMMObjectCsv
        always write raw values and bypass this transform entirely. Use the
        Path-based approach shown here when you need masked UDFs in CSV output.

    See README.md in this folder for full usage guidance.
#>

@{

    # ─────────────────────────────────────────────────────────────────────────
    # DRMMUser — PII-Safe Default
    #
    # Replaces the built-in Default transform. All five identity fields are
    # routed through their masked ScriptProperty equivalents. Non-PII fields
    # (Status, Disabled, Created, LastAccess) are unchanged.
    # ─────────────────────────────────────────────────────────────────────────
    'DRMMUser' = @{

        'Default' = @(
            @{Name = 'Username';  Path = 'MaskedUsername'}
            @{Name = 'FirstName'; Path = 'MaskedFirstName'}
            @{Name = 'LastName';  Path = 'MaskedLastName'}
            @{Name = 'Email';     Path = 'MaskedEmail'}
            @{Name = 'Telephone'; Path = 'MaskedTelephone'}
            'Status'
            'Disabled'
            'Created'
            'LastAccess'
        )
    }

    # ─────────────────────────────────────────────────────────────────────────
    # DRMMDevice — PII-Safe Default
    #
    # Replaces the built-in Default transform. LastLoggedInUser is routed
    # through MaskedLastLoggedInUser. All other columns are identical to the
    # built-in Default.
    #
    # UDF masking example:
    #   Udf5 is included via the MaskedUdf5 ScriptProperty, demonstrating the
    #   pattern for any UDF that stores PII in your environment.
    #
    #   To mask a different UDF:
    #     1. Define MaskedUdf<N> in DattoRMM.Core.PII-Safe.Types.ps1xml
    #     2. Add the entry here: @{Name = 'Udf<N>'; Path = 'MaskedUdf<N>'}
    #
    #   To include an additional unmasked UDF alongside:
    #     @{Name = 'Udf1'; Path = 'Udfs.Udf1'}
    # ─────────────────────────────────────────────────────────────────────────
    'DRMMDevice' = @{

        'Default' = @(
            'Id'
            'Uid'
            'SiteId'
            'SiteName'
            'Hostname'
            @{Name = 'DeviceCategory'; Path = 'DeviceType.Category'}
            @{Name = 'DeviceTypeName'; Path = 'DeviceType.Type'}
            'IntIpAddress'
            'ExtIpAddress'
            'OperatingSystem'
            'Domain'

            # LastLoggedInUser — masked. Remove and replace with the plain string
            # 'LastLoggedInUser' to restore raw output for this column.
            @{Name = 'LastLoggedInUser'; Path = 'MaskedLastLoggedInUser'}

            'Online'
            'LastSeen'
            'RebootRequired'
            'Suspended'
            'Deleted'
            'WarrantyDate'
            @{Name = 'AntivirusProduct'; Path = 'Antivirus.AntivirusProduct'}
            @{Name = 'AntivirusStatus';  Path = 'Antivirus.AntivirusStatus'}
            @{Name = 'PatchStatus';      Path = 'PatchManagement.PatchStatus'}
            'PortalUrl'

            # ── UDF masking ───────────────────────────────────────────────────
            # Udf5 is masked via the ScriptProperty defined in Types.ps1xml.
            # The column name in the CSV is 'Udf5' — indistinguishable from a
            # raw UDF column by downstream consumers, but the value is masked.
            #
            # Pattern for any other PII-bearing UDF:
            #   @{Name = 'Udf12'; Path = 'MaskedUdf12'}
            #
            # Pattern for a raw (unmasked) UDF alongside:
            #   @{Name = 'Udf1'; Path = 'Udfs.Udf1'}
            # ─────────────────────────────────────────────────────────────────
            @{Name = 'Udf5'; Path = 'MaskedUdf5'}
        )
    }
}
