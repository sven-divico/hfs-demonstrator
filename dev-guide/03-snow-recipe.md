# SNOW Recipe — Scripted REST API implementation

**Audience:** ServiceNow developer ready to write code.
**Prereq:** read [02-developer-onboarding.md](02-developer-onboarding.md) and have the live demo open in another tab.
**Goal:** copy-paste-and-adapt scripts for the four endpoints in [01-api-specification.md §B](01-api-specification.md#b-rest-api).

> **Heads-up — data model has evolved.** The scripts in this recipe target the *original* 2-table model (`wm_order` / `wm_task`). The current model is 3 tables: `wm_customer_order` → `wm_rfs_order` → `wm_task`. Use this recipe to understand the GlideScript patterns (pagination, batched task fetch, drilldown), then apply the table/field renames from [05-data-acquisition-after-customer-order.md §4](05-data-acquisition-after-customer-order.md#4-glidescript-reference--paginated-matrix-on-the-new-model) before pasting into your instance.

This is intentionally *opinionated*: the scripts work as-is for a fresh project, are commented for the parts that vary by instance, and follow ServiceNow conventions (`sysparm_*` parameters, status code helpers, JSON error shapes).

---

## 0. One-time setup

### 0.1 Create the Scripted REST Service

System Web Services → Scripted REST APIs → New.

| Field | Value |
|---|---|
| Name | `HFS Status Matrix` |
| API ID | `hfs_status_matrix` |
| Application scope | your custom scope (e.g. `x_company`) |

The base URL becomes `/api/x_company/hfs_status_matrix`.

### 0.2 Stash the canonical task registry

The 17-task list is the same data the demo serves from `public/task-columns.json`. Create a **System Property** so all four scripts can read it.

System Properties → New.

| Field | Value |
|---|---|
| Name | `x_company.hfs.task_columns_json` |
| Type | `string` |
| Value | (the full JSON below, one line) |

```json
[{"name":"HV-S","short":"HV","label":"Standard House Visit","sequence":1},{"name":"UV-S","short":"UV","label":"Standard Unit Visit","sequence":2},{"name":"HV-NE4","short":"HV4","label":"House Visit NE4","sequence":3},{"name":"UV-NE4","short":"UV4","label":"Unit Visit NE4","sequence":4},{"name":"GIS Planung","short":"GP","label":"GIS Planning - NAS","sequence":5},{"name":"Fremdleitungsplan","short":"LLD","label":"Utility Lines Plan","sequence":6},{"name":"Genehmigungen","short":"PM","label":"Permits (VRAO / Aufbruch)","sequence":7},{"name":"Tiefbau","short":"CV","label":"Civil Works","sequence":8},{"name":"Spleißen","short":"SP","label":"Splicing","sequence":9},{"name":"Einblasen","short":"BF","label":"Blow-in Fiber","sequence":10},{"name":"Gartenbohrung","short":"GD","label":"Garden Drilling","sequence":11},{"name":"Hauseinführung","short":"WB","label":"Wall Breakthrough","sequence":12},{"name":"HÜP","short":"HÜP","label":"Install HÜP","sequence":13},{"name":"Leitungsweg NE4","short":"CW4","label":"Cable Way NE4","sequence":14},{"name":"GFTA","short":"GFTA","label":"Install GFTA","sequence":15},{"name":"ONT","short":"ONT","label":"Install ONT","sequence":16},{"name":"Patch","short":"PCH","label":"Patch","sequence":17}]
```

### 0.3 Create a Script Include for shared helpers

Script Includes → New.

| Field | Value |
|---|---|
| Name | `HFSMatrixUtil` |
| API Name | `x_company.HFSMatrixUtil` |
| Client callable | `false` |
| Application | your scope |

```javascript
var HFSMatrixUtil = Class.create();
HFSMatrixUtil.prototype = {
    initialize: function () {},

    /** Read the canonical 17-task registry. */
    getTaskColumns: function () {
        var raw = gs.getProperty('x_company.hfs.task_columns_json', '[]');
        try { return JSON.parse(raw); }
        catch (e) {
            gs.error('HFSMatrixUtil: task_columns_json is malformed: ' + e);
            return [];
        }
    },

    /** Read & clamp an integer query parameter. */
    clampInt: function (raw, fallback, min, max) {
        var n = parseInt(raw, 10);
        if (isNaN(n)) return fallback;
        return Math.max(min, Math.min(max, n));
    },

    /** Standard error response in the documented shape {error, message}. */
    sendError: function (response, status, code, message) {
        response.setStatus(status);
        response.setBody({ error: code, message: message });
    },

    /** Serialise a wm_order GlideRecord into the JSON row shape. */
    serialiseOrder: function (gr) {
        return {
            sys_id:              gr.getUniqueValue(),
            number:              gr.getValue('number'),
            status_code:         parseInt(gr.getValue('status_code'), 10),
            construction_status: gr.getValue('construction_status'),
            account:             gr.getValue('account'),
            city:                gr.getValue('city'),
            address:             gr.getValue('address'),
            unit_count:          parseInt(gr.getValue('unit_count'), 10) || 0,
            set_name:            gr.getValue('set_name')
        };
    },

    /** Serialise a wm_task GlideRecord into the JSON task shape. */
    serialiseTask: function (gr) {
        return {
            sys_id:            gr.getUniqueValue(),
            number:            gr.getValue('number'),
            work_order:        gr.getValue('work_order'),
            short_description: gr.getValue('short_description'),
            short_code:        gr.getValue('short_code'),
            state:             gr.getValue('state'),
            assignment_group:  gr.getDisplayValue('assignment_group') || null,
            sys_updated_on:    gr.getValue('sys_updated_on')
        };
    },

    type: 'HFSMatrixUtil'
};
```

> **Field name caveat.** This script assumes `wm_order.status_code`, `wm_order.construction_status`, `wm_task.short_code`, `wm_task.state` exist with those exact names. If your instance uses different fields (e.g. `state` as an integer choice list with display values like `"Work In Progress"`), swap `getValue` → `getDisplayValue` accordingly. Verify against `sys_dictionary` first.

---

## 1. Resource: `task-columns`

The trivial one. Build this first to confirm your scaffold works end-to-end.

**Resource path:** `/task-columns`
**HTTP method:** `GET`
**Script:**

```javascript
(function process(request, response) {
    var util = new x_company.HFSMatrixUtil();
    response.setStatus(200);
    response.setBody(util.getTaskColumns());
})(request, response);
```

**Smoke test (REST API Explorer):**
- URL: `/api/x_company/hfs_status_matrix/task-columns`
- Expected: JSON array, 17 entries, first one `{"name":"HV-S","short":"HV",...}`.

If this works, your service + scope + Script Include are wired correctly.

---

## 2. Resource: `matrix` (the pivot)

The centerpiece — the endpoint that replaces the developer's Excel sheet.

**Resource path:** `/work-orders/matrix`
**HTTP method:** `GET`
**Query parameters consumed:** `sysparm_limit`, `sysparm_offset`, `list`

> **Pagination param naming.** Demo uses `limit` / `offset`; SNOW convention is `sysparm_limit` / `sysparm_offset`. The component is parameterised via `data-endpoint` — set it to the SNOW URL and the rest is just query string mechanics. **In SNOW, prefer `sysparm_*`** so other tools (REST API Explorer, scripted clients, the auto-pagination Link header logic) understand your endpoint natively. If you want both names to work, accept either (recipe below).

**Script:**

```javascript
(function process(request, response) {
    var util    = new x_company.HFSMatrixUtil();
    var columns = util.getTaskColumns();
    var qp      = request.queryParams;

    // ---- 1. Read & validate parameters ----------------------------------
    // `list`: filter selector. Allow only documented values.
    var list = String(qp.list || 'legacy');
    if (list !== 'legacy' && list !== 'attention') {
        return util.sendError(response, 400, 'bad_list',
            "Unknown list '" + list + "'. Allowed: legacy, attention.");
    }

    // Pagination — accept both SNOW (`sysparm_*`) and demo (`limit`/`offset`)
    // names; clamp to safe bounds. Default page size 25, max 200.
    var limit  = util.clampInt(qp.sysparm_limit  || qp.limit,  25, 1, 200);
    var offset = util.clampInt(qp.sysparm_offset || qp.offset, 0,  0, 1e9);

    // ---- 2. Build the encoded query for the WO list ---------------------
    // 'attention' = WOs with at least one task in state 'Problem'.
    // We resolve this with a sub-query in two GlideRecord passes since
    // wm_order has no direct field for "has problem task".
    var woQuery;
    if (list === 'attention') {
        var subTask = new GlideRecord('wm_task');
        subTask.addQuery('state', 'Problem');
        subTask.query();
        var attentionIds = [];
        while (subTask.next()) {
            var id = subTask.getValue('work_order');
            if (attentionIds.indexOf(id) === -1) attentionIds.push(id);
        }
        if (attentionIds.length === 0) {
            response.setStatus(200);
            response.setBody({ total: 0, offset: 0, limit: limit, columns: columns, rows: [] });
            return;
        }
        woQuery = 'sys_idIN' + attentionIds.join(',');
    } else {
        woQuery = ''; // legacy = all
    }

    // ---- 3. Count total (for the response's `total` field) --------------
    var counter = new GlideAggregate('wm_order');
    if (woQuery) counter.addEncodedQuery(woQuery);
    counter.addAggregate('COUNT');
    counter.query();
    var total = counter.next() ? parseInt(counter.getAggregate('COUNT'), 10) : 0;

    // ---- 4. Fetch the page of WOs ---------------------------------------
    var woGR = new GlideRecord('wm_order');
    if (woQuery) woGR.addEncodedQuery(woQuery);
    woGR.orderByDesc('number');
    woGR.chooseWindow(offset, offset + limit, true);  // SNOW pagination helper
    woGR.query();

    var rows = [];
    var pageWoIds = [];
    while (woGR.next()) {
        var row = util.serialiseOrder(woGR);
        row.tasks = {};      // filled in below
        rows.push(row);
        pageWoIds.push(row.sys_id);
    }

    // ---- 5. Fetch tasks for the page only & fold into the pivot map ----
    if (pageWoIds.length > 0) {
        var taskGR = new GlideRecord('wm_task');
        taskGR.addEncodedQuery('work_orderIN' + pageWoIds.join(','));
        taskGR.query();

        var tasksByWo = {};
        while (taskGR.next()) {
            var wo   = taskGR.getValue('work_order');
            var name = taskGR.getValue('short_description');  // canonical key
            var st   = taskGR.getValue('state');
            (tasksByWo[wo] = tasksByWo[wo] || {})[name] = st;
        }

        for (var i = 0; i < rows.length; i++) {
            rows[i].tasks = tasksByWo[rows[i].sys_id] || {};
        }
    }

    // ---- 6. Respond -----------------------------------------------------
    response.setStatus(200);
    response.setBody({
        total:   total,
        offset:  offset,
        limit:   limit,
        columns: columns,
        rows:    rows
    });
})(request, response);
```

**Smoke tests (REST API Explorer):**

| Request | Expected |
|---|---|
| `/work-orders/matrix` | `total: <full count>, rows.length === Math.min(25, total)` |
| `/work-orders/matrix?list=attention` | only WOs with at least one Problem task |
| `/work-orders/matrix?sysparm_limit=10&sysparm_offset=10` | page 2 of 10-row pages |
| `/work-orders/matrix?list=bogus` | HTTP 400, body `{error:"bad_list", message:"..."}` |

**Cross-check against the demo.** With the live demo open, hit `https://hfs-demo.biztechbridge.com/api/work-orders/matrix?list=attention&limit=2`. Compare your JSON to the demo's response — field names and types should match exactly. The order of fields and the order of rows don't matter as long as they're internally consistent.

### 2.1 Critical detail — the `tasks` map key

The map keys must be the canonical German task names (`"HV-S"`, `"GIS Planung"`, `"HÜP"`). The component looks up `row.tasks[column.name]` where `column.name` comes from the registry.

**Most common porting bug:** building the map with the wrong key shape. Two ways to introduce the bug:

```javascript
//  WRONG  – key is the display value, e.g. "Standard House Visit"
tasksByWo[wo][taskGR.getDisplayValue('short_description')] = st;

//  WRONG  – key is the short code, e.g. "HV"
tasksByWo[wo][taskGR.getValue('short_code')] = st;

//  RIGHT – key is the canonical German name stored on the wm_task record
tasksByWo[wo][taskGR.getValue('short_description')] = st;
```

If every cell renders as `—` in the UI, this is the bug — verify the network-tab JSON keys match `columns[i].name` literally.

### 2.2 Encoded query alternatives

If your data model has a more elegant way to express "WOs with a Problem task" (e.g. a stored flag, a related list calculation, or a database view), use it instead of the two-pass approach above. The two-pass version is robust on a stock `wm_order` / `wm_task` schema without making assumptions.

---

## 3. Resource: `work-order` (single WO + all tasks)

Used by `<wo-detail-tab>`.

**Resource path:** `/work-orders/{sysId}`
**HTTP method:** `GET`

**Script:**

```javascript
(function process(request, response) {
    var util  = new x_company.HFSMatrixUtil();
    var sysId = request.pathParams.sysId;

    // ---- 1. Validate the sysId format ----------------------------------
    if (!/^ord-\d{7,}$/.test(sysId)) {
        return util.sendError(response, 400, 'bad_sys_id',
            "sysId must look like 'ord-0012867'.");
    }

    // ---- 2. Fetch the WO -----------------------------------------------
    var woGR = new GlideRecord('wm_order');
    if (!woGR.get(sysId)) {
        return util.sendError(response, 404, 'not_found',
            'Work order ' + sysId + ' not found.');
    }
    var out = util.serialiseOrder(woGR);

    // ---- 3. Fetch all tasks for this WO --------------------------------
    var taskGR = new GlideRecord('wm_task');
    taskGR.addQuery('work_order', sysId);
    taskGR.orderBy('short_description');
    taskGR.query();
    var tasks = [];
    while (taskGR.next()) tasks.push(util.serialiseTask(taskGR));
    out.tasks = tasks;

    // ---- 4. Respond ----------------------------------------------------
    response.setStatus(200);
    response.setBody(out);
})(request, response);
```

**Smoke tests:**

| Request | Expected |
|---|---|
| `/work-orders/ord-0012867` | full WO + `tasks.length === 17` |
| `/work-orders/ord-9999999` | HTTP 404 |
| `/work-orders/garbage` | HTTP 400 |

### 3.1 sysId format note

The regex `/^ord-\d{7,}$/` matches our demo seed convention. **Your real `wm_order.sys_id` values won't have the `ord-` prefix** — they'll be 32-char GUIDs. Adjust the regex to `/^[a-f0-9]{32}$/` for production.

If you change the sysId format, also update the component's matrix-row rendering so the `wo:open` event sends the real sys_id (the component currently just passes whatever `sys_id` field the API returns — no change needed there).

---

## 4. Resource: `task` (single WO × task)

Used by `<task-detail-tab>`.

**Resource path:** `/work-orders/{sysId}/tasks/{taskName}`
**HTTP method:** `GET`

**Script:**

```javascript
(function process(request, response) {
    var util  = new x_company.HFSMatrixUtil();
    var sysId    = request.pathParams.sysId;
    var taskName = request.pathParams.taskName;  // SNOW auto-decodes path segments

    // ---- 1. Validate parameters ----------------------------------------
    if (!/^ord-\d{7,}$/.test(sysId)) {                  // see §3.1 for prod regex
        return util.sendError(response, 400, 'bad_sys_id',
            "sysId must look like 'ord-0012867'.");
    }
    if (!taskName) {
        return util.sendError(response, 400, 'bad_task_name', 'taskName is required.');
    }

    // ---- 2. Fetch the task ---------------------------------------------
    var taskGR = new GlideRecord('wm_task');
    taskGR.addQuery('work_order',        sysId);
    taskGR.addQuery('short_description', taskName);   // canonical German name
    taskGR.setLimit(1);
    taskGR.query();
    if (!taskGR.next()) {
        return util.sendError(response, 404, 'not_found',
            "Task '" + taskName + "' not found on " + sysId + '.');
    }

    response.setStatus(200);
    response.setBody(util.serialiseTask(taskGR));
})(request, response);
```

**Smoke tests:**

| Request | Expected |
|---|---|
| `/work-orders/ord-0012867/tasks/HV-S` | task detail JSON |
| `/work-orders/ord-0012865/tasks/H%C3%9CP` | task detail for HÜP (umlaut decoded) |
| `/work-orders/ord-0012867/tasks/NonExistent` | HTTP 404 |

### 4.1 Umlauts & URL encoding

The component sends `encodeURIComponent(taskName)` so `HÜP` becomes `H%C3%9CP` in the URL. ServiceNow's Scripted REST framework auto-decodes `request.pathParams.taskName` once. **Do not call `decodeURIComponent` again** — that would double-decode and corrupt names containing `%`.

If your test client (curl, Postman) doesn't auto-encode, you'll need to encode by hand.

---

## 5. ACLs and security

The components do read-only fetches. The four endpoints need read ACL on:

- `wm_order` (all the row fields used in `serialiseOrder`)
- `wm_task` (all the fields used in `serialiseTask`)

If your instance has row-level ACLs (e.g. "users only see their assignment-group's tasks"), the queries above respect them automatically — `GlideRecord` honours ACLs by default. The `total` count in §2 will reflect what the *current user* can see, which is the correct behaviour.

**If you want the API to ignore ACLs** (e.g. for a dashboard service account that needs unrestricted reads), wrap the GlideRecord calls in a `GlideRecordSecure` toggle or run via a `sys_user` impersonation. **Don't** sprinkle `gr.setWorkflow(false); gr.autoSysFields(false);` — those are for write operations and don't affect read ACLs.

---

## 6. Pagination Link header (optional but nice)

ServiceNow's built-in list APIs return a `Link` header with `rel="next"` / `rel="prev"` so clients can paginate without parsing the response body. To make your matrix endpoint feel native, add this after computing `limit/offset/total`:

```javascript
// At the end of the matrix script, before response.setBody(...):
function buildLink(baseUrl, list, off, lim, rel) {
    return '<' + baseUrl
        + '?list=' + encodeURIComponent(list)
        + '&sysparm_limit='  + lim
        + '&sysparm_offset=' + off
        + '>; rel="' + rel + '"';
}
var links = [];
var base  = '/api/x_company/hfs_status_matrix/work-orders/matrix';
if (offset > 0)             links.push(buildLink(base, list, Math.max(0, offset - limit), limit, 'prev'));
if (offset + limit < total) links.push(buildLink(base, list, offset + limit,             limit, 'next'));
if (links.length)           response.setHeader('Link', links.join(', '));
response.setHeader('X-Total-Count', String(total));
```

The component doesn't read these (it uses the `total` field in the body) but other consumers — and the SNOW REST Explorer — will display them.

---

## 7. Error response shape — recap

Every non-`200` response from all four endpoints returns this exact shape:

```json
{ "error": "<short-code>", "message": "<human-readable>" }
```

Error codes used by the components: nothing specific — they treat any non-`200` as "render the error string from `message`". You're free to invent new error codes; the table below mirrors the demo.

| Status | Code | When |
|---|---|---|
| `400` | `bad_list` | Unknown `list` value |
| `400` | `bad_sys_id` | Malformed `sysId` path param |
| `400` | `bad_task_name` | Missing or empty `taskName` |
| `404` | `not_found` | WO or task with that key does not exist |
| `500` | `internal` | Unhandled exception — set in a top-level try/catch you can add per script |

---

## 8. Top-level try/catch (production hardening)

The scripts above don't wrap themselves in `try { … } catch (e) { … }`. ServiceNow will return a generic 500 with a stack-trace-ish body on uncaught errors. For production, wrap each script's body:

```javascript
(function process(request, response) {
    try {
        // … script body …
    } catch (e) {
        gs.error('HFS Matrix REST error: ' + e + '\nStack: ' + e.stack);
        response.setStatus(500);
        response.setBody({ error: 'internal', message: 'Internal server error.' });
    }
})(request, response);
```

Keep `gs.error()` so SNOW captures the real error in the system log; only the sanitised message goes to the client.

---

## 9. Update Set hygiene

Capture everything in one update set:

1. Scripted REST Service + the four Scripted REST Resources
2. System Property `x_company.hfs.task_columns_json`
3. Script Include `HFSMatrixUtil`
4. Now Experience custom component (carries the four `.js` files)
5. UI Builder page (or page section) that hosts the component

Test the update set in a sub-prod instance against a freshly imported copy of the `wm_order` / `wm_task` data before promoting.

---

## 10. Checklist before declaring done

Cross-reference this checklist with [02-developer-onboarding.md § "What 'done' looks like"](02-developer-onboarding.md#what-done-looks-like):

- [ ] `task-columns` returns the 17-entry registry, matches `name` keys with `wm_task.short_description` values.
- [ ] `matrix` returns `{total, offset, limit, columns, rows}` with the right field types (numbers as numbers).
- [ ] `matrix` `tasks` map is keyed by canonical German `name` — verified by visual inspection of one row vs the live demo's same row.
- [ ] `matrix?list=attention` returns exactly the WOs with a `Problem` task.
- [ ] Pagination works against both `sysparm_*` and `limit`/`offset` (if you support both).
- [ ] `work-order` returns 17 tasks per WO; 404s on unknown sysId.
- [ ] `task` handles `HÜP` (the umlaut) without double-decoding.
- [ ] All four endpoints return the documented error JSON shape on 4xx/5xx.
- [ ] The component renders 25+ rows against the live SNOW data with no console errors.
- [ ] Drill-down → close cycle works end-to-end.

Ship it.
