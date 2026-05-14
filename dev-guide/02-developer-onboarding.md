# Developer Onboarding — HFS Status Matrix

**Welcome.** You've been asked to port the work-order status matrix into the ServiceNow Workspace. Most of the hard thinking is already done. This document is a *hands-on* path that gets you from zero to "I understand the demo and I know what to write" in about an hour.

If you read only one other thing, read [`01-api-specification.md`](01-api-specification.md) — it's the contract you'll be implementing.

---

## TL;DR

1. **Try the running demo first** (5 minutes). It is the spec, made tangible.
2. **Run it locally** if you want to step through the code (10 minutes).
3. **Use the demo as a reference oracle while you port** — open DevTools on the live demo and copy JSON shapes / event signatures into your SNOW code.
4. **Re-read the API spec** ([01-api-specification.md](01-api-specification.md)) once the demo "clicks" for you. It'll make a lot more sense after step 1.

---

## Step 1 — Try the live demo (5 minutes)

**URL:** ask the project lead.
**Credentials:** ask the project lead — credentials are not committed to this repo.

### What to do, in order

1. **Look at the table.** This is the deliverable. The blocker you're being asked to solve is rendering this view (row = work order, column = task) inside SNOW Workspace.
2. **Hover a status dot.** Tooltip shows `<task name>: <state>`. The four states you'll see most: `Done`, `Pending Dispatch`, `Work In Progress`, `Problem`. The em-dash `—` means *not applicable for this WO's status code* (per the NAS ToBe sheet).
3. **Click "Needs Attention"** in the sidebar. The list filters to four WOs with at least one `Problem` task. This is the same endpoint with a different query parameter — open the network tab to see.
4. **Click an ORDER number** (e.g. `ORD0012848`). A new **blue** tab appears with that WO's full detail. The blue colour and clipboard icon mean "this tab holds a Work Order". The list tab stays open in the strip.
5. **Click a red task dot** in the matrix. An **amber** tab appears (Task type). Task tabs and WO tabs use different colours and icons so the user can see the mix at a glance.
6. **Click the `×` on the WO tab.** It closes; you return to the matrix. The matrix tab itself has no `×` — it's permanent.
7. **Change page size to 10**, watch pagination kick in. The pagination is built so it ports cleanly to SNOW (`sysparm_limit` / `sysparm_offset`).

By the time you've done these seven things you understand 90% of the UX you're being asked to rebuild.

---

## Step 2 — Run it locally (optional, 10 minutes)

You don't need the local stack to do the port. But it helps if you want to read the source while it runs, or test API shapes by hand.

### Prerequisites

- Node 22 (the Dockerfile uses `node:22-alpine` — anything 20+ should work)
- Git
- macOS, Linux, or WSL2

### Get it running

```bash
git clone https://github.com/sven-divico/hfs-demonstrator
cd hfs-demonstrator
npm install                  # ~30 s. Compiles better-sqlite3 native binding.
DB_PATH=./data/hfs.sqlite npm run reseed   # creates ./data/hfs.sqlite (25 WOs + 425 tasks)
DB_PATH=./data/hfs.sqlite npm start        # Fastify on :8080
```

Visit <http://localhost:8080/> — no auth at the local layer (Basic auth is only in front of the production deploy).

### Useful local commands

```bash
# Re-seed (after editing db/seed.sql)
DB_PATH=./data/hfs.sqlite npm run reseed

# Hit the API directly
curl -s "http://localhost:8080/api/work-orders/matrix?list=legacy&limit=5" | jq

# Reset everything
rm -rf data/ && DB_PATH=./data/hfs.sqlite npm run reseed
```

### Repo layout you'll care about

| Path | Why |
|---|---|
| [`public/components/`](../public/components/) | The four custom elements. **This is what you're porting.** 4 files, ~800 LOC total. |
| [`public/task-columns.json`](../public/task-columns.json) | The 17 canonical tasks. Port as a static asset or System Property. |
| [`public/app.css`](../public/app.css) | Light-DOM styles + the `--hfs-*` token set. Reference for the CSS contract. |
| [`server/routes/matrix.ts`](../server/routes/matrix.ts) | Reference implementation of the pivot. ~50 LOC; translate to GlideScript. |
| [`server/routes/work-order.ts`](../server/routes/work-order.ts) | Reference WO detail endpoint. |
| [`server/routes/task.ts`](../server/routes/task.ts) | Reference single-task endpoint. |
| [`dev-guide/01-api-specification.md`](01-api-specification.md) | The contract. Read after you've played with the demo. |
| [`HANDOVER.md`](../HANDOVER.md) | Higher-level handover doc — overlaps with the API spec; the spec is more current. |

You should **not** spend time understanding the Docker / Caddy / deploy plumbing — that's the demo's hosting, not yours.

---

## Step 3 — Use the demo as a reference oracle

This is the most useful trick. While you're porting, keep the live demo open in another browser window with **DevTools → Network** filtered to "Fetch/XHR". Every action you take in the demo shows you the exact JSON you need to produce on the SNOW side.

### Example session

You're writing the Scripted REST resource for the matrix. You're not sure if `unit_count` is a number or a string.

1. Live demo → DevTools → Network → filter `matrix`
2. Click "Needs Attention" → see a fresh request fire
3. Click the request → Response tab → look at `rows[0].unit_count`. You'll see `1`, no quotes — it's a number.
4. Write your GlideRecord code to return a number, not `gr.getValue('unit_count')` (which returns a string).

This loop replaces hours of spec-reading with seconds of curiosity.

### Example: what does `task:open` look like?

Open the live demo, then in DevTools → Console:

```js
document.addEventListener('task:open', e => console.log('task:open', e.detail));
```

Click any task dot in the matrix. The console prints:

```
task:open { woId: "ord-0012848", woNumber: "ORD0012848", taskName: "Genehmigungen" }
```

That's the event contract you'll wire up in your SNOW component.

### Example: cheating the pivot logic

You're implementing the matrix pivot in GlideScript. You want to know if a particular WO has the `Genehmigungen` task in state `Problem`. From the local repo:

```bash
sqlite3 ./data/hfs.sqlite \
  "SELECT o.number, t.state FROM wm_order o JOIN wm_task t ON t.work_order=o.sys_id WHERE t.short_description='Genehmigungen' AND t.state='Problem'"
```

The result is your fixture for asserting your GlideRecord query is right.

---

## Step 4 — Port, step by step

When you sit down to write SNOW code, the order that minimises rework is:

### 1. Stand up the four Scripted REST resources, returning **fake but well-shaped** data first

Don't touch GlideRecord yet. Hardcode the four endpoints to return canned JSON copied from the live demo. This lets you build the UI side without API-side bugs in the way.

```js
// HFS Status Matrix > matrix (initial stub)
(function process(request, response) {
  response.setStatus(200);
  return JSON.parse(/* paste live JSON from https://hfs-demo.biztechbridge.com/api/work-orders/matrix?list=legacy */);
})(request, response);
```

### 2. Drop the four components into a Now Experience component

Copy `public/components/*.js`, register them via `customElements.define()` at component boot. The framework treats them as opaque custom elements. Use a thin host template:

```html
<wo-status-matrix
  data-endpoint="/api/x_company/hfs_status_matrix/work-orders/matrix"
  data-list="legacy"
  data-tab-pane="matrix">
</wo-status-matrix>
```

Add `<tab-strip>` and the matrix tab button (see [`public/index.html`](../public/index.html) for the exact static markup).

### 3. Wire `--hfs-*` tokens to Polaris

Open the spec's CSS Contract section (§C). Map the demo tokens to the Polaris ones — the suggested mapping is in the table.

### 4. Replace the stub Scripted REST with real GlideRecord queries

Now that the UI works against the stub, swap the canned JSON for real `wm_order` / `wm_task` reads. Test one endpoint at a time:

- `task-columns` first — trivial, just returns the JSON registry.
- `work-order` next — a single GlideRecord get + join.
- `matrix` last — the pivot. Most complex. Use the reference SQL in §B.2 as a guide.

### 5. Verify against the live demo

For each endpoint, open both the live demo's response and your SNOW response side-by-side. JSON should match shape exactly (the field *order* doesn't matter; field *names* and *types* do).

---

## Common porting recipes

### "How do I do the pivot in GlideScript?"

The demo's [`server/routes/matrix.ts`](../server/routes/matrix.ts) is ~50 lines. The logic:

```
1. Run a list query → array of work-order records.
2. Run a task query for the page's work-order sys_ids → array of (work_order, short_description, state).
3. Build a Map<work_order_sys_id, Record<task_name, state>>.
4. For each WO in step 1, attach `tasks: theMap.get(wo.sys_id) ?? {}`.
5. Return { total, offset, limit, columns, rows }.
```

In GlideScript:

```js
// Pseudocode — adapt to your style
var orders = [];
var ordersGR = new GlideRecord('wm_order');
ordersGR.orderByDesc('number');
ordersGR.chooseWindow(offset, offset + limit);  // SNOW pagination
ordersGR.query();
while (ordersGR.next()) orders.push(serialiseOrder(ordersGR));

var orderIds = orders.map(function(o){ return o.sys_id; });
var tasksByWo = {};
var tasksGR = new GlideRecord('wm_task');
tasksGR.addQuery('work_order', 'IN', orderIds.join(','));
tasksGR.query();
while (tasksGR.next()) {
  var wo = tasksGR.getValue('work_order');
  if (!tasksByWo[wo]) tasksByWo[wo] = {};
  tasksByWo[wo][tasksGR.getValue('short_description')] = tasksGR.getValue('state');
}

orders.forEach(function(o){ o.tasks = tasksByWo[o.sys_id] || {}; });
return { total: total, offset: offset, limit: limit, columns: columns, rows: orders };
```

### "The matrix renders but all cells are em-dashes"

This is the #1 porting bug. Your matrix is returning the `tasks` map with the wrong key shape. The component looks up `row.tasks[column.name]` where `column.name` is the canonical German name (`"HV-S"`, `"GIS Planung"`, …). If your API returns the keys as `short` codes (`"HV"`) or English labels (`"Standard House Visit"`), every lookup fails and you get all em-dashes.

**Fix:** ensure the SQL/GlideRecord uses `wm_task.short_description` (the canonical name) as the map key.

### "Drill-down doesn't work — clicks do nothing"

The components dispatch `wo:open` / `task:open` events on `document`. If your SNOW host page mounts the components inside a shadow root of its own, the events bubble out (composed: true) but may not reach `<tab-strip>` if it's in a sibling shadow tree.

**Fix:** keep `<tab-strip>` and `.content` siblings in the same DOM scope (light DOM or a common shadow root).

### "How do I update the live demo's seed to match my SNOW data?"

For business demos:

```bash
# Edit db/seed.sql, then:
./deploy-to-prod.sh
```

The `seed.sql` is hand-written for clarity; each `INSERT` is one WO or one task. Reuse the patterns in §7 of the design spec.

### "I need a new task type / status state — where do I add it?"

- New task: add a row to [`public/task-columns.json`](../public/task-columns.json), then add 25 corresponding rows in `db/seed.sql` (one per WO).
- New lifecycle state: extend the `stateClass()` mapping in [`public/components/wo-status-matrix.js`](../public/components/wo-status-matrix.js) and add the matching CSS rule for the dot colour.

---

## FAQ

**Q: Can I keep the Web Components as-is in SNOW, or do I have to translate to JSX?**
You can keep them. SNOW's Now Experience renderer (snabbdom-based) treats unknown custom elements as opaque DOM nodes — it doesn't interfere with their lifecycle. You only need to translate if your team has a hard policy against vanilla web components.

**Q: The matrix endpoint takes `limit` / `offset`. SNOW uses `sysparm_limit` / `sysparm_offset`. Which wins?**
Your Scripted REST URL uses whatever SNOW prefers. The component is parameterised — set `data-endpoint` to your URL, the rest is just query-string mechanics. If your script needs to read `sysparm_limit` instead of `limit`, that's an internal detail.

**Q: Do I need to implement WebSocket / real-time updates?**
No. The demo is read-only; users get a fresh view on tab open / list switch. If the business asks for live updates later, that's a future iteration.

**Q: The matrix endpoint sometimes returns `tasks: {}` for a WO. Bug?**
Not a bug. If a WO genuinely has no `wm_task` records, the map is empty and every column renders as em-dash. In practice the seed ensures every WO has all 17 tasks; you may want to do the same.

**Q: Can I evolve the API contract?**
Yes, but coordinate with the project lead. The shape is documented in [01-api-specification.md](01-api-specification.md). Backward-compatible additions (new optional fields) are fine; renaming or removing fields breaks the component.

**Q: There's no `sys_updated_on` per task in the matrix response. Why?**
Trade-off: the matrix endpoint returns 25 × 17 = 425 task entries per page. Including a full timestamp per cell roughly doubles the payload. The matrix tooltip therefore shows state only; the per-task `<task-detail-tab>` shows full timestamps. If the business wants timestamps in the matrix tooltip, change the `tasks` map shape from `{name: state}` to `{name: {state, sys_updated_on}}` and update the component accordingly.

---

## When to ping back

You should be able to do most of this independently. Reach out to the project lead if:

- A field in the API spec is ambiguous and the live demo doesn't disambiguate it.
- You hit a SNOW-platform constraint that makes a component contract impossible to satisfy (e.g. ACL prevents reading `wm_task` for the user account).
- Business asks for a feature outside §F of the API spec — get it on a backlog rather than improvising.

**Lead contact:** sven.s0042@gmail.com.

**Repo issues:** <https://github.com/sven-divico/hfs-demonstrator/issues>.

---

## What "done" looks like

A successful port has:

- A Now Experience custom component embedded in a Workspace UI Builder page.
- The matrix renders 25+ rows against live `wm_order` / `wm_task` data.
- Click → drill-down → close cycle works end-to-end.
- Pagination works against `sysparm_limit` / `sysparm_offset` (or whatever your Scripted REST uses).
- The visual matches the demo within a small token-mapping delta.
- A handover doc on your side that lists the four Scripted REST URLs + the project version you ported from.

Good luck. The demo will be kept running while you port; lean on it.
