# Work Order Task Status Matrix — Demonstrator

## Goal

Provide a single, at-a-glance view that answers:
> *For a given Work Order, what is the current status of each of its Work Order Tasks?*

Each Work Order (WO) carries a fixed set of ~17 tasks — List is detailed below — each with its own lifecycle state. Today, a dispatcher or field coordinator must open each task individually to get the full picture. The demonstrator collapses that into one pivot table:

| Work Order | HV-S | UV-S | HV-NE4 | GIS Planung |...|
|---|---|---|---|---|---|
| WO0001001 | Closed | In Progress | Pending | … |… |
| WO0001002 | Closed | Closed | In Progress | … |… |

**Discussion objective:** Validate with business whether this matrix view is the right mental model, agree on the task names/sequence, and decide on the target surface (report, dashboard widget, or embedded list view).
Agree on click path to further drill down or take action on work order or task level

---

## Tasks
The follwoing tasks can exist for one top level work order

HV-S	UV-S	HV-NE4	UV-NE4	GIS Planung	Fremdleitungsplan	Genehmigungen	Tiefbau	Spleißen	Einblasen	Gartenbohrung	Hauseinführung	HÜP	Leitungsweg NE4	GFTA	ONT	Patch

## Task Live cycle

Tasks are created based on the connnection status of a given address. The driving idea is that only tasks are created that still need execution. example: if tubes are already connecting DP and HÜP, no garden drilling or Hauseinführung is required. The logic for this is outside this demonstrator. If the technician runs onto a problem, he created a fallout task, on the board this is indicated via status 'Problem'. If the field service has created an appointment for a house visit task, it's indicated via status Scheduled.

not applicable
Work In Progress
Assigned
Scheduled
Pending Dispatch
Draft
Problem
Done

## Approach

### Data model

- **`wm_order`** — Work Order header (number, customer, state, …)
- **`wm_task`** — Work Order Tasks, linked to `wm_order` via the `work_order` field
- Key fields on `wm_task`: `short_description` (task name), `state` (integer code + display value)

### Pivot strategy

Because task names are known and stable, the pivot is done in a server-side script:

1. Collect the distinct task names once (column headers).
2. Iterate Work Orders; for each WO query its tasks and map `task name → state display value`.
3. Pre-fill missing task slots with `—` (task not yet created on that WO).

### Delivery options — to discuss with business

| Option | Effort | Flexibility |
|---|---|---|
| **Cross-Tab Report** (out-of-box) | Low | Limited styling, no drill-down |
| **UI Page** with scripted HTML table | Medium | Full control, embeddable |
| **Service Portal Widget** | Medium–High | Best UX, mobile-friendly |
| **Scripted REST API → external dashboard** | High | Max flexibility, outside SNOW |

**Recommended starting point:** UI Page or Cross-Tab Report for the first discussion round — zero risk, quick to iterate on column set and status labels.

---

## JavaScript Snippet (Server-Side GlideRecord)

```javascript
(function buildWorkOrderMatrix() {

    // ── Step 1: Collect distinct task names → column headers ──────────────
    var taskNames = [];
    var nameGR = new GlideRecord('wm_task');
    nameGR.orderBy('short_description');
    nameGR.query();
    while (nameGR.next()) {
        var n = nameGR.getValue('short_description');
        if (taskNames.indexOf(n) === -1) taskNames.push(n);
    }

    // ── Step 2: Build one row per Work Order ──────────────────────────────
    var matrix = [];
    var woGR = new GlideRecord('wm_order');
    woGR.orderBy('number');
    woGR.query();

    while (woGR.next()) {
        var row = { wo_number: woGR.getValue('number') };

        // Pre-fill all task columns with a placeholder
        taskNames.forEach(function (t) { row[t] = '—'; });

        // Fetch tasks for this Work Order and fill actual statuses
        var taskGR = new GlideRecord('wm_task');
        taskGR.addQuery('work_order', woGR.getUniqueValue());
        taskGR.query();
        while (taskGR.next()) {
            var taskName = taskGR.getValue('short_description');
            row[taskName] = taskGR.getDisplayValue('state'); // e.g. "Pending", "In Progress", "Closed"
        }

        matrix.push(row);
    }

    // Returns: { columns: [...taskNames], rows: [...rowObjects] }
    return { columns: taskNames, rows: matrix };

})();
```

### Notes & open points

- **Table names** — confirm `wm_order` / `wm_task` are correct for this instance (check *System Definition → Tables* if scoped app uses a prefix).
- **Link field** — `work_order` on `wm_task` assumed; may be `parent` on older releases.
- **State values** — using `getDisplayValue('state')` returns the label; swap for `getValue('state')` if you need the integer code for colour-coding.
- **Scope / ACLs** — script must run in the correct application scope; confirm with SNOW admin.
- **Performance** — for large WO volumes add `setLimit()` or scope the query with a date/state filter before demoing.

---

## Open Questions for Business Discussion

1. Which task names are canonical? Is the list static or does it vary by order type?
The list is static. if a task is required or not is driven by the connection status

2. Should the view show *all* Work Orders or be filtered (e.g. active only, by region)?
2nd iteration shall address filtering, 1st pass shows open work orders
smart filtering on "work orders requiring attention" will liekely be of big benefit


3. Is drill-down into a specific task required from the matrix view?
Drill down is required, let's discuss UX options as we proceed 

4. What is the primary consumer — dispatcher, field manager, or reporting/BI?
Consumer is the order manager and dispatcher, he must react if tasks are stuck

5. Are colour-coded states (traffic-light) important for the MVP?
Yes, colour coding will be important to engage with business and to have a compact data representation
