<#
    Copyright (c) 2025-2026 Robert Faddes
    SPDX-License-Identifier: MPL-2.0
#>

# Maps HTTP method and normalised API path to the operation name used in operationWriteStatus.
# Path templates use {id} as a placeholder for any GUID or numeric identifier.
# Keys are formatted as 'METHOD:path/template' (no leading /v2/ or api/v2/ prefix).
# Values must match the keys returned by the API's operationWriteStatus response.

@{

    # PUT operations (creates and moves)
    'PUT:site' = 'site-create'
    'PUT:site/{id}/variable' = 'site-variable-create'
    'PUT:device/{id}/site/{id}' = 'device-move'
    'PUT:device/{id}/quickjob' = 'device-job-create'
    'PUT:account/variable' = 'account-variable-create'

    # POST operations (updates and actions)
    'POST:site/{id}' = 'site-update'
    'POST:site/{id}/variable/{id}' = 'site-variable-update'
    'POST:site/{id}/settings/proxy' = 'site-proxy-create'
    'POST:device/{id}/warranty' = 'device-warranty-create'
    'POST:device/{id}/udf' = 'device-udf-set'
    'POST:alert/{id}/resolve' = 'alert-resolve'
    'POST:account/variable/{id}' = 'account-variable-update'
    'POST:user/resetApiKeys' = 'user-reset-keys'

    # DELETE operations
    'DELETE:site/{id}/variable/{id}' = 'site-variable-delete'
    'DELETE:site/{id}/settings/proxy' = 'site-proxy-delete'
    'DELETE:account/variable/{id}' = 'account-variable-delete'

}
