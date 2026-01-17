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

(Add additional issues below using the same format.)
