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
