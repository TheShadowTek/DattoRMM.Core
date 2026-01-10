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
