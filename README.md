# HFS Demonstrator

A read-only UX prototype of the Work Order Task Status Matrix, packaged as a single Docker container.

**Spec:** [`docs/superpowers/specs/2026-05-14-hfs-demonstrator-design.md`](docs/superpowers/specs/2026-05-14-hfs-demonstrator-design.md)

---

## Run locally

```bash
npm install
DB_PATH=./data/hfs.sqlite npm run reseed
DB_PATH=./data/hfs.sqlite npm start
# open http://localhost:8080/
```

---

## Deploy

See Task 6.4 / spec §11 for full deploy instructions (prerequisites, one-time host setup, biztechbridge refactor, per-deploy command).

_Placeholder — content added in Task 6.4._

---

## Reseed

```bash
# Local:
DB_PATH=./data/hfs.sqlite npm run reseed

# On server (no image rebuild):
ssh ***REDACTED-USER***@***REDACTED-IP*** 'cd hfs-demonstrator && sudo -n docker compose exec hfs-demo tsx scripts/reseed.ts'
```

---

## Project layout

```
.
├── server/          # Fastify server + TypeScript source
│   ├── index.ts     # Boot (DB init, static, routes)
│   ├── db.ts        # better-sqlite3 wrapper
│   └── routes/      # matrix, work-order, task, task-columns
├── scripts/
│   └── reseed.ts    # CLI reseed script
├── db/
│   ├── schema.sql   # DDL for wm_order, wm_task
│   └── seed.sql     # 25 WOs × 17 tasks
├── public/
│   ├── index.html   # Workspace shell
│   ├── app.css      # Polaris-family tokens + layout
│   ├── app.js       # Sidebar wiring
│   ├── task-columns.json  # 17-task canonical registry
│   └── components/  # Four Web Components (plain JS)
├── Dockerfile
├── docker-compose.yml
└── docs/            # Spec, plan, vault
```
