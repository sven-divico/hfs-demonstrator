# HFS Demonstrator

A read-only UX prototype of the Work Order Task Status Matrix, packaged as a single Docker container.

Built as a handover artifact for the ServiceNow developer who will port the four Web Components into a Now Experience custom component. See [`dev-guide/`](dev-guide/) for the full developer guide.

---

## Run locally

```bash
npm install
DB_PATH=./data/hfs.sqlite npm run reseed
DB_PATH=./data/hfs.sqlite npm start
# open http://localhost:8080/
```

---

## Run in Docker

```bash
docker compose up --build -d
# open http://localhost:8080/
```

---

## Reseed (local)

After editing `db/seed.sql`:

```bash
DB_PATH=./data/hfs.sqlite npm run reseed
```

To regenerate the SQLite file from scratch, delete `./data/hfs.sqlite` first.

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
├── dev-guide/       # Developer-facing handover docs
├── Dockerfile
└── docker-compose.yml
```

---

## Deployment

This demonstrator is deployed to a private URL; the hosting configuration and credentials live outside this repository. Ask the project lead for access to the running instance.
