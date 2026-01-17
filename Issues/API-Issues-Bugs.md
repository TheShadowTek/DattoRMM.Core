# Datto RMM API Issues and Bugs

This document tracks known issues and bugs with the Datto RMM API.

---

### Unnecessary nextPageUrl in Activity Log API Response
**API Endpoint:** `GET /v2/activity-logs`

**Issue:**
When retrieving the first page of results from the Activity Log API endpoint, if the number of results is less than the defined page maximum, the response still includes a `nextPageUrl` property. However, following this URL returns an empty set of objects. This is misleading and can cause unnecessary additional requests or confusion in automated workflows.

**Expected Behavior:**
The `nextPageUrl` property should only be present if there are additional results to retrieve. If the first (or any) page is the last page, `nextPageUrl` should be omitted or set to null.

**Impact:**
- Causes unnecessary API calls in paginated automation.
- Can lead to confusion or error handling logic for empty pages.
- Wastes API rate limit quota.

**Example Response:**
```json
{
  "activities": [ ... ],
  "nextPageUrl": "https://api.datto.com/v2/activity-logs?page=2"
}
```

**But page 2 returns:**
```json
{
  "activities": []
}
```

**Requested Fix:**
Only include `nextPageUrl` if there are more results to fetch. If the current page is the last, omit the property or set it to null.

---

### Alert Context `srvc_resource_usage_ctx` Webhook Missing Title/Description

**Type:** UI/Webhook Bug (not strictly API)

**Issue:**
Alerts with the context `srvc_resource_usage_ctx` (service resource usage) generated via webhook show empty `title` and `description` fields in the webhook payload:

```
WEBHOOK_EXECUTED: {
    "title": "",
    "description": "",
    "priority": "SERVICE",
    "category": "CPU",
    ...
}
```

This is also apparent in the Datto RMM UI, where the alert is missing a title and cannot be accessed via the alerts page. Direct URL navigation to the alert page using the `alertUid` works, but the alert remains visibly missing in the webhook response action.

**Impact:**
- Alerts with this context are not visible or accessible in the UI alerts page.
- Webhook payloads lack key information (`title`, `description`), making automation and notification difficult.
- Can only access the alert by direct URL walk with the `alertUid`.

**Evidence:**
- See screenshots:  
  - `[path/to/screenshot1.png]`  
  - `[path/to/screenshot2.png]`  
  *(Replace with actual file paths after upload/rename)*

**Requested Fix:**
Ensure alerts with `srvc_resource_usage_ctx` context populate `title` and `description` fields in both webhook payloads and the UI, so they are visible and accessible like other alert types.

---

