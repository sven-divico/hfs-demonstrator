# HFS Status-Matrix Component — API Specification & How-To

**Audience:** ServiceNow developer porting the components into a Now Experience custom component.
**Source repo:** <https://github.com/sven-divico/hfs-demonstrator>
**Live reference:** <https://hfs-demo.biztechbridge.com> (creds via project lead)

> **Heads-up — data model has evolved.** The wire contract (request/response shapes) in this doc still describes the current API. The SQL examples that touch `wm_order` / `wm_task` describe the *original* 2-table backing. Read [05-data-acquisition-after-customer-order.md](05-data-acquisition-after-customer-order.md) for the current 3-table model (Customer Order → RFS → task) before writing pivot or drilldown code. The business motivation is in [../docs/business-view.md](../docs/business-view.md).

This document is the complete contract. If something here disagrees with the running demo or the spec, the running demo is authoritative.

---

## 0. Architecture at a glance

```
┌────────────────────────── BROWSER ─────────────────────────┐
│  Web Components (plain JS, no framework, no build step)    │
│    <wo-status-matrix>     pivot view (the deliverable)     │
│    <wo-detail-tab>        WO detail pane                   │
│    <task-detail-tab>      task detail pane                 │
│    <tab-strip>            workspace tab manager            │
└────────────────────────────────────────────────────────────┘
                              │
                              │ fetch(JSON)
                              ▼
┌────────────────────── REST API CONTRACT ───────────────────┐
│  GET /api/task-columns                  column registry    │
│  GET /api/work-orders/matrix?…          pivot (paginated)  │
│  GET /api/work-orders/:sysId            single WO + tasks  │
│  GET /api/work-orders/:sysId/tasks/:n   single task        │
└────────────────────────────────────────────────────────────┘
```

The components and the REST contract are independent surfaces. The components don't care who serves the JSON; the REST contract doesn't care who consumes it. In the SNOW port the same components stay, the REST contract is reimplemented as Scripted REST APIs against `wm_order` / `wm_task`.

---

## A. Custom Element API

### A.0 Conventions

- All four elements are defined via `customElements.define()` and attach an **open** Shadow DOM in `connectedCallback`.
- Configuration is via **`data-*` attributes** only. No properties, no methods on instances (intentionally; keeps the SNOW port boring).
- Cross-component communication is via **`CustomEvent` dispatched on `document`** with `bubbles: true, composed: true`. This crosses every shadow boundary cleanly.
- Components are independently reusable — you can drop `<wo-status-matrix>` into a page without `<tab-strip>`, and the events will simply have no listener.

### A.1 `<wo-status-matrix>`

The pivot view. Reads a paginated list of work orders from the matrix endpoint and renders them as one row per WO × one column per task.

**Attributes** *(read on connect and on change)*:

| Attribute | Type | Default | Description |
|---|---|---|---|
| `data-endpoint` | URL string | `/api/work-orders/matrix` | Matrix endpoint URL. The component appends `?list=&limit=&offset=`. |
| `data-list` | `"legacy" \| "attention"` | `"legacy"` | Filter — `legacy` returns all WOs, `attention` returns only WOs with ≥ 1 task in state `"Problem"`. |
| `data-tab-pane` | string | — | Set by `<tab-strip>` so the strip can show/hide this pane. Honour `[hidden]` to disable. |

**Observed attributes:** `["data-list"]`. Changing `data-list` triggers a refetch and resets to page 0.

**Events emitted** *(on `document`)*:

| Event | `detail` shape | Triggered by |
|---|---|---|
| `wo:open` | `{ woId: string, woNumber: string }` | Click on the `ORDER` cell of any row. |
| `task:open` | `{ woId: string, woNumber: string, taskName: string }` | Click on any task-state dot (except `not applicable`). `taskName` is the **canonical German name** (e.g. `"HV-S"`, `"GIS Planung"`). |

**Events listened:** none.

**Layout requirements:** the host must be a flex container or have a definite height; the table is internally scrollable.

**Example:**

```html
<wo-status-matrix
  data-endpoint="/api/work-orders/matrix"
  data-list="legacy"
  data-tab-pane="matrix"></wo-status-matrix>
```

---

### A.2 `<wo-detail-tab>`

Work-order detail pane. Renders header info + a list of all tasks for the WO. Each task is clickable, dispatching `task:open`.

**Attributes:**

| Attribute | Type | Required | Description |
|---|---|---|---|
| `data-wo-id` | string | yes | `sys_id` of the WO (e.g. `ord-0012867`). |
| `data-wo-number` | string | yes | Human-readable WO number (e.g. `ORD0012867`). |
| `data-tab-pane` | string | yes | Tab id, used by `<tab-strip>` to show/hide. |

**Events emitted:**

| Event | `detail` | Triggered by |
|---|---|---|
| `task:open` | `{ woId, woNumber, taskName }` | Click on any task row. |
| `tab:close` | `{ tabId }` (= `data-tab-pane`) | Click on the close `×` in the pane header. |

**On connect** it fetches `GET /api/work-orders/${woId}`. While loading it shows a "Loading…" placeholder.

---

### A.3 `<task-detail-tab>`

Task detail pane. Renders the single task's state, assignment group, and `sys_updated_on`.

**Attributes:**

| Attribute | Type | Required | Description |
|---|---|---|---|
| `data-wo-id` | string | yes | WO sys_id. |
| `data-wo-number` | string | yes | WO number for display. |
| `data-task-name` | string | yes | Canonical German task name (key into the matrix `tasks` map). |
| `data-tab-pane` | string | yes | Tab id for `<tab-strip>`. |

**Events emitted:**

| Event | `detail` | Triggered by |
|---|---|---|
| `tab:close` | `{ tabId }` | Click on the close `×`. |

**On connect** it fetches `GET /api/work-orders/${woId}/tasks/${encodeURIComponent(taskName)}`.

---

### A.4 `<tab-strip>`

Workspace tab manager. Renders tab buttons across the top and shows/hides panes (any element with a matching `data-tab-pane` attribute) inside the `.content` area of the page.

**Children (light DOM):** any number of `<button slot="tab">` elements. The first one in the markup (typically the matrix tab) is permanent — its close button is hidden via CSS.

**Tab button structure** *(set by `_mkTabButton` for dynamic tabs, authored by hand for the matrix tab in `index.html`)*:

```html
<button slot="tab" data-tab-id="…" data-tab-type="list|wo|task" class="active">
  <svg>…icon…</svg>
  <span class="tab-label">Display label</span>
  <span class="tab-close" role="button" aria-label="Close tab">…✕…</span>
</button>
```

`data-tab-type` drives the per-type accent colour via the CSS custom property `--tab-accent` (see §C).

**Events listened (on `document`):**

| Event | What it does |
|---|---|
| `wo:open` | If a WO tab already exists for that `woId`, activate it. Otherwise create a new `<wo-detail-tab>` pane + tab button (`data-tab-type="wo"`) and activate it. |
| `task:open` | Same, for `<task-detail-tab>` (`data-tab-type="task"`). The tab id encodes both `woId` and a sanitised `taskName` so the same task on different WOs gets distinct tabs. |
| `tab:close` | Remove the tab button + pane for `tabId`, fall back to the matrix tab. Ignores `tabId === "matrix"`. |

**Events emitted:** none. Tab-strip is a sink for the contract; the matrix and detail panes are the sources.

---

### A.5 Event contract — full picture

```
   <wo-status-matrix>             <wo-detail-tab>             <task-detail-tab>
         │                              │                            │
         │ click ORDER                  │ click task row             │ click ×
         │   wo:open                    │   task:open                │   tab:close
         │ click dot                    │ click ×                    │
         │   task:open                  │   tab:close                │
         ▼                              ▼                            ▼
   ─────────────────────── document.addEventListener ─────────────────
                                        │
                                        ▼
                               <tab-strip>  (creates/activates/closes tabs)
```

All events bubble + cross shadow DOM boundaries via `composed: true`. The strip is the only thing in the system that holds tab state; everything else is stateless w.r.t. tab management.

---

## B. REST API

### B.0 Conventions

- **Method:** `GET` only. The component is read-only.
- **Content-Type:** `application/json; charset=utf-8`.
- **Auth:** unspecified at the contract level. In the demo it's HTTP Basic auth at the Caddy layer; in SNOW it's whatever a Scripted REST API normally uses.
- **Error shape:** every non-`200` response returns `{ "error": "<short-code>", "message": "<human>" }`.

| Status | When |
|---|---|
| `200` | OK |
| `400` | Bad query parameter (e.g. unknown `list`, malformed `sysId`/`taskName`). |
| `404` | Resource doesn't exist (unknown `sysId`, unknown `taskName` for that WO). |
| `500` | Internal error. |

---

### B.1 `GET /api/task-columns`

Returns the canonical 17-task registry used as column headers and as the lookup-key list for the matrix `tasks` map.

**Query parameters:** none.

**Response 200:**

```json
[
  { "name": "HV-S",        "short": "HV",   "label": "Standard House Visit", "sequence": 1 },
  { "name": "UV-S",        "short": "UV",   "label": "Standard Unit Visit",  "sequence": 2 },
  { "name": "HV-NE4",      "short": "HV4",  "label": "House Visit NE4",      "sequence": 3 },
  …
  { "name": "Patch",       "short": "PCH",  "label": "Patch",                "sequence": 17 }
]
```

| Field | Semantics |
|---|---|
| `name` | Canonical German task name. **Authoritative join key** with the `tasks` map in the matrix response. |
| `short` | Column header label in the matrix UI. |
| `label` | Long-form English label, used in tooltips and detail panes. |
| `sequence` | Display order (ascending). The component renders columns in `sequence` order. |

**Demo implementation:** [public/task-columns.json](../public/task-columns.json) — served both as a static file and via this API endpoint.

**SNOW port:** model as a System Property or static script include; return the same JSON shape verbatim.

---

### B.2 `GET /api/work-orders/matrix`

The pivot endpoint — the one that replaces the developer's manual Excel sheet.

**Query parameters:**

| Param | Type | Default | Allowed |
|---|---|---|---|
| `list` | string | `legacy` | `legacy` (all WOs) \| `attention` (WOs with ≥ 1 task in state `Problem`) |
| `limit` | integer | `25` | `1` – `200` (clamped silently if outside) |
| `offset` | integer | `0` | `≥ 0` (clamped to `0` if negative) |

**Maps to SNOW:** `sysparm_limit` / `sysparm_offset`. `list` would map to a parameter the SNOW dev chooses (e.g. `filter`).

**Response 200:**

```typescript
{
  total:   number,   // total rows for this `list` filter (NOT page size)
  offset:  number,   // echoed back
  limit:   number,   // echoed back (post-clamping)
  columns: TaskColumn[],   // same shape as GET /api/task-columns
  rows: WorkOrderMatrixRow[]
}

interface WorkOrderMatrixRow {
  sys_id:               string;   // 'ord-0012867'
  number:               string;   // 'ORD0012867'
  status_code:          number;   // 100, 101, 102, 103, 105, 107, 108, 109
  construction_status:  string;   // 'Open' | 'in progress' | 'Completed'
                                  //   | 'Cancellation in progress' | 'Fallout'
  account:              string;   // 'Test1 Customer'
  city:                 string;
  address:              string;
  unit_count:           number;
  set_name:             string;   // 'SDU-GFTAL-NE4', 'MDU-PHA Full Expansion-NE4', …

  tasks: Record<CanonicalTaskName, TaskState>;
}

type TaskState =
  | "Draft" | "Pending Dispatch" | "Assigned"
  | "Scheduled" | "Work In Progress" | "Done"
  | "Problem" | "not applicable";
```

**Critical detail — lookup key:** the keys of `tasks` are the **canonical German names** (`"HV-S"`, `"GIS Planung"`, `"HÜP"`, …) — not `short`, not `label`. The component uses `columns[i].name` to look up each cell. If the SNOW REST returns the wrong key shape, the matrix will silently render `not applicable` for every cell.

**Every WO returns all 17 task entries.** Tasks that don't apply to the WO's status code use `state: "not applicable"`. The component renders these as `—` and treats them as non-clickable.

**Example pivot SQL (demo backend):**

```sql
SELECT wo.*, t.short_description, t.state
FROM   wm_order wo
JOIN   wm_task t ON t.work_order = wo.sys_id
WHERE  …                                  -- list filter
ORDER  BY wo.number DESC
LIMIT  ? OFFSET ?
```

Group by `wo.sys_id`, fold `(short_description, state)` pairs into the `tasks` map, return.

**Demo implementation:** [server/routes/matrix.ts](../server/routes/matrix.ts).

---

### B.3 `GET /api/work-orders/:sysId`

Full detail for one work order. Used by `<wo-detail-tab>`.

**Path parameter:**

| Param | Format | Example |
|---|---|---|
| `sysId` | matches `/^ord-\d{7,}$/` | `ord-0012867` |

**Response 200:**

```typescript
{
  // Same fields as WorkOrderMatrixRow (without the `tasks` map):
  sys_id, number, status_code, construction_status,
  account, city, address, unit_count, set_name,

  tasks: TaskDetail[]   // all 17 tasks for this WO, fully expanded
}

interface TaskDetail {
  sys_id:            string;   // 'wot-0050001'
  number:            string;   // 'WOT0050001'
  work_order:        string;   // back-reference to WO sys_id
  short_description: string;   // canonical German name — same as the matrix `tasks` map key
  short_code:        string;   // duplicated from task-columns.json for convenience
  state:             TaskState;
  assignment_group:  string | null;
  sys_updated_on:    string;   // ISO-8601
}
```

**Errors:** `400` if `sysId` doesn't match the regex, `404` if not found.

**Demo implementation:** [server/routes/work-order.ts](../server/routes/work-order.ts).

---

### B.4 `GET /api/work-orders/:sysId/tasks/:taskName`

Single task detail. Used by `<task-detail-tab>`.

**Path parameters:**

| Param | Format | Example |
|---|---|---|
| `sysId` | `/^ord-\d{7,}$/` | `ord-0012865` |
| `taskName` | canonical German name, **URL-encoded** | `HV-S`, `GIS%20Planung`, `H%C3%9CP` |

**Response 200:** a single `TaskDetail` object (same shape as a `tasks[]` element in §B.3).

**Errors:**
- `400` if `sysId` malformed.
- `404` if no task with that `short_description` exists for that WO.

**Demo implementation:** [server/routes/task.ts](../server/routes/task.ts).

**Note:** Fastify auto-decodes the path segment, so the server reads `req.params.taskName` directly. If your SNOW Scripted REST framework doesn't auto-decode, decode once and don't double-decode (`HÜP` is `H%C3%9CP` — a double decode mangles it).

---

## C. CSS Token Contract

The components read styling via CSS custom properties set on `:root` in light DOM. Custom properties pierce shadow DOM, so the components pick them up automatically.

**Required tokens** (the components will work with the built-in fallbacks, but a SNOW port should declare these so theme switching works):

```css
:root {
  --hfs-font:               "Source Sans 3", -apple-system, BlinkMacSystemFont, "Segoe UI", system-ui, sans-serif;

  /* Surfaces */
  --hfs-color-bg:           #f4f5f7;
  --hfs-color-surface:      #fff;
  --hfs-color-sidebar:      #fafbfc;
  --hfs-color-tab-active:   #dde3eb;
  --hfs-color-toolbar:      #eef0f3;
  --hfs-color-border:       #d8dde3;

  /* Text */
  --hfs-color-text:         #1b2734;
  --hfs-color-text-muted:   #5b6770;

  /* Brand */
  --hfs-color-primary:      #1f8476;
  --hfs-color-primary-bg:   #e8f5f1;

  /* Status dot fills */
  --hfs-status-open:        #9aa5b1;   /* Draft — ring only, no fill */
  --hfs-status-pending:     #f59e0b;   /* Pending Dispatch, Assigned */
  --hfs-status-scheduled:   #3b82f6;   /* Scheduled, Work In Progress */
  --hfs-status-done:        #10b981;   /* Done */
  --hfs-status-problem:     #dc2626;   /* Problem */

  /* Heights */
  --hfs-topbar-h:           48px;
  --hfs-tabstrip-h:         40px;
  --hfs-toolbar-h:          40px;
  --hfs-sidebar-w:          200px;
}
```

**Polaris mapping table** (suggestion; the developer chooses exact Polaris token names):

| Demo token | SNOW Polaris equivalent |
|---|---|
| `--hfs-color-primary` | `--now-color-primary` |
| `--hfs-color-text` | `--now-color-text` |
| `--hfs-color-text-muted` | `--now-color-text--secondary` |
| `--hfs-color-bg` | `--now-color-background--surface` |
| `--hfs-color-border` | `--now-color-border` |
| `--hfs-status-problem` | `--now-color-critical` |
| `--hfs-status-done` | `--now-color-positive` |
| `--hfs-status-scheduled` | `--now-color-information` |
| `--hfs-status-pending` | `--now-color-notice` |

**Per-tab accent token:** `--tab-accent` is set via attribute selectors in `app.css`:

```css
tab-strip > button[slot="tab"][data-tab-type="list"] { --tab-accent: var(--hfs-color-primary); }
tab-strip > button[slot="tab"][data-tab-type="wo"]   { --tab-accent: var(--hfs-status-scheduled); }
tab-strip > button[slot="tab"][data-tab-type="task"] { --tab-accent: var(--hfs-status-pending); }
```

The active tab's top accent and the icon colour both read `--tab-accent`. Add more types by adding more attribute-selector rows.

---

## D. How-To — porting to SNOW Now Experience

These steps assume a working ServiceNow developer instance and the standard `@servicenow/cli` toolchain.

### Step 1 — scaffold a Now Experience custom component

```bash
snc ui-component project --name x_company_hfs_status_matrix
cd x_company_hfs_status_matrix
```

This generates a project with `src/`, `tests/`, and a `now-cli.json`.

### Step 2 — copy the four custom elements

From this repo, copy [public/components/](../public/components/) into your project's `src/components/` (or wherever your build expects raw web components). Files:

- `wo-status-matrix.js`
- `wo-detail-tab.js`
- `task-detail-tab.js`
- `tab-strip.js`

If your scaffold uses the Now Experience renderer (`@servicenow/ui-renderer-snabbdom`), you have two options:

**Option A — keep them as native Web Components** *(recommended)*. Register all four via `customElements.define()` at boot, then wrap them in a thin Now Experience component whose template is just `<wo-status-matrix data-…></wo-status-matrix>`. The framework will treat them as opaque custom elements and won't interfere.

**Option B — translate the shadow templates to snabbdom JSX**. The components' shadow content is mostly imperative DOM construction in `_render`; the structural HTML in the template literals is simple enough to port mechanically. Style blocks port one-to-one.

### Step 3 — wire the tokens

Add the CSS custom properties from §C to your component's root styles. Map `--hfs-*` → `--now-*` per the table above (or your scoped scheme).

Copy [public/task-columns.json](../public/task-columns.json) into your project as a static asset (or seed a SNOW System Property `x_company.hfs.task_columns` with the same JSON and have the API echo it).

### Step 4 — implement the four Scripted REST APIs

Create a Scripted REST Service `HFS Status Matrix` with these four resources:

| Resource | Path | Method | Maps to §B |
|---|---|---|---|
| `task-columns` | `/task-columns` | GET | B.1 |
| `matrix` | `/work-orders/matrix` | GET | B.2 — read `sysparm_limit` / `sysparm_offset`, your own `list` param |
| `work-order` | `/work-orders/{sysId}` | GET | B.3 |
| `task` | `/work-orders/{sysId}/tasks/{taskName}` | GET | B.4 |

Each script does an ACL-aware GlideRecord lookup against `wm_order` / `wm_task` and assembles the JSON shapes from §B. Keep the matrix pivot server-side — do not return one row per task and let the client pivot.

### Step 5 — wire the component to the API

Set the matrix's `data-endpoint` to the REST resource URL the developer instance exposes:

```html
<wo-status-matrix
  data-endpoint="/api/x_company/hfs_status_matrix/work-orders/matrix"
  data-list="legacy">
</wo-status-matrix>
```

The detail tabs derive their fetch URLs from `data-endpoint` by convention — if you change the matrix path, also update the constants inside `wo-detail-tab.js` and `task-detail-tab.js` (one line each, search for `/api/work-orders`).

### Step 6 — smoke-check

1. Load the component in a UI Builder page.
2. Confirm the matrix renders 25+ rows with coloured dots.
3. Click an ORDER → blue tab opens with full WO detail.
4. Click a dot → amber tab opens with task detail.
5. Click the `×` on the WO tab → tab closes, matrix re-activates.
6. Switch list filter / page size — confirm fetches go out and table re-renders.

If any of 1–6 fails, the bug is almost certainly in the API response shape; cross-check against §B with the browser network tab against the live demo for a known-good payload.

---

## E. Reference data

### E.1 The 17 canonical tasks (in `sequence` order)

| # | `name` (key) | `short` (header) | `label` (display) |
|---|---|---|---|
| 1 | HV-S | HV | Standard House Visit |
| 2 | UV-S | UV | Standard Unit Visit |
| 3 | HV-NE4 | HV4 | House Visit NE4 |
| 4 | UV-NE4 | UV4 | Unit Visit NE4 |
| 5 | GIS Planung | GP | GIS Planning - NAS |
| 6 | Fremdleitungsplan | LLD | Utility Lines Plan |
| 7 | Genehmigungen | PM | Permits (VRAO / Aufbruch) |
| 8 | Tiefbau | CV | Civil Works |
| 9 | Spleißen | SP | Splicing |
| 10 | Einblasen | BF | Blow-in Fiber |
| 11 | Gartenbohrung | GD | Garden Drilling |
| 12 | Hauseinführung | WB | Wall Breakthrough |
| 13 | HÜP | HÜP | Install HÜP |
| 14 | Leitungsweg NE4 | CW4 | Cable Way NE4 |
| 15 | GFTA | GFTA | Install GFTA |
| 16 | ONT | ONT | Install ONT |
| 17 | Patch | PCH | Patch |

### E.2 Task lifecycle states

```
Draft → Pending Dispatch → Assigned → Scheduled → Work In Progress → Done
                                                          ↓
                                                       Problem (terminal fallout)
                                              not applicable (never created)
```

These are the **only** values the components accept for `state`. Any other string falls through to the default `pending` colour with the literal string in the tooltip.

### E.3 Status code → applicability (driven by `NAS ToBe` sheet)

Status codes (100, 101, 102, 103, 105, 107, 108, 109) each select a subset of the 17 tasks as applicable. Tasks that are not applicable for a given status code are sent with `state: "not applicable"` so the matrix shows `—`.

The authoritative mapping lives in the source XLSX. The seed in this repo implements it for the 25 demo WOs; the SNOW port re-derives the mapping from the live `wm_task` records (a task simply isn't created if it doesn't apply).

---

## F. Out of scope (intentionally)

The following are deliberately not in v1; they are noted here so the developer doesn't waste time looking for them:

- **Editing.** No `POST`/`PATCH`/`DELETE`. The components are read-only.
- **Real-time updates.** No WebSocket / polling. The "Last refreshed just now" hint is a placeholder; future refresh is a button.
- **Rich tooltips.** Matrix dot tooltips use the native `title` attribute. Polaris's tooltip component is a polish item.
- **Per-task history.** `<task-detail-tab>` shows current `state` + `sys_updated_on` only. The matrix API does not return per-task `sys_updated_on` (it would require changing the `tasks` map shape from `{name: state}` to `{name: {state, updated}}` — a real spec change, not a quick add).
- **i18n.** All UI strings are English; canonical task names stay German. A SNOW port would use the standard translation pipeline.
- **Tests.** Per the project spec, no automated tests in v1. The smoke checks in Step 6 above are the verification.

---

## G. Where to ask questions

- **Code issues:** open an issue at <https://github.com/sven-divico/hfs-demonstrator/issues>.
- **Spec questions:** the demo at <https://hfs-demo.biztechbridge.com> is authoritative — inspect the network tab against the live JSON.
- **Project lead:** sven.s0042@gmail.com.
