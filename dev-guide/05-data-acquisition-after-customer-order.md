# Data Acquisition After the Customer Order Refactor

**Audience:** ServiceNow developer porting the matrix endpoint.
**Prereq:** read [01-api-specification.md](01-api-specification.md), [03-snow-recipe.md](03-snow-recipe.md), and [04-pagination-and-query-improvements.md](04-pagination-and-query-improvements.md) — those describe the *original* 2-table model (`wm_order` → `wm_task`). This document is the **delta** that supersedes the data model and pivot sections of those docs.

> **What this changes vs. what stays.**
> The endpoint contract in `01 §B.2` is unchanged on the wire — same `{ columns, rows, total, offset, limit }` envelope, same German short-description keys in the per-row `tasks` map. Only the *backing data model* and the *pivot SQL/GlideScript* change. Read this doc to update those; everything else in 01/03/04 still applies.

---

## 1. The new data model

```
wm_customer_order             ← business-facing record; matrix rows are these
  uuid (PK)                     'co-NNNNNNN'
  number                        'CO-YY-XXXX-XXXX'
  customer_name, address, city, phone, order_date,
  scheduled_appointment, status_code, construction_status,
  unit_count, set_name
  │
  ├── wm_rfs_order  rfs_type=LMA            (16 tasks)
  └── wm_rfs_order  rfs_type=Connectivity   (1 task: ONT)
        sys_id (PK)              'rfs-NNNNNNN'
        number                   'RFSNNNNNNN'
        customer_order (FK)      → wm_customer_order.uuid
        rfs_type                 'LMA' | 'Connectivity'
        │
        └── wm_task
              sys_id (PK)         'wot-NNNNNNN'
              number              'WOTNNNNNNN'
              rfs_order (FK)      → wm_rfs_order.sys_id
              rfs_type            denormalised copy of parent.rfs_type ← see §3.2
              short_description, short_code, state, assignment_group, sys_updated_on
```

Two structural changes vs the old model:

1. **A new top-level table** (`wm_customer_order`) is the row backing for the matrix. Pagination, counting, sorting, and filtering all happen at the Customer Order level — not at the RFS level, and certainly not at the task level.
2. **`wm_task.work_order` is gone.** Tasks now point at `wm_rfs_order` via `rfs_order`. The owning Customer Order is reached transitively (`task → rfs → co`).

The 17 canonical German `short_description` values are unchanged. The map key contract from `01 §B.2` is intact — the matrix component still keys `row.tasks` on `"HV-S"`, `"GIS Planung"`, `"HÜP"`, etc.

## 2. The pivot — old vs new

### 2.1 Old pivot (2 tables)

```sql
SELECT  wo.*, t.short_description, t.state
FROM    wm_order wo
JOIN    wm_task  t  ON t.work_order = wo.sys_id
ORDER BY wo.number DESC;
```

Group by `wo.sys_id`, fold `(short_description → state)` into `tasks`.

### 2.2 New pivot (3 tables)

```sql
SELECT  co.*, t.short_description, t.state
FROM    wm_customer_order co
JOIN    wm_rfs_order      rfs ON rfs.customer_order = co.uuid
JOIN    wm_task           t   ON t.rfs_order        = rfs.sys_id
ORDER BY co.number DESC;
```

Group by `co.uuid`, fold `(short_description → state)` into `tasks`. The fold logic is **identical** — the only difference is the join path to reach the task rows.

In the demo backend ([server/routes/matrix.ts](../server/routes/matrix.ts)) the pivot is done in two queries per page: one for the CO rows, then one batched task query scoped to the page's CO IDs and going through the RFS join inline. That stays well inside the round-trip budget from `04 §3.3`.

## 3. Optimization angles the new model unlocks

The split into `LMA` + `Connectivity` is a constraint imposed by TMF — but once it exists in the schema, two pieces of metadata become cheap, and both let you skip joins in the matrix pivot.

### 3.1 Filter by `rfs_type` without joining `wm_rfs_order`

The demo denormalises `wm_task.rfs_type` (an exact copy of `wm_rfs_order.rfs_type`). This is set in `seed.sql` at insert time and is intended to be maintained by a SNOW Business Rule on `wm_task` (set on insert, recompute if the rare `rfs_order` reassignment ever happens). The benefit:

```sql
-- "Only the activation/Connectivity-side tasks across the whole list"
SELECT * FROM wm_task WHERE rfs_type = 'Connectivity';
```

No join to `wm_rfs_order` to filter by side. For the matrix this matters when you eventually want a sidebar filter like *"Only show orders with an open Connectivity task"* — the count and the page-scoped task fetch both stay one-table reads.

If you opt **not** to denormalise (defensible: violates 3NF, requires a business rule to stay consistent), the alternative is a two-step:

```javascript
// Step 1: pull rfs_ids for the side you want
var rfsGR = new GlideRecord('wm_rfs_order');
rfsGR.addQuery('rfs_type', 'Connectivity');
rfsGR.query();
var connRfsIds = [];
while (rfsGR.next()) connRfsIds.push(rfsGR.getUniqueValue());

// Step 2: scope tasks to those rfs_ids
taskGR.addEncodedQuery('rfs_orderIN' + connRfsIds.join(','));
```

That's the same shape as the `attention`-list two-pass in `04 §4`. Workable, but the denormalised flag turns 2 queries into 1.

### 3.2 A "has-Problem" flag at the Customer Order level

`04 §4` introduces the *attention* filter — "Customer Orders with ≥ 1 Problem task". In the old model that was a `wm_order.has_problem_task` Business Rule. In the new model the same flag lives on `wm_customer_order` and the maintenance rule is mildly more complex:

- On `wm_task` insert/update: walk up `rfs_order → customer_order`, recompute the Customer Order's `has_problem_task` based on whether *any* task on *either* RFS is `Problem`.
- On `wm_rfs_order` delete (rare): re-evaluate.

The payoff is the same — the matrix's `attention` query becomes a single encoded query (`has_problem_task=true`) instead of a collect-then-filter pass. Worth it as soon as the dataset exceeds a few hundred Customer Orders.

### 3.3 RFS-level rollup as a stepping stone

If you don't want to maintain a flag on the Customer Order directly, an intermediate option is `wm_rfs_order.has_problem_task` (cheap — only depends on the RFS's own tasks). The matrix attention query then becomes:

```sql
SELECT DISTINCT co.uuid
FROM   wm_customer_order co
JOIN   wm_rfs_order      rfs ON rfs.customer_order = co.uuid
WHERE  rfs.has_problem_task = true;
```

One join, no fold, no two-pass. Trades a tiny bit of duplication for a clean query path. This is the recommended starting point if a single Business Rule maintaining the CO-level flag feels brittle.

## 4. GlideScript reference — paginated matrix on the new model

Drop-in replacement for the body of `03 §2`. The structure is unchanged from `04 §3.3` — only the table/field names move.

```javascript
(function process(request, response) {
    var list   = request.queryParams.list   || 'legacy';
    var limit  = clampInt(request.queryParams.limit,  25, 1, 200);
    var offset = clampInt(request.queryParams.offset, 0,  0);

    // --- attention filter: collect Customer Order uuids with ≥ 1 Problem task
    var filterEncodedQuery = '';
    if (list === 'attention') {
        // If you've added wm_rfs_order.has_problem_task, this is one encoded
        // query: 'rfs_order.has_problem_task=true' on wm_customer_order via dot-walk.
        // The two-pass version below is the model-agnostic fallback.
        var problemTaskGR = new GlideRecord('wm_task');
        problemTaskGR.addQuery('state', 'Problem');
        problemTaskGR.query();
        var coIds = {};                       // dedup
        while (problemTaskGR.next()) {
            var rfsId = problemTaskGR.getValue('rfs_order');
            var rfsGR = new GlideRecord('wm_rfs_order');
            if (rfsGR.get(rfsId)) {
                coIds[rfsGR.getValue('customer_order')] = true;
            }
        }
        filterEncodedQuery = 'uuidIN' + Object.keys(coIds).join(',');
        // Empty list → 'uuidIN' (no value) matches no rows → total=0, rows=[].
    }

    // --- total
    var counter = new GlideAggregate('wm_customer_order');
    if (filterEncodedQuery) counter.addEncodedQuery(filterEncodedQuery);
    counter.addAggregate('COUNT');
    counter.query();
    var total = counter.next() ? parseInt(counter.getAggregate('COUNT'), 10) : 0;

    // --- page of Customer Orders
    var coGR = new GlideRecord('wm_customer_order');
    if (filterEncodedQuery) coGR.addEncodedQuery(filterEncodedQuery);
    coGR.orderByDesc('number');
    coGR.chooseWindow(offset, offset + limit, true);
    coGR.query();

    var orders   = [];
    var pageIds  = [];
    while (coGR.next()) {
        var row = serialiseCustomerOrder(coGR);
        row.tasks = {};
        orders.push(row);
        pageIds.push(coGR.getValue('uuid'));
    }

    // --- batched task fetch — one query, joined to wm_rfs_order via dot-walk
    if (pageIds.length > 0) {
        var taskGR = new GlideRecord('wm_task');
        taskGR.addEncodedQuery('rfs_order.customer_orderIN' + pageIds.join(','));
        taskGR.query();
        var tasksByCo = {};
        while (taskGR.next()) {
            var coId = taskGR.getDisplayValue('rfs_order.customer_order') || taskGR.rfs_order.customer_order + '';
            var name = taskGR.getValue('short_description');     // canonical key
            (tasksByCo[coId] = tasksByCo[coId] || {})[name] = taskGR.getValue('state');
        }
        orders.forEach(function (o) { o.tasks = tasksByCo[o.uuid] || {}; });
    }

    return { total: total, offset: offset, limit: limit, columns: getTaskColumns(), rows: orders };
})(request, response);
```

Two GlideScript-specific notes:

- **Dot-walk on the encoded query** — `'rfs_order.customer_orderIN' + ids` traverses the reference fields. SNOW resolves this server-side; you don't write any join code. Same idea you'd use for `caller_id.department`-style queries.
- **Getting the FK value back** — `taskGR.getValue('rfs_order')` returns the RFS sys_id (one hop), but you want the *Customer Order* uuid (two hops). Either fetch the RFS in a side-map (`rfsId → coUuid`) once at the start of the page assembly, or use the dot-walked `getDisplayValue` as above. The side-map version is more explicit and faster for large pages.

## 5. Drilldown endpoints

The contract from `01 §B.3 / §B.4` is replaced by three endpoints. Use the same Scripted REST patterns; only the join paths change.

| Endpoint | Old | New |
|---|---|---|
| Single record | `GET /api/work-orders/:sysId` | `GET /api/customer-orders/:uuid` — returns the CO plus both nested RFS plus the flattened task list |
| RFS detail | *(did not exist)* | `GET /api/rfs-orders/:sysId` — returns the RFS, its tasks, and the parent Customer Order |
| Single task | `GET /api/work-orders/:sysId/tasks/:taskName` | `GET /api/customer-orders/:uuid/tasks/:taskName` — resolves through both RFS so the caller never picks a side |

Reference implementations in [server/routes/customer-order.ts](../server/routes/customer-order.ts), [server/routes/rfs-order.ts](../server/routes/rfs-order.ts), and [server/routes/task.ts](../server/routes/task.ts).

## 6. Migration considerations (not in scope for the port, but worth seeing once)

If the SNOW instance already has data in the legacy `wm_order` / `wm_task` tables:

- **Lift `wm_order` rows into `wm_customer_order` 1:1.** The legacy commercial fields (customer, address, status_code) carry over unchanged; `order_date`, `phone`, `scheduled_appointment` are new and start NULL until backfilled.
- **For each legacy `wm_order`, create two `wm_rfs_order` rows** — one LMA, one Connectivity. The RFS numbering scheme (`RFS00200NN`) and Customer Order numbering (`CO-26-XXXX-XXXX`) are independent of any legacy number; you're not renaming records, you're creating a layer above them.
- **Repoint `wm_task.rfs_order`** based on `short_description`: `ONT` → the Connectivity RFS, everything else → the LMA RFS. This is a deterministic rule for the demo dataset; the production rule needs validation against any edge-case task names not in the 17-task registry.

Field-rename mappings if you keep the legacy tables physically and rewrite via views instead of a hard migration:

| Legacy | New |
|---|---|
| `wm_order` | `wm_customer_order` |
| `wm_order.sys_id` | `wm_customer_order.uuid` |
| `wm_order.number` ( `ORDNNNNNNN`) | `wm_customer_order.number` (`CO-YY-XXXX-XXXX`) — different format, plan customer-comms accordingly |
| `wm_task.work_order` | `wm_task.rfs_order` (transitively reaches the CO) |

## 7. Self-check (extends `04 §7`)

In addition to the questions in `04 §7`:

1. **Trace one paginated request on the new model.** `list=legacy`, `limit=10`, `offset=10`: how many DB round-trips, and what does each return?
2. **Where does the `attention` filter's "≥1 Problem task" condition cross schema layers?** Name the cheapest invariant you could maintain to make it a single-pass query.
3. **A bug report says `task-detail-tab` always shows "LMA RFS" in the subtitle even for the ONT task.** Where do you check first — the API, the denormalised `rfs_type` column, or the component? Justify your order.
4. **The seed generator routes `ONT` to the Connectivity RFS based on `short_description`. What's the fragility here, and what would you add to make it self-healing if a new task name is added later?**

## Open questions to send back

- Does the SNOW instance prefer dot-walked encoded queries (`rfs_order.customer_orderIN…`) or explicit nested GlideRecord lookups for two-hop references?
- Is there a SNOW-standard pattern for "denormalised flag with a Business Rule guardian" (e.g. for `wm_task.rfs_type`)? If yes, follow it rather than the manual setter sketched above.
- Should the Customer Order's `status_code` be derived from the two RFS states (rollup), or owned independently? The demo treats it as independent because the legacy seed already populated it.
