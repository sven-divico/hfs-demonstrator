# Demo Data — Story Catalogue

This document describes the **25 fictional work orders** loaded into the HFS Demonstrator. Each row was chosen to illustrate a specific situation worth discussing — a completed order, an order blocked on permits, an order with multiple problems, etc.

**Use this document to:**

- Decide whether the data is varied enough for the conversations you want to have.
- Request changes (new rows, different status patterns, edge cases) — see the template at the bottom.

**This is not real customer data.** All addresses, customer names, and order numbers are invented. The patterns are designed to look plausible while being safe to share publicly.

---

## What the live demo shows

Open the demonstrator → the matrix lists 25 work orders, one per row, with 17 task columns each:

| Range of order numbers | Address pattern | Notes |
|---|---|---|
| `ORD0012828` – `ORD0012867` | Borken / Willbecke 12–23, Hauptstraße 1–25 | All in one fictional area |

Customer names are `Test1 Customer` through `Test10 Customer`.

---

## The 25 stories

Each row below corresponds to one work order in the demo. The "Story" column says **why** that order exists — what conversation it's designed to support.

| Order | Status | Construction | Address | Story / what this row demonstrates |
|---|---|---|---|---|
| ORD0012867 | 100 | Completed | Willbecke 12 | A fully completed order — all applicable tasks Done. Reference "happy path" row. |
| ORD0012865 | 103 | in progress | Willbecke 15 | Mid-flow order, civil works done, mounting open. |
| ORD0012864 | 100 | Completed | Willbecke 13 | Second completed order — variety in the green band. |
| ORD0012860 | 100 | Completed | Willbecke 14 | Third completed order. |
| ORD0012853 | 103 | in progress | Willbecke 16 | Mid-flow with civil works progressing. |
| ORD0012849 | 103 | in progress | Hauptstraße 5 | Early-flow in-progress order. |
| **ORD0012848** | **108** | **Fallout** | **Hauptstraße 7** | **Blocked on permits — the `Genehmigungen` task is in state `Problem`.** Discussion: how should a dispatcher react to a permit fallout? |
| **ORD0012846** | **108** | **Fallout** | **Hauptstraße 9** | **Civil works stuck — the `Tiefbau` task is in state `Problem`.** |
| ORD0012845 | 101 | Open | Willbecke 17 | Fresh order, all tasks Pending Dispatch. |
| ORD0012844 | 101 | Open | Willbecke 18 | Another fresh order. Includes a `Draft` GIS Planung task (very earliest lifecycle state). |
| ORD0012843 | 102 | in progress | Willbecke 19 | In-progress, scheduled house visit (blue dot = Scheduled). |
| ORD0012842 | 109 | Cancellation in progress | Hauptstraße 11 | Cancellation — most tasks Done, mounting/activation tasks `not applicable`. |
| ORD0012841 | 103 | in progress | Hauptstraße 3 | MDU pattern (multi-dwelling unit). |
| ORD0012840 | 103 | in progress | Hauptstraße 1 | MDU pattern with multiple unit visits. |
| ORD0012839 | 102 | in progress | Willbecke 20 | `Spleißen` (splicing) currently in progress, upstream tasks Done. |
| ORD0012838 | 101 | Open | Hauptstraße 13 | Draft phase — `GIS Planung` still Draft. |
| ORD0012837 | 101 | Open | Hauptstraße 15 | Another Draft-phase order. |
| **ORD0012836** | **103** | **in progress** | **Hauptstraße 17** | **HÜP done, but `Hauseinführung` (wall breakthrough) is in state `Problem`.** |
| **ORD0012835** | **103** | **in progress** | **Hauptstraße 19** | **Two parallel `Problem` tasks — clearly an order that needs attention.** |
| ORD0012834 | 102 | in progress | Hauptstraße 21 | Healthy mid-flow variation. |
| ORD0012833 | 102 | in progress | Hauptstraße 23 | Healthy mid-flow with different set type. |
| ORD0012832 | 105 | in progress | Willbecke 21 | Later-stage in-progress. |
| ORD0012831 | 107 | in progress | Willbecke 22 | Long-tail: only `ONT` and `Patch` left to do. |
| ORD0012830 | 103 | in progress | Hauptstraße 25 | Multi-unit MDU. |
| ORD0012828 | 100 | Completed | Willbecke 23 | Reference "happy path" finished row at the bottom of the list. |

**The four bolded rows** (`ORD0012848`, `ORD0012846`, `ORD0012836`, `ORD0012835`) are the ones that appear in the "**Needs Attention**" sidebar list — they all have at least one task in state `Problem`.

---

## The 17 tasks (column headers)

Each work order can have up to 17 tasks. Their canonical names are German (matching what the SNOW system uses internally); the English label is shown on hover and in detail panes.

| # | German name (column header) | English label |
|---|---|---|
| 1 | HV-S | Standard House Visit |
| 2 | UV-S | Standard Unit Visit |
| 3 | HV-NE4 | House Visit NE4 |
| 4 | UV-NE4 | Unit Visit NE4 |
| 5 | GIS Planung | GIS Planning - NAS |
| 6 | Fremdleitungsplan | Utility Lines Plan |
| 7 | Genehmigungen | Permits (VRAO / Aufbruch) |
| 8 | Tiefbau | Civil Works |
| 9 | Spleißen | Splicing |
| 10 | Einblasen | Blow-in Fiber |
| 11 | Gartenbohrung | Garden Drilling |
| 12 | Hauseinführung | Wall Breakthrough |
| 13 | HÜP | Install HÜP |
| 14 | Leitungsweg NE4 | Cable Way NE4 |
| 15 | GFTA | Install GFTA |
| 16 | ONT | Install ONT |
| 17 | Patch | Patch |

---

## What the colours mean

| Glyph | State | Plain language |
|---|---|---|
| `—` | not applicable | This task isn't required for this order (e.g. no Garden Drilling if the property doesn't need it). |
| ○ (gray ring) | Draft | The task exists but no real planning has started. |
| ● amber | Pending Dispatch / Assigned | Ready to be worked, waiting for a technician. |
| ● blue | Scheduled / Work In Progress | Appointment booked or technician actively working. |
| ● green | Done | Task completed. |
| ● red | Problem | Something blocks completion — technician reported a fallout. |

The construction-status column on the left uses the same colour family: green dot = Completed, blue = in progress, gray = Open / Cancellation, red = Fallout.

---

## Status codes — what each one means

The "Status" column on the left shows a numeric code that drives which of the 17 tasks **apply** to that order.

| Code | What it means (in this demo) |
|---|---|
| 100 | All applicable tasks completed (Completed orders). |
| 101 | Open / Draft — fresh order, early lifecycle. |
| 102 | Early-mid in-progress. |
| 103 | Mid in-progress. |
| 105 | Later in-progress. |
| 107 | Long-tail (mostly Done). |
| 108 | Fallout (something went wrong). |
| 109 | Cancellation. |

In the real system, not every task is created for every order — the status code determines which tasks are skipped. The demo follows the same rule: tasks marked "unconsidered" for a status code show as `—`.

---

## How to request changes

You can suggest changes to this demo data. The reseed cycle is fast (~30 seconds), so iterating on stories between business sessions is cheap.

Please describe each change using **this template**:

```
CHANGE REQUEST — [date]
[bullet-point list of changes; use one bullet per change]

For a NEW order:
  - Order number:        ORD00xxxxx (any free number in the 0012700–0012899 range)
  - Customer:            <Test N Customer> or any other fictional name
  - Address:             <Street name + number> (Borken assumed unless specified)
  - Status code:         100 / 101 / 102 / 103 / 105 / 107 / 108 / 109
  - Construction status: Completed / Open / in progress / Fallout / Cancellation in progress
  - Story (1-line):      what is this row demonstrating?
  - Specific task states (optional): e.g. "Genehmigungen = Problem; everything upstream Done"

For an EXISTING order:
  - Order number:        ORD00xxxxx (one of the 25 above)
  - Change:              what task or attribute changes, and to what new value
  - Reason / story:      what does the new state demonstrate?

For DELETING an order:
  - Order number:        ORD00xxxxx
  - Reason:              why remove it?
```

### Example request

> **CHANGE REQUEST — 2026-05-20**
>
> 1. **New order `ORD0012880`** — Customer `Test11 Customer`, address `Borken / Kirchplatz 4`, status code `108`, Fallout. Story: a *fresh* fallout that has only just been reported (i.e. only one task in `Problem`, nothing else stuck) — to contrast with `ORD0012848` and `ORD0012835` which have aged fallouts.
> 2. **Modify `ORD0012832`** — set `Einblasen` (Blow-in Fiber) to state `Problem`. Story: show that fiber blow-in can also fail, not just civil works and permits.
> 3. **Delete `ORD0012830`** — too similar to `ORD0012841`; not adding new story value.

Email this to the project lead. After the next reseed, the live demo at the demo URL reflects your changes within ~30 seconds.

---

## Frequently asked

**Q: Can we use real customer data?**
No — the demo URL is on a shared host with limited access controls. Stick to invented `Test N Customer` style names and Borken-area addresses.

**Q: Can we change the **task names** (e.g. rename "Genehmigungen" to "Permit Approvals")?**
The German names are deliberately kept because they match what the SNOW system stores. The **English labels** (shown on hover) are free to adjust — request via the template above.

**Q: Can we add more **task types** beyond the current 17?**
Yes, but it's a bigger change — every order has to be re-evaluated against the new task. Please raise this as a separate discussion rather than via the change-request template.

**Q: Can we add more than 25 orders?**
Yes. Up to ~100 is comfortable; beyond that the "demo" framing starts to blur into a load test. If you want the live UI to demonstrate pagination across multiple pages, ~50–60 orders is a sweet spot.

**Q: Where is the data physically stored?**
A small SQLite database file inside the demo container. It is **not** connected to any SNOW environment. Changes to the demo do not affect any real system.
