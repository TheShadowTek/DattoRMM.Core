# Datto RMM API Feature Requests

This document tracks API limitations and feature requests to discuss with Datto Account Manager.

---

## 1. Security and Access Management

### Token Invalidation Endpoint for Refresh Operations
**API Endpoint:** Authentication infrastructure (suggested: `POST /v2/auth/invalidateToken`)

**Issue:** The API currently does not provide a way to explicitly invalidate a specific token when a refresh operation occurs. This means that when a token is refreshed, the previous token may remain valid until its expiry, increasing the risk window if the old token is compromised or leaked.

**Requested Enhancement:**
- Add an authentication endpoint that allows clients to invalidate a specific token as part of the refresh process.
- Ensure the endpoint is separate from main API resource endpoints and is part of the authentication infrastructure.
- The endpoint should accept the token to be invalidated and immediately revoke its access, regardless of its expiry.

**Business Justification:**
- **Security Best Practice:** Minimizes the risk window by ensuring that only the latest token is valid after a refresh, reducing exposure from token leakage or compromise.
- **Incident Response:** Enables automated workflows to immediately invalidate compromised tokens during a refresh, improving response times and reducing manual intervention.
- **Compliance:** Supports security and compliance requirements for strict token lifecycle management and auditability.


**Suggested Response Schema:**
```json
{
  "invalidatedToken": "string",
  "status": "success|failure",
  "timestamp": "datetime"
}
```

This enhancement would improve API security posture and align Datto RMM with industry standards for token lifecycle management.

---


### API Endpoints for Security Level Membership Management
**API Endpoint:** N/A - Missing endpoints

**Issue:** The API does not provide endpoints to add or remove users, sites, site device groups, device groups, or site groups to/from Security Level memberships. This limits the ability to fully automate user access provisioning, internal role changes, and just-in-time (JIT) access for restricted customer accounts. While configuration of other Security Level settings is best handled in the UI, membership management is a critical automation requirement for MSPs and enterprises.

Currently, Security Level membership changes must be performed manually in the web UI, which is not scalable or suitable for automated workflows.

**Requested Enhancement:**
- Add endpoints to programmatically add or remove:
  - Users to/from Security Level memberships
  - Sites to/from Security Level memberships
  - Site Device Groups to/from Security Level memberships
  - Device Groups to/from Security Level memberships
  - Site Groups to/from Security Level memberships
- Ensure these endpoints support both assignment and removal, enabling full automation of access workflows.
- Maintain UI-based configuration for other Security Level settings (e.g., permissions, policies).

**Business Justification:**
- **Automated Access Provisioning:** Enables automated onboarding, offboarding, and internal role changes without manual UI intervention.
- **JIT Access:** Supports just-in-time access for restricted customer accounts, improving security and compliance.
- **Scalability:** Manual membership management does not scale for organisations with many users, sites, or groups.
- **Consistency:** Reduces human error and ensures consistent application of access policies across the environment.
- **Auditability:** Programmatic changes can be logged and audited, supporting compliance requirements.

- **Delegation and Workflow Integration:** Simple admin tasks (such as access changes) often require senior admin privileges in the UI. API endpoints would allow these tasks to be integrated with internal business approval, change advisory board (CAB), and security workflows, reducing the need for elevated access and improving governance.

**Current Limitation:**
- All Security Level membership changes must be performed manually in the UI, blocking automation and increasing operational overhead.

This enhancement would enable true end-to-end automation for user and resource access management in Datto RMM, while leaving advanced Security Level configuration to the UI as appropriate.

---

### API Keys Should Respect Security Levels
**API Endpoint:** N/A - Platform-wide behavior

**Issue:** API keys are assigned to users, but do not honour user Security Levels. As a result, any user with an API key effectively has full administrative rights for all API operations, regardless of their assigned Security Level in the UI. This creates a significant security risk and limits the ability to safely distribute API access.

**Requested Enhancement:**
- Enforce Security Level restrictions for all API operations performed using user API keys, so that API access is limited to the same permissions and scopes as the user's interactive UI session.

**Business Justification:**
- **Principle of Least Privilege:** Ensures users and automation tools only have access to the resources and operations appropriate for their role.
- **Wider Adoption:** If API keys respected Security Levels, interactive automation tools (such as PowerShell modules) could be safely distributed to management teams and non-admin users.
- **CI/CD Isolation:** Enables secure, isolated automation in CI/CD pipelines by assigning API keys with only the necessary permissions for each workflow.
- **Risk Reduction:** Prevents accidental or malicious use of API keys to perform unauthorised actions across the environment.

**Current Limitation:**
- All users with API keys have full admin rights on API operations, regardless of their Security Level, making it unsafe to broadly distribute API access.

This enhancement would align API access controls with UI-based security, improving both security and operational flexibility.

---

## 2. Site and Group Management

### Delete Site
**API Endpoint:** N/A - Missing endpoint

**Issue:** The API does not provide an endpoint to delete sites. This functionality is available in the Datto RMM UI but cannot be performed programmatically.

**Requested Enhancement:** Add a `DELETE /v2/site/{siteUid}` endpoint to allow programmatic deletion of sites. This would complete the CRUD operations for site management.

---

### Full CRUD Support for Site Groups
**API Endpoint:** N/A - Missing endpoints

**Issue:** The Datto RMM API does not provide endpoints for full management (Create, Read, Update, Delete) of Site Groups, as described in the [Datto RMM Site Groups documentation](https://rmm.datto.com/help/en/Content/3NEWUI/Sites/SiteGroups.htm). Site Groups are essential for Organising sites and managing access, but currently, all Site Group operations must be performed manually through the web UI.

This limitation makes it impossible to fully automate site onboarding or to create, update, or delete Site Groups as part of a workflow. organisations cannot programmatically assign sites to groups, manage group membership, or enforce access policies at scale.

**Requested Enhancement:**
- Add endpoints to support full CRUD operations for Site Groups:
  - `POST /v2/sitegroup` - Create a new Site Group
  - `GET /v2/sitegroup` and `GET /v2/sitegroup/{siteGroupUid}` - List and retrieve Site Groups
  - `PUT /v2/sitegroup/{siteGroupUid}` - Update Site Group details and membership
  - `DELETE /v2/sitegroup/{siteGroupUid}` - Delete a Site Group
- Allow assignment and removal of sites to/from Site Groups via the API
- Ensure all Site Group properties and relationships are available for automation

**Business Justification:**
- **Automated Site Onboarding:** Full Site Group CRUD support is required to automate the entire site onboarding process, including group assignment and access control.
- **Workflow Automation:** Enables organisations to create, update, and delete Site Groups as part of larger provisioning, compliance, or access management workflows.
- **Consistency and Scale:** Manual group management does not scale for MSPs or enterprises managing hundreds of sites. API support ensures consistency and reduces human error.
- **Access Policy Enforcement:** Programmatic group management is essential for enforcing access policies, role-based access control, and compliance requirements.

**Current Limitation:**
Currently, there is no way to automate Site Group creation or management. All operations must be performed manually in the UI, which is a significant blocker for organisations seeking to automate onboarding and access workflows.

This enhancement would bring Site Group management in line with other core objects in the Datto RMM API and enable true end-to-end automation for site provisioning and access control.

---

### "Deleted Devices" (special site handling)

**Issue:** The API returns the "Deleted Devices" site when using the get site endpoint. This is not a normal customer site—it is used internally by Datto RMM to group devices that have been deleted. However, the "Deleted Devices" value is assigned a malformed GUID (not a valid UUID), which can break typed workflows, validation logic, and automation that expect all site GUIDs to be well-formed.

**API Endpoint:** `GET /v2/account/sites` (method: GET)

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

## 3. Job and Automation Management

### Create Full Job Endpoint
**API Endpoint:** N/A - Missing endpoint

**Issue:** The API only supports creating "Quick Jobs" via `PUT /v2/device/{deviceUid}/quickjob`, which are limited in functionality. Full jobs created through the Datto RMM UI support additional configuration options including timeout settings, scheduling, and the ability to add multiple devices to a single job. Quick jobs are restricted to single devices and lack these advanced configuration options.

**Requested Enhancement:** Add a full `Job` creation endpoint (e.g., `POST /v2/job`) that supports:
- Multiple devices in a single job
- Timeout configuration
- Scheduling options
- All other job configuration options available in the UI

Additionally, update `GET /v2/account/jobs/{jobUid}` response to include targeted device information when jobs support multiple devices.

---

### Job Control Operations (Stop, Cancel, Rerun, Delete)
**API Endpoint:** N/A - Missing endpoints

**Issue:** The API provides read-only access to job information (`GET /v2/job/{jobUid}`) but lacks any job control operations. Once a job is created and executing, there is no programmatic way to:
- Stop or cancel a running job
- Rerun a failed or completed job
- Modify job execution

- Delete job history for specific jobs

This creates operational challenges when jobs hang, run longer than expected, or need to be restarted after failures.

**Requested Enhancement:** Add job control endpoints:
- `DELETE /v2/job/{jobUid}` or `POST /v2/job/{jobUid}/cancel` - Cancel/stop an active job
- `POST /v2/job/{jobUid}/rerun` - Rerun a job with the same configuration and variables
- Optional: `POST /v2/job/{jobUid}/timeout` - Set or update job timeout
- `DELETE /v2/job/{jobUid}/history` - Delete job history for a specific job (successful, failed, or completed)

**Business Justification:**

**Platform Load Management at Scale:**
- **Resource Protection**: Jobs that hang or run for extended periods consume agent resources, API connections, and platform capacity. At scale across thousands of devices, stuck jobs create cumulative platform load that degrades performance for all customers. The ability to programmatically identify and stop long-running jobs would significantly reduce unnecessary platform resource consumption.

- **Cost Efficiency**: Extended job execution times increase infrastructure costs for both customers and Datto. Automated job timeout enforcement and cancellation capabilities would improve overall platform efficiency and reduce operational costs at scale.

- **Cascading Failure Prevention**: Hung jobs on one device can trigger monitoring alerts and compound into wider operational issues. Programmatic job control enables automated remediation before issues cascade across the environment.

- **Job History Management in Large Environments:** In large environments, job history can become congested with thousands of successful or completed jobs, making it difficult to audit, search, or manage ongoing operations. The ability to programmatically delete specific job histories (e.g., for successful jobs) would help keep the job log manageable, improve performance, and reduce clutter for both users and automation tools.

**Operational Efficiency:**
- **Automated Incident Response**: When monitoring systems detect jobs running beyond expected thresholds, automated workflows should be able to stop them without manual web portal intervention. This reduces mean time to resolution (MTTR) and prevents resource exhaustion.

- **Bulk Job Management**: organisations deploying components to hundreds of devices need ability to programmatically stop jobs on a subset if issues are detected, rather than waiting for all executions to timeout naturally.

- **Retry Without Reconfiguration**: Failed jobs should be retry completed job without recreating the entire job definition and variable payload. A rerun endpoint maintains job history while enabling quick recovery.

- **Automated Cleanup:** Automated deletion of job history enables organisations to implement retention policies, reduce manual cleanup, and ensure that only relevant job records are retained for compliance or troubleshooting.

**Current Workarounds and Limitations:**
- Jobs must be manually cancelled through the web UI, requiring human intervention even during automated workflows
- Failed jobs require complete recreation via new API calls, losing historical context and requiring duplicate variable preparation
- Long-running jobs must timeout naturally, consuming platform resources until completion
- No programmatic way to implement job timeout policies across the estate

- No way to delete job history except manual UI cleanup, which is not scalable or automated

**Suggested API Design:**
```http
DELETE /v2/job/{jobUid}
POST /v2/job/{jobUid}/cancel
Response: 204 No Content or job status confirmation

POST /v2/job/{jobUid}/rerun
Request Body: { "deviceUids": ["guid1", "guid2"] } (optional - rerun on subset)
Response: New job object(s)

DELETE /v2/job/{jobUid}/history
Response: 204 No Content or confirmation of deletion
```

This enhancement would reduce platform load at scale, improve operational automation capabilities, and align with standard job management patterns in enterprise automation platforms.

---

### Retrieve Historic Job Results (StdOut/StdErr) for Scheduled Jobs
**API Endpoint:** N/A - Missing endpoint

**Issue:** The current API and new UI do not provide a way to retrieve the historic StdOut and StdErr results for specific executions of recurring scheduled jobs. This feature was previously available in the old UI, where users could review and download output for each run of a scheduled job. In the new UI, only the most recent run's output is accessible via the API using `job.uid`, while attempts to retrieve results for previous runs using `job.scheduled_job_uid` return 404 errors. However, the device activity log in the UI does show historic job results and allows downloads, indicating the data is available internally.

This limitation prevents forensic analysis and troubleshooting, as it is not possible to review or compare output from previous executions of a scheduled job over time.

**Requested Enhancement:**
- Add API endpoints to retrieve StdOut and StdErr for all historical executions of a scheduled job, not just the most recent run.
- Allow filtering or listing of all executions for a given scheduled job (by scheduled_job_uid), with access to their individual results.
- Ensure parity with the device activity log in the UI, where historic job results are visible and downloadable.

**Business Justification:**
- **Forensic Analysis:** Reviewing historic job output is essential for identifying changes, regressions, or anomalies in recurring automation tasks.
- **Troubleshooting:** Enables support and engineering teams to diagnose issues by comparing output across multiple job runs.
- **Audit and Compliance:** Retaining and accessing historic job results is important for audit trails and compliance in managed environments.
- **Feature Parity:** Restores functionality that was available in the old UI and is still present in the device activity log, ensuring a consistent experience across UI and API.

**Current Limitation:**
- Only the most recent run of a scheduled job exposes StdOut/StdErr via the API; all previous runs are inaccessible.
- Attempts to retrieve results for previous runs using scheduled_job_uid return 404 errors.
- Manual review and download is possible in the UI device activity log, but not automatable via API.

This enhancement would enable full programmatic access to historic job results, supporting advanced automation, troubleshooting, and compliance workflows.

---
