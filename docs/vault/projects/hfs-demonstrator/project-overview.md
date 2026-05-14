# HFS-Demonstrator — Project Overview

**Status:** Kickoff — initial inputs collected under `docs/` (HFS-Screens.docx, NAS_Task Decomposition_V2.xlsx, ORD0001472.xlsx, mockup.png, wo-task-status-matrix-demonstrator.md). No code yet.
**Goal:** Demonstrator for a Work Order Task Status Matrix — collapse the per-task drill-down into a single pivot view answering *"for a given WO, what is the status of each of its ~17 tasks?"*

---

## Concept

Pivot table (one row per Work Order × one column per task type) over `wm_order` / `wm_task`. ~17 known task names (HV-S, UV-S, HV-NE4, UV-NE4, GIS Planung, Fremdleitungsplan, Genehmigungen, Tiefbau, Spleißen, Einblasen, Gartenbohrung, Hauseinführung, HÜP, Leitungsweg NE4, GFTA, ONT, Patch). Task lifecycle states: not applicable, Work In Progress, Assigned, Scheduled, Pending Dispatch, Draft, Problem, Done.

**Discussion objective:** Validate the matrix mental model with business, agree on task names/sequence, decide target surface (report, dashboard widget, embedded list view), and define drill-down click path.

## Inputs in `docs/`

- `wo-task-status-matrix-demonstrator.md` — concept brief
- `HFS-Screens.docx` — screen designs
- `NAS_Task Decomposition_V2.xlsx` — task decomposition
- `ORD0001472.xlsx` — example order data
- `mockup.png` — UI mockup

## Open Questions

- Target surface: ServiceNow report, dashboard widget, or embedded list view?
- Source of truth for task name list + sequence (matches the 17 above?)
- Drill-down behavior at WO and task level
- Refresh cadence (live vs. scheduled materialization)

## Related Files

- GitHub repo: <https://github.com/sven-divico/hfs-demonstrator>
- `docs/superpowers/specs/2026-05-14-hfs-demonstrator-design.md` — approved design
- `docs/superpowers/plans/2026-05-14-hfs-demonstrator.md` — implementation plan
- `HANDOVER.md` — SNOW developer handover doc
- `docs/vault/session-logs/` — session history
- `docs/vault/daily-notes/` — daily journal
