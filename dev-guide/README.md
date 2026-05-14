# Developer Guide — HFS Status Matrix

Documentation aimed at the ServiceNow developer who will port the components into a Now Experience workspace.

Read in this order.

| # | Doc | What it gives you |
|---|---|---|
| 1 | [02-developer-onboarding.md](02-developer-onboarding.md) | Hands-on path from zero to "I get it" in about an hour. Try the live demo, run it locally, use it as a reference oracle while you port. |
| 2 | [01-api-specification.md](01-api-specification.md) | The full contract — custom-element API, REST endpoints with JSON schemas, CSS token contract, porting steps, reference data. |

If you've never seen the demo, start with [02](02-developer-onboarding.md) — it's faster than reading the spec cold. Come back to [01](01-api-specification.md) when you're writing code and need an authoritative reference.

## Quick links

- **Live demo:** <https://hfs-demo.biztechbridge.com> (creds via project lead)
- **Source code:** <https://github.com/sven-divico/hfs-demonstrator>
- **Project lead:** sven.s0042@gmail.com

## What you'll be porting

```
4 plain-JS Web Components  +  4 REST endpoints  +  1 task registry  =  the deliverable
```

Demo backend (Node + Fastify + SQLite) is **throwaway** — you replace it with Scripted REST APIs against the live `wm_order` / `wm_task` tables. The components, the JSON shapes, and the task-column registry **stay** as-is in your SNOW component.
