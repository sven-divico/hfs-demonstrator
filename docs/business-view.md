# Business View — One Customer Order, two RFS work orders

**Audience:** business analysts, customer-operations leads, anyone who has been confused by why a single "order" suddenly has two IDs in the SNOW back-end.
**Companion docs:** [demo-data-stories.md](demo-data-stories.md) (what the 25 demo rows mean), [wo-task-status-matrix-demonstrator.md](wo-task-status-matrix-demonstrator.md) (the matrix concept).

---

## The conflict

The HFS rollout sits on top of two worlds that disagree about what an "order" is.

**The TMF Open API world** that our IT and integrations team works in. Following SID guidelines, a customer service request is decomposed into two **Resource-Facing Service** (RFS) work orders:

- **LMA** — Last-Mile Access. Owns the 16 civil-works and infrastructure tasks: house visits, GIS planning, permits, civil works (Tiefbau), splicing, garden drilling, wall breakthrough, HÜP, GFTA, patch.
- **Connectivity** — owns the single ONT install task that activates the customer's line.

This split is the right model for IT — it lets the LMA team and the activation team plan, dispatch, and bill against their own backlog. It also keeps the data model TMF-compliant for downstream integrations.

**The business world.** Customer-operations, sales, and the dispatcher don't think in RFS at all. They think:

> *"I have one customer order. What's the status?"*

When they open a SNOW workspace and see two records — `RFS0020001` and `RFS0020026` — both labelled "Test1 Customer · Willbecke 12", they reasonably ask: *which one is "the" order?* The honest answer ("both, plus neither, because there's an implicit grouping above them") is exactly the kind of TMF detail the business should never have to learn.

That gap is what this demonstrator now closes.

## The resolution — Customer Order as the business façade

We introduce a third entity that sits **above** the two RFS records:

```
wm_customer_order                    ← the business-facing record
  number = CO-26-XXXX-XXXX             (pronounceable in pairs over the phone)
  customer, address, phone, appointment, …
  │
  ├── wm_rfs_order (LMA)             ← 16 infrastructure tasks
  └── wm_rfs_order (Connectivity)    ← 1 task: ONT
        └── wm_task (17 tasks total, flattened in the UI)
```

The Customer Order carries everything a non-technical user cares about — the customer name, the address, the appointment date, the construction status — and aggregates the work happening underneath. The two RFS records stay exactly where TMF wants them, but they become **a one-click-deep detail** rather than a primary surface.

### What you see at each level

| Surface | What it shows | Who it's for |
|---|---|---|
| **Matrix** (Legacy Orders list) | One row per Customer Order, with the 17 tasks as columns. First column is `CO-26-XXXX-XXXX`. | Dispatcher scanning for problems |
| **Customer Order tab** (the merged page) | Customer header, both RFS pills side-by-side, flattened 17-task list with an `LMA` / `Connectivity` tag on each row. "Schedule Appointment" button. | Customer-operations, account managers, anyone speaking to a customer |
| **RFS tab** (one click deeper) | Single RFS record with only its own tasks. Breadcrumb back to the Customer Order. | IT, dispatcher, anyone needing to act on one side of the split |
| **Task tab** (one click deeper still) | Single task with all details. Header shows the Customer Order; small grey text identifies the owning RFS for the technician. | Technician working a single task |

### What's deliberately hidden

The matrix never shows `RFS0020001` / `RFS0020026`. It never shows the LMA/Connectivity split. The flat 17 tasks read as one workflow even though they belong to two RFS records under the hood. Tab labels say `CO-26-…`, never `LMA RFS …` or `Connectivity RFS …` — that detail surfaces only inside the Customer Order tab once the user explicitly drills in.

## Customer Order Reference format

`CO-26-XXXX-XXXX`

- `CO` — Customer Order prefix
- `26` — year of the order (2026)
- two groups of 4 characters in **Crockford base32** (omits `I`, `L`, `O`, `U` to avoid confusion with `1`, `0`, and obscenities)

Examples from the demo: `CO-26-7T4K-NM9P`, `CO-26-RT63-PVH7`, `CO-26-ZF2D-J8KH`.

The format is designed to be **pronounceable in pairs over the phone** — a service-desk agent reading "Customer order C-O dash twenty-six dash seven tango four kilo dash november mike niner papa" stays sane. Spelling is unambiguous because the omitted characters can't appear.

A separate stable identifier (`co-0010001` style) is used in URLs and database joins — the human-readable number is never the join key. This is conventional for ServiceNow records and lets the human number be reassigned later if needed (e.g. correcting a typo'd year) without breaking links.

## The "Schedule Appointment" button — demo behaviour

The Customer Order tab shows a primary action: **Schedule Appointment**. Its purpose is to anchor the conversation about how customer-operations would actually book the technician visit.

| State | Visual | Behaviour |
|---|---|---|
| No appointment booked | Solid teal button, label "Schedule Appointment" | Click triggers a toast: *"Demo only — would open the scheduling flow"*. No actual action. |
| Appointment already set | Greyed-out, label "Appointment scheduled", tooltip with the date/time | Disabled — the operator can't accidentally double-book. |

This is one of the few business-process decisions hard-coded in the demonstrator. Worth confirming: is this the right place for the booking trigger, or should it live elsewhere (sales hand-off, technician self-schedule, automated based on tasks reaching a state)?

## Open questions for business

These are the conversations the demonstrator is meant to provoke:

1. **Is `CO-26-XXXX-XXXX` the right format for the customer-facing reference?** Alternatives: `CO/26/####`, fully numeric `9-digit` like SAP, or align with an existing sales-order numbering scheme.
2. **Where does the Customer Order originate?** Is it the same as a sales order in the CRM, or is it created at the point of provisioning? The answer shapes who's authoritative for the customer name and address fields.
3. **What's the lifecycle of the Customer Order vs the RFS orders?** When the LMA RFS finishes but Connectivity is still open, is the Customer Order "active" or "partially complete"? Today the demo just inherits `construction_status` from the legacy seed — production needs a deliberate rule.
4. **Who owns the Schedule Appointment action?** Customer-operations? Sales? The technician via a self-service link sent to the customer?
5. **Should the RFS pills be visible at all on the Customer Order tab?** Argument for: transparency, lets a dispatcher hop straight to one side. Argument against: every visible IT detail is a future support-ticket question from a confused operator. The demo shows them; production might collapse them under an "Advanced" toggle.

## TL;DR for stakeholders walking up cold

> The technical world splits each order into LMA + Connectivity for compliance reasons. The business world does not need to know that. The demonstrator puts a **Customer Order** layer on top — one record, one reference number, one screen — and pushes the technical split one click deep. Business users get a coherent single pane of glass; IT keeps a TMF-compliant data model underneath.
