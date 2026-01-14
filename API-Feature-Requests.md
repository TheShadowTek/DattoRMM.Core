# Datto RMM API Feature Requests

This document tracks API limitations and feature requests to discuss with Datto Account Manager.

## Create Full Job Endpoint
**API Endpoint:** N/A - Missing endpoint

**Issue:** The API only supports creating "Quick Jobs" via `PUT /v2/device/{deviceUid}/quickjob`, which are limited in functionality. Full jobs created through the Datto RMM UI support additional configuration options including timeout settings, scheduling, and the ability to add multiple devices to a single job. Quick jobs are restricted to single devices and lack these advanced configuration options.

**Requested Enhancement:** Add a full `Job` creation endpoint (e.g., `POST /v2/job`) that supports:
- Multiple devices in a single job
- Timeout configuration
- Scheduling options
- All other job configuration options available in the UI

Additionally, update `GET /v2/account/jobs/{jobUid}` response to include targeted device information when jobs support multiple devices.

---

## Delete Site
**API Endpoint:** N/A - Missing endpoint

**Issue:** The API does not provide an endpoint to delete sites. This functionality is available in the Datto RMM UI but cannot be performed programmatically.

**Requested Enhancement:** Add a `DELETE /v2/site/{siteUid}` endpoint to allow programmatic deletion of sites. This would complete the CRUD operations for site management.

---

## Reset API Keys Should Return New Keys
**API Endpoint:** `POST /v2/user/resetApiKeys`

**Issue:** The API resets (regenerates) API keys but does not return the new keys in the response. Users must log in to the Datto RMM web portal to retrieve the newly generated keys, which breaks automated security workflows and creates operational friction during security incidents.

**Requested Enhancement:** Return the new `apiAccessKey` and `apiSecretKey` in the response body when keys are successfully reset.

**Business Justification:**
- **Security Incident Response**: During a credential compromise, every second counts. Requiring manual web portal login to retrieve new keys delays response time and potentially extends the window of vulnerability. Automated incident response workflows should be able to reset keys and immediately update secure vault storage (e.g., Azure Key Vault, HashiCorp Vault, CyberArk) without human intervention.

- **Secret Rotation Automation**: Modern security best practices require periodic API key rotation. Organizations using secret management platforms need programmatic access to rotated credentials to automatically update their vaults. Manual key retrieval breaks these automated security workflows and increases operational overhead.

- **Reduced Human Error**: Manual key retrieval and entry introduces risk of transcription errors, clipboard exposure, and accidental key disclosure. API-returned keys can be piped directly to secure storage without human handling.

- **Audit Trail Completeness**: Automated workflows can immediately log new key metadata (creation time, rotation reason) to SIEM/audit systems. Manual processes create gaps in audit trails.

- **Business Continuity**: Organizations with 24/7 operations need to rotate keys outside business hours without requiring staff to access web portals. Programmatic key retrieval enables truly automated security operations.

**Suggested Response Schema:**
```json
{
  "apiAccessKey": "string",
  "apiSecretKey": "string", 
  "userName": "string",
  "resetTimestamp": "datetime"
}
```

This enhancement would align Datto RMM with industry best practices from AWS, Azure, and other enterprise platforms that support programmatic credential rotation.

---


## "Deleted Devices"

**Issue:** The API returns the "Deleted Devices" site when using the get site endpoint. This is not a normal customer site—it is used internally by Datto RMM to group devices that have been deleted. However, the "Deleted Devices" value is assigned a malformed GUID (not a valid UUID), which can break typed workflows, validation logic, and automation that expect all site GUIDs to be well-formed.

**API Endpoint:** `GET /v2/site` (method: GET)

**Impact:**
- Typed PowerShell and API workflows may fail or require special handling to exclude this site.
- Automation and reporting tools that iterate over all sites may encounter errors or unexpected behavior when processing the malformed GUID.
- The presence of this system site in results can cause confusion for users and developers who expect only valid, customer-created sites.

**Requested Enhancement:**
- Add a parameter to the get site endpoint (e.g., `excludeSystemSites` or `excludeDeletedDevicesSite`) that allows callers to exclude the "Deleted Devices" system site from the response.
- Alternatively, ensure the GUID for this site is well-formed and clearly documented as a system-reserved value.

**Business Justification:**
- Improves reliability and predictability of automation and reporting workflows.
- Reduces the need for custom filtering logic in every client implementation.
- Prevents errors and confusion for users and integrators.

This change would maintain backwards compatibility while allowing integrators to opt out of receiving the special "Deleted Devices" site in their results.

---

## Job Control Operations (Stop, Cancel, Rerun)
**API Endpoint:** N/A - Missing endpoints

**Issue:** The API provides read-only access to job information (`GET /v2/job/{jobUid}`) but lacks any job control operations. Once a job is created and executing, there is no programmatic way to:
- Stop or cancel a running job
- Rerun a failed or completed job
- Modify job execution

This creates operational challenges when jobs hang, run longer than expected, or need to be restarted after failures.

**Requested Enhancement:** Add job control endpoints:
- `DELETE /v2/job/{jobUid}` or `POST /v2/job/{jobUid}/cancel` - Cancel/stop an active job
- `POST /v2/job/{jobUid}/rerun` - Rerun a job with the same configuration and variables
- Optional: `POST /v2/job/{jobUid}/timeout` - Set or update job timeout

**Business Justification:**

**Platform Load Management at Scale:**
- **Resource Protection**: Jobs that hang or run for extended periods consume agent resources, API connections, and platform capacity. At scale across thousands of devices, stuck jobs create cumulative platform load that degrades performance for all customers. The ability to programmatically identify and stop long-running jobs would significantly reduce unnecessary platform resource consumption.

- **Cost Efficiency**: Extended job execution times increase infrastructure costs for both customers and Datto. Automated job timeout enforcement and cancellation capabilities would improve overall platform efficiency and reduce operational costs at scale.

- **Cascading Failure Prevention**: Hung jobs on one device can trigger monitoring alerts and compound into wider operational issues. Programmatic job control enables automated remediation before issues cascade across the environment.

**Operational Efficiency:**
- **Automated Incident Response**: When monitoring systems detect jobs running beyond expected thresholds, automated workflows should be able to stop them without manual web portal intervention. This reduces mean time to resolution (MTTR) and prevents resource exhaustion.

- **Bulk Job Management**: Organizations deploying components to hundreds of devices need ability to programmatically stop jobs on a subset if issues are detected, rather than waiting for all executions to timeout naturally.

- **Retry Without Reconfiguration**: Failed jobs should be retryable without recreating the entire job definition and variable payload. A rerun endpoint maintains job history while enabling quick recovery.

**Current Workarounds and Limitations:**
- Jobs must be manually cancelled through the web UI, requiring human intervention even during automated workflows
- Failed jobs require complete recreation via new API calls, losing historical context and requiring duplicate variable preparation
- Long-running jobs must timeout naturally, consuming platform resources until completion
- No programmatic way to implement job timeout policies across the estate

**Suggested API Design:**
```http
DELETE /v2/job/{jobUid}
POST /v2/job/{jobUid}/cancel
Response: 204 No Content or job status confirmation

POST /v2/job/{jobUid}/rerun
Request Body: { "deviceUids": ["guid1", "guid2"] } (optional - rerun on subset)
Response: New job object(s)
```

This enhancement would reduce platform load at scale, improve operational automation capabilities, and align with standard job management patterns in enterprise automation platforms.

---
