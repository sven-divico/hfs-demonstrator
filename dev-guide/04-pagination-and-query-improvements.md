# Pagination & Query Improvements

**Audience:** ServiceNow developer porting the matrix endpoint.
**Prereq:** read [03-snow-recipe.md](03-snow-recipe.md). This document is a deeper dive on **how your existing pivot query maps onto the paginated contract** in [01-api-specification.md §B.2](01-api-specification.md#b2-get-apiwork-ordersmatrix).

> **Heads-up — data model has evolved.** The pagination, counting, and `attention`-filter *patterns* in this doc all still apply. The table/field names (`wm_order`, `wm_task.work_order`) describe the *original* 2-table model. Read [05-data-acquisition-after-customer-order.md](05-data-acquisition-after-customer-order.md) for how the same patterns lift onto the 3-table Customer Order → RFS → task model.

Please read carefully. Come back with questions on anything that doesn't sit right.

---

## 1. Where you are now

Your existing pivot (from the original concept doc) walks `wm_order`, and for each WO runs a second query against `wm_task` to fold `(task name, state)` pairs into a row map. Schematically:

```javascript
var woGR = new GlideRecord('wm_order');
woGR.orderBy('number');
woGR.query();
while (woGR.next()) {
    var row = serialiseOrder(woGR);
    row.tasks = {};
    var taskGR = new GlideRecord('wm_task');
    taskGR.addQuery('work_order', woGR.getUniqueValue());
    taskGR.query();
    while (taskGR.next()) {
        row.tasks[taskGR.getValue('short_description')] = taskGR.getValue('state');
    }
    rows.push(row);
}
return { columns: taskColumns, rows: rows };
```

That's an **N+1 pattern**: 1 outer query + N inner queries (one per WO). It works at small scale and produces the right output shape.

## 2. What stays the same

The paginated contract doesn't ask you to rethink the algorithm. These remain identical:

- **The pivot logic** — group by WO, fold `(task name → state)` into a map keyed by the canonical German `short_description` (`"HV-S"`, `"GIS Planung"`, `"HÜP"`, …).
- **The field names** — `wm_order.number`, `wm_task.work_order`, `wm_task.short_description`, `wm_task.state`, etc.
- **The per-row output shape** — every WO row carries the same meta fields plus a `tasks` map.
- **The `columns` array** — read once per request from the canonical registry (`x_company.hfs.task_columns_json`).

The response envelope evolves additively: where your earlier prototype returned `{ columns, rows }`, the paginated version returns `{ total, offset, limit, columns, rows }`. Old fields keep their meaning; new fields can be ignored by any consumer that doesn't care about pagination.

## 3. Three changes you'll make

### 3.1 Window the outer query with `chooseWindow`

GlideRecord exposes paginated reads natively. Replace the unbounded `query()` with:

```javascript
woGR.orderByDesc('number');
woGR.chooseWindow(offset, offset + limit, true);   // [start, end), forceCount=true
woGR.query();
```

`chooseWindow(start, end, forceCount)` reads rows in the half-open range `[start, end)` — `start` is inclusive, `end` is exclusive. So `chooseWindow(0, 25, true)` returns rows 0 through 24 (25 rows), and `chooseWindow(25, 50, true)` returns the next 25.

Pass `forceCount = true` so the row count is materialised — without it, some GlideRecord methods (`getRowCount`) return -1 until you exhaust the iterator.

### 3.2 Compute `total` with `GlideAggregate`

The component renders the pagination footer's "X–Y of Z" label and enables/disables the Next button using `total`. Compute it once per request, before the page query:

```javascript
var counter = new GlideAggregate('wm_order');
counter.addEncodedQuery(filterEncodedQuery);   // same filter your page query uses
counter.addAggregate('COUNT');
counter.query();
var total = counter.next() ? parseInt(counter.getAggregate('COUNT'), 10) : 0;
```

Two notes:

- `getAggregate('COUNT')` returns a **string**, not a number. Wrap with `parseInt(_, 10)` so the response field has the right type — the component reads `total` as a number and compares to `offset + limit`.
- `GlideAggregate` honours the same ACLs as a plain `GlideRecord`. The `total` you return reflects what the calling user can see, which is exactly what you want.

### 3.3 Collapse the N+1 into a single batched task query

This is the most valuable change pagination forces, and it's not strictly about pagination — your existing query did N+1 already. With pagination, the N is bounded by `limit` (max 200 per the contract), so the IN-query stays comfortable.

After you have the page of WO records, gather their sys_ids and run **one** task query:

```javascript
var pageWoIds = orders.map(function (o) { return o.sys_id; });

var taskGR = new GlideRecord('wm_task');
taskGR.addEncodedQuery('work_orderIN' + pageWoIds.join(','));
taskGR.query();

var tasksByWo = {};
while (taskGR.next()) {
    var wo   = taskGR.getValue('work_order');
    var name = taskGR.getValue('short_description');     // canonical German name = map key
    var st   = taskGR.getValue('state');
    (tasksByWo[wo] = tasksByWo[wo] || {})[name] = st;
}

orders.forEach(function (o) { o.tasks = tasksByWo[o.sys_id] || {}; });
```

For 25 WOs per page, this turns **26 round-trips into 2**. The cost of building the `tasksByWo` map in JavaScript is negligible; the cost saved is real DB round-trip latency.

## 4. The `attention` filter — new requirement

The original pivot fetched every order. The contract introduces a query parameter `list=attention` that filters to **WOs with ≥ 1 task in state `Problem`**. There's no direct field on `wm_order` for this — the cheapest pattern is a two-pass collect-then-filter:

```javascript
// Pass 1 — collect WO sys_ids that own at least one Problem task
var problemTaskGR = new GlideRecord('wm_task');
problemTaskGR.addQuery('state', 'Problem');
problemTaskGR.query();
var attentionIds = [];
while (problemTaskGR.next()) {
    var id = problemTaskGR.getValue('work_order');
    if (attentionIds.indexOf(id) === -1) attentionIds.push(id);
}

// Pass 2 — page the WO list, scoped to those sys_ids
woGR.addEncodedQuery('sys_idIN' + attentionIds.join(','));
woGR.orderByDesc('number');
woGR.chooseWindow(offset, offset + limit, true);
woGR.query();
```

When `attentionIds` is empty (no Problem tasks anywhere in the dataset), the encoded query `sys_idIN` with an empty value is interpreted by GlideRecord as **"match no records"** — the WO query naturally returns zero rows. No explicit empty-list check is needed in code, and the response `total` correctly comes out as `0`.

If your dataset has thousands of Problem tasks, pass 1 may get expensive. Mitigations:

- Cache the `attentionIds` list for a few seconds.
- Add a computed field on `wm_order` (e.g. `has_problem_task`) maintained by a Business Rule — turns the two-pass into a single-pass encoded query.

## 5. Page stability — ordering matters

`chooseWindow` returns stable pages **only when the underlying `orderBy` is unique per row**. The WO `number` field is unique by construction (`ORD0012867` etc.), so `orderByDesc('number')` is safe.

If you later support sorting by, say, `construction_status` (not unique — many WOs share `"in progress"`), you'll see rows shuffle between pages on each request. The standard fix is a deterministic tiebreaker:

```javascript
woGR.orderBy('construction_status');
woGR.orderBy('number');                      // unique tiebreaker, applied after
```

Multiple `orderBy` calls compose left-to-right; the final unique field guarantees a deterministic page boundary.

## 6. Putting it together — reference assembly

Read the full reference implementation in [03-snow-recipe.md § 2](03-snow-recipe.md#2-resource-matrix-the-pivot). It folds all three changes plus the `attention` filter into ~70 lines of script. If your version diverges significantly in structure, double-check against that recipe before declaring done.

## 7. Self-check

Before you ping back with questions, work through these. They mirror what we'll smoke-test at handover:

1. **What does `chooseWindow(50, 60, true)` return for a 25-WO dataset?** (Hint: think about both rows-in-range and total.)
2. **Why does `parseInt(getAggregate('COUNT'), 10)` need the explicit radix?** (Hint: leading zeros.)
3. **What happens if your `attention` pass 1 yields an empty list and a user requests page 3** (`offset=50`)? Walk through what `total`, `rows`, and the Prev/Next button states should be.
4. **Sketch the SQL-ish trace of one paginated request** (`list=legacy`, `limit=10`, `offset=10`): how many round-trips to the DB, and what does each one return?
5. **The contract says `total` reflects the row count for the current `list` filter.** Why is it important that the same encoded query is used for both `GlideAggregate` (count) and `GlideRecord` (page)?

If any of these are unclear or you spot something in this document that doesn't square with the recipe, surface it before writing code — better to align the contract early than fix it after a half-built pivot.

---

## Open questions to send back

Add anything that's still ambiguous after reading this doc and the recipe — examples:

- Does the SNOW instance have an existing `has_problem_task` field on `wm_order` we should use?
- Is there a ServiceNow Platform Encoded Query pattern preferred over the two-pass approach for `attention`?
- What's the production page-size expectation (default 25, but is 100 / 200 realistic for your users)?
- Are there ACLs that would cause the `total` returned by `GlideAggregate` to differ from the actual user-visible row count in pagination edge cases?
