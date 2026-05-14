# HFS Demonstrator — SNOW Developer Handover

This document covers everything the ServiceNow developer needs to port the four custom elements into a Now Experience component and replace the demo backend with Scripted REST APIs.

**Spec:** [`docs/superpowers/specs/2026-05-14-hfs-demonstrator-design.md`](docs/superpowers/specs/2026-05-14-hfs-demonstrator-design.md)

---

## 1. Custom-element contracts

All four elements are plain-JavaScript Web Components (no framework dependency). They communicate exclusively via `CustomEvent`s dispatched on `document` with `{ bubbles: true, composed: true }` so events cross shadow-DOM boundaries.

### `<wo-status-matrix>`

| Item | Value |
|------|-------|
| **File** | `public/components/wo-status-matrix.js` |
| **Registered tag** | `wo-status-matrix` |
| **Purpose** | Fetches the pivoted matrix endpoint and renders a sticky-header, sticky-first-column table with colour-coded task-state dots |

**Attributes (observed):**

| Attribute | Type | Default | Behaviour |
|-----------|------|---------|-----------|
| `data-endpoint` | string | `/api/work-orders/matrix` | URL prefix; query param `?list=` is appended |
| `data-list` | `"legacy"` \| `"attention"` | `"legacy"` | Observed — changing it triggers a re-fetch and re-render |

**Events emitted (dispatched on `document`):**

| Event | Detail shape | When |
|-------|-------------|------|
| `wo:open` | `{ woId: string, woNumber: string }` | User clicks an ORDER number cell |
| `task:open` | `{ woId: string, woNumber: string, taskName: string }` | User clicks a status dot (`taskName` is the canonical German name, e.g. `"HV-S"`) |

**Events listened to:** none.

**Internal fetch URLs:**
- `GET ${data-endpoint}?list=${data-list}` — on connect and on every `data-list` attribute change

---

### `<wo-detail-tab>`

| Item | Value |
|------|-------|
| **File** | `public/components/wo-detail-tab.js` |
| **Registered tag** | `wo-detail-tab` |
| **Purpose** | WO detail pane: header card (account, address, construction status, set name) + task list table; clicking a task row opens a task-detail tab |

**Attributes (not observed — set once by `<tab-strip>` before DOM insertion):**

| Attribute | Type | Description |
|-----------|------|-------------|
| `data-wo-id` | string | `sys_id` of the work order (e.g. `"ord-0012867"`) |
| `data-wo-number` | string | Human-readable WO number (e.g. `"ORD0012867"`) — used for tab label and task-open event |
| `data-tab-pane` | string | Tab identifier (e.g. `"wo-ord-0012867"`) — echoed back in `tab:close` |

**Events emitted (dispatched on `document`):**

| Event | Detail shape | When |
|-------|-------------|------|
| `task:open` | `{ woId: string, woNumber: string, taskName: string }` | User clicks a task row |
| `tab:close` | `{ tabId: string }` | User clicks the × close button |

**Events listened to:** none.

**Internal fetch URLs:**
- `GET /api/work-orders/${woId}` — on connect; `woId` is URL-encoded

---

### `<task-detail-tab>`

| Item | Value |
|------|-------|
| **File** | `public/components/task-detail-tab.js` |
| **Registered tag** | `task-detail-tab` |
| **Purpose** | Single-task detail pane: header (task name + WO number), state with colour dot, task number, assignment group, last updated |

**Attributes (not observed — set once by `<tab-strip>` before DOM insertion):**

| Attribute | Type | Description |
|-----------|------|-------------|
| `data-wo-id` | string | `sys_id` of the parent work order |
| `data-wo-number` | string | Human-readable WO number — shown in subtitle |
| `data-task-name` | string | Canonical German task name (e.g. `"Genehmigungen"`, `"HÜP"`) — URL-encoded in the fetch |
| `data-tab-pane` | string | Tab identifier — echoed in `tab:close` |

**Events emitted (dispatched on `document`):**

| Event | Detail shape | When |
|-------|-------------|------|
| `tab:close` | `{ tabId: string }` | User clicks the × close button |

**Events listened to:** none.

**Internal fetch URLs:**
- `GET /api/work-orders/${woId}/tasks/${encodeURIComponent(taskName)}` — on connect

---

### `<tab-strip>`

| Item | Value |
|------|-------|
| **File** | `public/components/tab-strip.js` |
| **Registered tag** | `tab-strip` |
| **Purpose** | Workspace tab bar. Manages tab buttons (slotted into light DOM) and pairs them with pane elements inserted into `.content` |

**Attributes:** none.

**Events emitted:** none directly — it relays pane creation which may cause downstream events.

**Events listened to (on `document`):**

| Event | Detail | What the element does |
|-------|--------|-----------------------|
| `wo:open` | `{ woId, woNumber }` | Creates or activates a `<wo-detail-tab>` pane + tab button |
| `task:open` | `{ woId, woNumber, taskName }` | Creates or activates a `<task-detail-tab>` pane + tab button |
| `tab:close` | `{ tabId }` | Removes the matching button + pane; activates `"matrix"` tab as fallback |

The `"matrix"` tab (initial tab rendered in `index.html`) is permanent — `tab:close` with `tabId === "matrix"` is a no-op.

---

## 2. API contract

The following endpoints are what your ServiceNow Scripted REST APIs must return. Field names mirror the `wm_order` / `wm_task` tables.

### `GET /api/task-columns`

Returns the ordered column registry. Mirror of `public/task-columns.json`. The SNOW equivalent is a static resource or System Property.

```json
[
  { "name": "HV-S",             "short": "HV",   "label": "Standard House Visit",        "sequence": 1  },
  { "name": "UV-S",             "short": "UV",   "label": "Standard Unit Visit",         "sequence": 2  },
  { "name": "HV-NE4",          "short": "HV4",  "label": "House Visit NE4",             "sequence": 3  },
  { "name": "UV-NE4",          "short": "UV4",  "label": "Unit Visit NE4",              "sequence": 4  },
  { "name": "GIS Planung",     "short": "GP",   "label": "GIS Planning - NAS",          "sequence": 5  },
  { "name": "Fremdleitungsplan","short": "LLD",  "label": "Utility Lines Plan",          "sequence": 6  },
  { "name": "Genehmigungen",   "short": "PM",   "label": "Permits (VRAO / Aufbruch)",   "sequence": 7  },
  { "name": "Tiefbau",         "short": "CV",   "label": "Civil Works",                 "sequence": 8  },
  { "name": "Spleißen",        "short": "SP",   "label": "Splicing",                    "sequence": 9  },
  { "name": "Einblasen",       "short": "BF",   "label": "Blow-in Fiber",               "sequence": 10 },
  { "name": "Gartenbohrung",   "short": "GD",   "label": "Garden Drilling",             "sequence": 11 },
  { "name": "Hauseinführung",  "short": "WB",   "label": "Wall Breakthrough",           "sequence": 12 },
  { "name": "HÜP",             "short": "HÜP",  "label": "Install HÜP",                "sequence": 13 },
  { "name": "Leitungsweg NE4", "short": "CW4",  "label": "Cable Way NE4",              "sequence": 14 },
  { "name": "GFTA",            "short": "GFTA", "label": "Install GFTA",               "sequence": 15 },
  { "name": "ONT",             "short": "ONT",  "label": "Install ONT",                "sequence": 16 },
  { "name": "Patch",           "short": "PCH",  "label": "Patch",                      "sequence": 17 }
]
```

---

### `GET /api/work-orders/matrix?list=legacy|attention`

The matrix endpoint. Pre-pivoted server-side — the frontend never does row→column math.

**Query parameters:**

| Param | Values | Default |
|-------|--------|---------|
| `list` | `"legacy"` (all WOs) \| `"attention"` (WOs with ≥ 1 `Problem` task) | `"legacy"` |
| `limit` | integer, 1–200 (clamped) | `25` |
| `offset` | integer ≥ 0 | `0` |

**SNOW mapping:** these map 1:1 to `sysparm_limit` / `sysparm_offset` on a Scripted REST list resource. The `total` field in the response gives the row count for the current `list` filter (not affected by limit/offset); use it to drive Prev/Next button enabled-state and the "X–Y of Z" label.

**Response shape:**

```json
{
  "total":  25,
  "offset": 0,
  "limit":  25,
  "columns": [ /* same array as /api/task-columns */ ],
  "rows": [
    {
      "sys_id":              "ord-0012867",
      "number":             "ORD0012867",
      "status_code":        100,
      "construction_status": "Completed",
      "account":            "Test1 Customer",
      "city":               "Borken",
      "address":            "Willbecke 12",
      "unit_count":         1,
      "set_name":           "SDU-GFTAL-NE4",
      "tasks": {
        "HV-S":             "Done",
        "UV-S":             "not applicable",
        "GIS Planung":      "Done",
        "Genehmigungen":    "Done"
        // ... one entry per canonical task name
      }
    }
  ]
}
```

> **Critical:** The keys in the `tasks` map are the canonical **German `name`** field (e.g. `"HV-S"`, `"GIS Planung"`, `"HÜP"`) — NOT the `short` code (`"HV"`, `"GP"`) or the English `label`. See §5 Lookup-key reminder.

**Error responses** (JSON `{ "error": "<code>", "message": "<human>" }`):

| Status | When |
|--------|------|
| 400 | `list` is not `"legacy"` or `"attention"` |
| 500 | Internal server error |

---

### `GET /api/work-orders/:sysId`

WO header + nested task list, consumed by `<wo-detail-tab>`.

**Path parameter:** `:sysId` — the `sys_id` value (e.g. `ord-0012867`).

**Response shape:**

```json
{
  "sys_id":              "ord-0012867",
  "number":             "ORD0012867",
  "status_code":        100,
  "construction_status": "Completed",
  "account":            "Test1 Customer",
  "city":               "Borken",
  "address":            "Willbecke 12",
  "unit_count":         1,
  "set_name":           "SDU-GFTAL-NE4",
  "tasks": [
    {
      "sys_id":           "wot-0050001",
      "number":           "WOT0050001",
      "work_order":       "ord-0012867",
      "short_description": "HV-S",
      "short_code":       "HV",
      "state":            "Done",
      "assignment_group": "HFS Field Team",
      "sys_updated_on":   "2026-04-30T10:22:00Z"
    }
  ]
}
```

**Error responses:**

| Status | When |
|--------|------|
| 400 | Malformed `:sysId` |
| 404 | Unknown `:sysId` |
| 500 | Internal server error |

---

### `GET /api/work-orders/:sysId/tasks/:taskName`

Single task detail, consumed by `<task-detail-tab>`.

**Path parameters:**
- `:sysId` — `sys_id` of the parent WO
- `:taskName` — canonical German `short_description` value, URL-encoded (e.g. `H%C3%9CP` for `HÜP`)

**Response shape:**

```json
{
  "sys_id":           "wot-0050001",
  "number":           "WOT0050001",
  "work_order":       "ord-0012867",
  "short_description": "HV-S",
  "short_code":       "HV",
  "state":            "Done",
  "assignment_group": "HFS Field Team",
  "sys_updated_on":   "2026-04-30T10:22:00Z"
}
```

**Error responses:**

| Status | When |
|--------|------|
| 400 | Malformed `:sysId` |
| 404 | Unknown `:sysId` or task name not found on that WO |
| 500 | Internal server error |

---

## 3. Portability matrix

| Demo file | SNOW equivalent | Notes |
|-----------|-----------------|-------|
| `public/components/wo-status-matrix.js` | Now Experience custom element (view + controller) | Port the class body; replace `fetch()` calls with `GlideRecord` or Scripted REST calls via the Now Experience data broker |
| `public/components/wo-detail-tab.js` | Now Experience custom element (view + controller) | Same pattern |
| `public/components/task-detail-tab.js` | Now Experience custom element (view + controller) | Same pattern |
| `public/components/tab-strip.js` | Now Experience component with tab management | `CustomEvent` dispatch pattern works inside Now Experience; verify shadow-DOM event propagation rules in the platform version |
| `public/app.css` | Styles block in your Now Experience component | Replace `--hfs-*` tokens with `--now-*` Polaris tokens (see §4 below) |
| `public/task-columns.json` | SNOW static resource **or** System Property (`x_hfs_task_columns`) | If using System Property, return it from a Scripted REST endpoint so the client code doesn't change |
| `public/index.html` | Now Experience workspace page | Shell layout rebuilt in the platform; custom elements registered as Now Experience components |
| `server/index.ts`, `server/routes/*.ts` | Scripted REST APIs (`/api/x_hfs/work-orders/...`) | See §2 for required JSON shapes |
| `db/schema.sql`, `db/seed.sql` | Demo-only — replaced by real `wm_order`/`wm_task` table data | The Scripted REST layer queries these tables directly |

---

## 4. CSS token mapping table

| Demo token (`--hfs-*`) | Polaris token (`--now-*`) | Fallback value | Notes |
|------------------------|--------------------------|----------------|-------|
| `--hfs-color-primary` | `--now-color-primary` | `#1f8476` | Teal action colour |
| `--hfs-color-text` | `--now-color-text` | `#1b2734` | Default body text |
| `--hfs-color-text-muted` | `--now-color-text-secondary` | `#5b6770` | Labels, metadata |
| `--hfs-color-bg` | `--now-color-surface-secondary` | `#f4f5f7` | Table header background |
| `--hfs-color-surface` | `--now-color-surface` | `#ffffff` | Card / pane background |
| `--hfs-color-border` | `--now-color-border` | `#d8dde3` | Table grid lines, card borders |
| `--hfs-status-open` | `--now-color-neutral-6` | `#9aa5b1` | Gray ring for Draft state |
| `--hfs-status-pending` | `--now-color-notice` | `#f59e0b` | Amber — Pending Dispatch / Assigned |
| `--hfs-status-scheduled` | `--now-color-information` | `#3b82f6` | Blue — Scheduled / Work In Progress |
| `--hfs-status-done` | `--now-color-positive` | `#10b981` | Green — Done |
| `--hfs-status-problem` | `--now-color-critical` | `#dc2626` | Red — Problem / Fallout |
| `--hfs-font` | `--now-font-family` | `system-ui, sans-serif` | Body font stack |
| `--hfs-space-md` | `--now-space-4` | `16px` | Standard padding / gap |

> The SNOW developer should verify exact Polaris token names against the platform version in use — token names may vary across Now Experience releases.

---

## 5. Lookup-key reminder

> **This is the single most common integration mistake. Read carefully.**

The `tasks` map returned by `GET /api/work-orders/matrix` (and consumed by `<wo-status-matrix>`) is keyed by the **canonical German task `name`** field from `task-columns.json`.

Examples:

| Correct key | Wrong (short code) | Wrong (English label) |
|-------------|-------------------|-----------------------|
| `"HV-S"` | `"HV"` | `"Standard House Visit"` |
| `"GIS Planung"` | `"GP"` | `"GIS Planning - NAS"` |
| `"HÜP"` | `"HÜP"` | `"Install HÜP"` |
| `"Genehmigungen"` | `"PM"` | `"Permits (VRAO / Aufbruch)"` |
| `"Tiefbau"` | `"CV"` | `"Civil Works"` |

The component looks up `row.tasks[col.name]` where `col.name` comes from `task-columns.json`. If your Scripted REST API returns keys using `short` or `label`, every cell will render as `—` (not applicable) because the lookup will miss.

---

## 6. Known gaps

### From spec §4 Out-of-Scope list

- **No write-back of any kind** — edits, state transitions, and comments are out of scope for this demonstrator
- **No real authentication or user-specific lists** — basic auth is a demo gate only; real SNOW uses session-based auth
- **No smart "Needs Attention" filtering** — the `attention` list is strictly "any WO with a task in state `Problem`"; a production rule would incorporate SLA breach, escalation flags, etc.
- **No pagination** — 25 rows fits on screen; the matrix endpoint returns all rows; revisit if the row count grows beyond ~100
- **No mobile / narrow-viewport layout** — the sticky-column table assumes a wide viewport; no responsive breakpoints

### Added by Chunk 5 implementation

- **Matrix dot tooltips show state only, not timestamp** — the `tasks` map in the matrix response is `{ canonical-name: state-string }` (a flat string→string map). Richer tooltips showing `sys_updated_on` would require either (a) a shape change to `{ canonical-name: { state, updated_on } }` or (b) per-task hover fetches to `/api/work-orders/:sysId/tasks/:taskName`. The `<task-detail-tab>` does show the timestamp after drill-down.

- **Sticky-column offsets are hardcoded pixel values** — the five sticky left columns use `left: 0`, `left: 100px`, `left: 160px`, `left: 210px`, `left: 310px` in the component's shadow CSS. These values match the demo's fixed column widths. In the SNOW port, consider CSS subgrid or JavaScript-measured `offsetLeft` values to make this robust to content changes.

- **Tooltip uses HTML `title` attribute** — quick to implement and accessible on desktop, but SNOW Polaris has richer `now-tooltip` components that integrate with the design system's z-index and animation layers. Replace `title="..."` with `<now-tooltip>` wrappers in the SNOW port.
