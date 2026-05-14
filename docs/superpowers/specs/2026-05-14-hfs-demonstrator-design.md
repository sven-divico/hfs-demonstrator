# HFS Demonstrator — Design

**Status:** Draft for review
**Date:** 2026-05-14
**Author:** Sven Schuchardt (with Claude)
**Related:** [`docs/wo-task-status-matrix-demonstrator.md`](../../wo-task-status-matrix-demonstrator.md), [`docs/vault/projects/hfs-demonstrator/project-overview.md`](../../vault/projects/hfs-demonstrator/project-overview.md), `docs/HFS-Screens.docx`, `docs/mockup.png`, `docs/NAS_Task Decomposition_V2.xlsx`, `docs/ORD0001472.xlsx`

---

## 1. Purpose

Build an interactive UX prototype that demonstrates a **Work Order Task Status Matrix** — one row per Work Order × one column per task type — to validate the mental model with business and to **hand the visualization JavaScript to the ServiceNow developer** who is currently struggling to build a row-oriented representation of a Work Order and its related tasks.

The demonstrator is **read-only**. State changes are out of scope; the goal is to lock UX and ship reusable view-layer code, not to build a workflow twin.

## 2. Decisions (from brainstorm)

| # | Decision | Rationale |
|---|---|---|
| Q1 | UX clickable prototype (read-only) | Goal is to lock UX and hand over view code; workflow stays in SNOW |
| Q2 | Plain Web Components + vanilla TypeScript | Ports 1:1 into a ServiceNow Now Experience custom element; the JS the SNOW dev is struggling with *is* the deliverable |
| Q3 | Node 22 + Fastify + better-sqlite3, single container | Tiny API doubles as a Scripted REST contract for the SNOW dev |
| Q4 | Hand-curated ~25 WO seed in `seed.sql`, anchored in real XLSX values | Every row tells a discussion-worthy story; reseed is cheap |
| Q5 | Strong family resemblance to ServiceNow Polaris (not pixel-faithful) | Believable look; effort focused on the matrix UX |
| Q6 | `hfs-demo.biztechbridge.com`, **host-native Caddy** in front of both apps, Basic auth | Multi-app pattern; biztechbridge today runs Caddy in-container — refactored as part of this work |
| Q7 | Tab-strip drill-down (mockup-faithful) | Matches the standard SNOW workspace pattern the dev will rebuild |

## 3. Architecture

```
Stakeholder browser  →  Caddy on host (TLS + Basic auth)  →  Docker container :8080
                          ***REDACTED-IP***
                          /etc/caddy/Caddyfile

┌─ Docker container ─────────────────────────────────────────────┐
│  Fastify (Node 22)  ──── reads ────▶  better-sqlite3            │
│    port 8080                          /data/hfs.sqlite          │
│    GET /api/...                       (rebuilt from seed.sql    │
│    serves /public/*                    on container start)      │
│                                                                 │
│  /public/                                                       │
│    index.html, app.css, task-columns.json                       │
│    components/                                                  │
│      ├─ wo-status-matrix.ts                                     │
│      ├─ wo-detail-tab.ts                                        │
│      ├─ task-detail-tab.ts                                      │
│      └─ tab-strip.ts                                            │
└─────────────────────────────────────────────────────────────────┘
```

**Single Node process** serves both the REST API and the static `public/` directory. SQLite lives inside the container's writable layer (no volume) so every fresh container starts from `seed.sql`. **Host-native Caddy** (installed via apt, systemd-managed) owns `:80` and `:443` on the server and reverse-proxies to the hfs-demo container on `localhost:8080` and the refactored biztechbridge container on `localhost:8081`. See §11 for the biztechbridge refactor.

## 4. Components (the dev-handover payload)

Four standards-based custom elements. No framework dependency.

| Element | Attributes | Events emitted | Notes |
|---|---|---|---|
| `<wo-status-matrix>` | `data-endpoint`, `data-filter` | `wo:open` (detail: `{woId, number}`), `task:open` (detail: `{woId, taskName}`) | Fetches `/api/work-orders/matrix`, renders sticky-first-column table, colour-coded dots, hover tooltips |
| `<wo-detail-tab>` | `data-wo-id` | `tab:close` | Fetches `/api/work-orders/:id`, renders WO header + per-task list |
| `<task-detail-tab>` | `data-wo-id`, `data-task-name` | `tab:close` | Fetches single task detail; shows state, assignment group, and `sys_updated_on` timestamp (no history table in v1) |
| `<tab-strip>` | — | — | Thin tab manager. Listens for `wo:open` / `task:open` on `document`, instantiates tab elements, manages active state |

**UX behaviors in scope:**
- Click ORDER cell → open WO-detail tab
- Click status dot → open task-detail tab
- Hover status dot → tooltip with full state label + `sys_updated_on`
- Sticky first column with WO meta (number, customer, address, construction status)
- Sidebar lists: *Legacy Orders* (all WOs) and *Needs Attention* (any WO with a task in state `Problem`)
- Status glyphs: `—` not-applicable, `○` open/draft (gray ring, no fill), `●` filled colored dot for every other state — blue for Scheduled and Work In Progress, green for Done, amber for Pending Dispatch / Assigned, red for Problem / Fallout

**Out of scope:**
- Edits or write-back of any kind
- Real authentication, user-specific lists, favorites
- Smart "Needs Attention" filtering beyond the has-Problem rule
- Pagination (25 rows fits on screen; revisit if seed grows)
- Mobile / narrow-viewport layout

## 5. Data model

SQLite schema in `db/schema.sql`. Field names mirror ServiceNow `wm_order` / `wm_task` so the SNOW dev sees a familiar shape.

```sql
CREATE TABLE wm_order (
  sys_id              TEXT PRIMARY KEY,            -- 'ord-0012865'
  number              TEXT UNIQUE NOT NULL,        -- 'ORD0012865'
  status_code         INTEGER NOT NULL,            -- 100,101,102,103,105,107,108,109
  construction_status TEXT,                        -- 'Open','in progress','Completed',
                                                   --   'Cancellation in progress','Fallout'
  account             TEXT,                        -- 'Test3 Customer'
  city                TEXT,                        -- 'Borken'
  address             TEXT,                        -- 'Willbecke 14'
  unit_count          INTEGER,
  set_name            TEXT                         -- 'SDU-GFTAL-NE4', 'MDU-PHA Full Expansion-NE4', ...
);

CREATE TABLE wm_task (
  sys_id            TEXT PRIMARY KEY,             -- 'wot-0047317'
  number            TEXT UNIQUE NOT NULL,         -- 'WOT0047317'
  work_order        TEXT NOT NULL REFERENCES wm_order(sys_id),
  short_description TEXT NOT NULL,                -- canonical task name (German), join key with task-columns.json: 'HV-S','GIS Planung','Tiefbau',...
  short_code        TEXT NOT NULL,                -- column header from task-columns.json: 'HV','GP','CV',...
                                                  -- denormalized for convenience; source of truth is task-columns.json
  state             TEXT NOT NULL,                -- 'Draft','Pending Dispatch','Assigned',
                                                  --   'Scheduled','Work In Progress','Done',
                                                  --   'Problem','not applicable'
  assignment_group  TEXT,
  sys_updated_on    TEXT                          -- ISO-8601 timestamp
);

CREATE INDEX idx_task_wo ON wm_task(work_order);
```

**Task registry** is a single JSON file at `public/task-columns.json` listing the 17 canonical tasks with `name` (German, canonical), `short` (column header), `label` (English display from real WO data), and `sequence`. Same file is served by both the static handler and `/api/task-columns` so the SNOW dev has one place to change column order.

## 6. REST API contract

| Method | Path | Returns |
|---|---|---|
| GET | `/api/task-columns` | `[{name, short, label, sequence}, …]` — mirror of `public/task-columns.json` |
| GET | `/api/work-orders/matrix?list=legacy\|attention` | `{columns:[…task-registry…], rows:[{sys_id, number, status_code, construction_status, account, city, address, unit_count, set_name, tasks:{<canonical-name>: <state>, …}}]}` |
| GET | `/api/work-orders/:sysId` | Full WO header + nested `tasks[]` (for `<wo-detail-tab>`) |
| GET | `/api/work-orders/:sysId/tasks/:taskName` | Single task detail (for `<task-detail-tab>`); `:taskName` is the canonical German `name` |

The matrix endpoint pre-pivots server-side using the algorithm from `docs/wo-task-status-matrix-demonstrator.md`, just expressed as SQL + a small JS pivot. The frontend never does row→column math. **Lookup key in the `tasks` map is the canonical German `name`** (e.g. `"HV-S"`, `"GIS Planung"`) — *not* `short` or `label`. This must be documented in HANDOVER.md so the SNOW dev's Scripted REST API returns the same key shape.

**Error responses:**

| Status | When |
|---|---|
| `200` | Success |
| `400` | Bad `list` query param (anything other than `legacy` or `attention`); malformed `:sysId` or `:taskName` |
| `404` | Unknown `:sysId`; unknown `:taskName` for that WO |
| `500` | Internal error (e.g. SQLite failure) |

All non-`200` responses return JSON `{error: "<short-code>", message: "<human>"}` so the SNOW dev's Scripted REST APIs can mirror the shape.

## 7. Seed data

`db/seed.sql` is **hand-curated**, ~25 WOs and ~250 tasks. Anchored in real values extracted from the XLSX inputs:

- **WO numbers:** `ORD0012828`–`ORD0012867` range (extends mockup set)
- **Customers:** `Test1 Customer` … `Test10 Customer`
- **City/Address:** `Borken / Willbecke 12…20` + a few `Hauptstraße N` for variety
- **Status codes:** mix of `100, 101, 102, 103, 105, 107, 108, 109` (≥2 of each)
- **Sets:** `SDU-GFTAL-HTP`, `SDU-GFTAL-NE4`, `MDU-GFTAL-NE4`, `MDU-PHA Standard-NA`, `MDU-PHA Full Expansion-NE4`
- **17 canonical task names** per `NAS ToBe` sheet — `HV-S, UV-S, HV-NE4, UV-NE4, GIS Planung, Fremdleitungsplan, Genehmigungen, Tiefbau, Spleißen, Einblasen, Gartenbohrung, Hauseinführung, HÜP, Leitungsweg NE4, GFTA, ONT, Patch`
- **Real EN ↔ DE mapping** from ORD0001472: `HV-S = Standard House Visit`, `Genehmigungen = VRAO Permit / Aufbruchgenehmigung`, `Spleißen = Splicing`, `Hauseinführung = Wall breakthrough`, `HÜP = Install HUP`, etc.

**Story rows** (each WO illustrates one discussion-worthy pattern):

| # | WO | construction_status | Pattern |
|---|---|---|---|
| 1–3 | ORD0012867, 64, 60 | Completed | All Done — green row |
| 4–6 | ORD0012865, 53, 49 | in progress | Civil works done, mounting open |
| 7 | ORD0012848 | Fallout | `Genehmigungen` Problem — blocked on permits |
| 8 | ORD0012846 | Fallout | `Tiefbau` Problem — civil works stuck |
| 9–10 | ORD0012845, 44 | Open | All Pending Dispatch — fresh orders |
| 11 | ORD0012843 | in progress | Scheduled house visit (Scheduled = blue) |
| 12 | ORD0012842 | Cancellation in progress | Mostly Done, last two `not applicable` |
| 13–14 | ORD0012841, 40 | in progress | MDU pattern with Multiple UV-NE4 / GFTA |
| 15 | ORD0012839 | in progress | `Spleißen` WIP, upstream Done |
| 16–17 | ORD0012838, 37 | Open | Draft phase — `GIS Planung` Draft |
| 18 | ORD0012836 | in progress | HÜP Done, `Hauseinführung` Problem |
| 19 | ORD0012835 | in progress | Two parallel Problems — needs attention |
| 20–22 | ORD0012834, 33, 32 | in progress | Healthy mid-flow across set types |
| 23 | ORD0012831 | in progress | Long-tail: only `ONT` + `Patch` left |
| 24 | ORD0012830 | in progress | Multi-unit MDU |
| 25 | ORD0012828 | Completed | Reference happy-path |

**Applicability rule:** for each WO, tasks marked `unconsidered` for that status code in the `NAS ToBe` sheet become `not applicable` (rendered as `—`); the remaining tasks get a believable lifecycle state per the row's pattern.

**Reseed paths:**
1. Local edit `seed.sql` → `./deploy-to-prod.sh` (~30 s, rebuilds image)
2. `ssh` to host → `docker compose exec hfs-demo node scripts/reseed.ts` (in-place, no image rebuild)

## 8. Visual style

Strong family resemblance to ServiceNow Polaris, not pixel-faithful.

- **Typography:** system font stack with Source Sans 3 fallback (free, similar feel)
- **Palette:** dark blue header (`#1b2734`), teal primary (`#1f8476`), neutral grays for chrome
- **Status dot colors:** open `#9aa5b1`, scheduled/in-progress `#3b82f6`, complete `#10b981`, Problem/Fallout `#dc2626`, not-applicable `—` glyph
- **CSS tokens** declared as `--hfs-color-*` variables in `app.css` — easy mapping table for the SNOW dev to swap with Polaris tokens (`--now-color-*`)
- **Layout chrome** mimics mockup: dark top bar with workspace switcher, tab strip beneath, sidebar with "My Lists", main pane with sticky-header table

## 9. Repository layout

```
HFS-Demonstrator/
├── README.md                  ← run locally, deploy, reseed
├── HANDOVER.md                ← for the SNOW developer ★
├── Dockerfile
├── docker-compose.yml
├── deploy-to-prod.sh          ← mirrors biztechbridge
├── Caddyfile.snippet          ← documentary copy of the hfs-demo block in /etc/caddy/Caddyfile (reference; not applied by deploy)
├── package.json               (Node 22, fastify, better-sqlite3, tsx)
├── tsconfig.json
├── server/
│   ├── index.ts               ← Fastify boot + static + API
│   ├── db.ts                  ← better-sqlite3 wrapper
│   └── routes/
│       ├── matrix.ts
│       ├── work-order.ts
│       └── task.ts
├── db/
│   ├── schema.sql
│   └── seed.sql               ← ~25 WOs, ~250 tasks
├── public/                    ← HANDOVER PAYLOAD ★
│   ├── index.html
│   ├── app.css
│   ├── task-columns.json
│   └── components/
│       ├── wo-status-matrix.ts
│       ├── wo-detail-tab.ts
│       ├── task-detail-tab.ts
│       └── tab-strip.ts
└── scripts/
    └── reseed.ts
```

## 10. HANDOVER.md (the developer doc)

Contains:

1. **Custom-element contracts** — attribute/event tables from §4
2. **API contract** — endpoints + JSON shapes from §6, framed as "this is what your Scripted REST APIs need to return"
3. **Portability matrix** — which files port directly into a Now Experience component vs. which are demo-only:
   - `public/components/*.ts` → port into SNOW Now Experience component (view + controller)
   - `public/app.css` → keep as styles, map `--hfs-*` tokens to `--now-*` tokens
   - `public/task-columns.json` → port as static resource or System Property
   - `server/*`, `db/*` → demo-only; replace with Scripted REST APIs against `wm_order` / `wm_task`
4. **CSS token mapping table** — demo variable → Polaris token name
5. **Known gaps** — the Out-of-Scope list from §4

## 11. Deploy

### 11.1 One-time host setup — host-native Caddy + biztechbridge refactor

Today the biztechbridge container runs Caddy *inside* the container and binds the host's `:80` + `:443` directly. To host two apps on the same server we move TLS termination to a **host-native Caddy** (installed via apt, systemd-managed) sitting in front of both backends.

**Refactor biztechbridge** (separate small change, sequenced before the first hfs-demo deploy):

1. Change `biztechbridge/Dockerfile` stage 2 to `nginx:alpine` serving the built `dist/` directory on container port `:80`. (We drop in-container Caddy entirely — its job moves to the host.)
2. Change `biztechbridge/docker-compose.yml` to publish `"8081:80"` (and remove `443` mappings + the `caddy_data`/`caddy_config` volumes; certs now belong to host Caddy).
3. Verify with `curl localhost:8081` on the host.

**Install host Caddy:**

```bash
sudo apt install -y caddy
```

**`/etc/caddy/Caddyfile`** (managed by hand, both site blocks live here):

```caddy
biztechbridge.com, www.biztechbridge.com {
    reverse_proxy localhost:8081
}

hfs-demo.biztechbridge.com {
    basicauth {
        demo $2a$14$<bcrypt-hash-of-shared-password>
    }
    reverse_proxy localhost:8080
}
```

Reload: `sudo systemctl reload caddy`. Caddy auto-issues TLS for both domains on first request.

**DNS:** A record `hfs-demo.biztechbridge.com → ***REDACTED-IP***` (the apex and `www` already point there).

This one-time setup is documented step-by-step in `README.md`.

### 11.2 Per-deploy flow — `deploy-to-prod.sh`

Mirrors `biztechbridge/deploy-to-prod.sh`:

1. `rsync` source to `***REDACTED-USER***@***REDACTED-IP***:/home/***REDACTED-USER***/hfs-demonstrator`, excluding `node_modules`, `.git`, `dist`, `.env*`
2. ssh in, `cd hfs-demonstrator`, `sudo -n docker compose up --build -d --remove-orphans`
3. ssh in, `sudo -n docker image prune -f`

The container publishes `"8080:8080"`. Host Caddy already routes `hfs-demo.biztechbridge.com → :8080`, so the redeploy is invisible to Caddy — no reload needed for routine deploys.

### 11.3 Why this is worth the one-time cost

- Adding app #3 later = one new site block + one `systemctl reload caddy`. No container juggling.
- Certs are managed in one place by Caddy's automatic ACME flow; they survive any container rebuild.
- biztechbridge's container shrinks to a pure static-server (no Caddy binary, no `caddy_data` volume).

## 12. Open items left to the implementation phase

- Exact 17-row content of `task-columns.json` (sequence + short codes confirmed; final English labels to be polished against the WO0040xxx examples)
- Bcrypt password hash for Caddy basicauth (generated at deploy time)
- Final colour values per status if business has brand colours

## 13. Anti-goals

- Not a SNOW replacement; never to be confused with the real workspace
- Not a workflow simulator; no state transitions, no edits
- Not production-grade observability — no metrics, no error tracking beyond `console.error`
- No tests beyond a hand-smoke check; effort goes into UX iteration, not test infrastructure
