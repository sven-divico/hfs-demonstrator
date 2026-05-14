# HFS Demonstrator Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a read-only UX prototype of the Work Order Task Status Matrix; deliver a Docker-packaged web app on `hfs-demo.biztechbridge.com` plus four reusable custom elements that the ServiceNow developer can port directly.

**Architecture:** Single Docker container (Node 22 + Fastify + better-sqlite3) serves a REST API and static frontend; four Web Components (`<wo-status-matrix>`, `<tab-strip>`, `<wo-detail-tab>`, `<task-detail-tab>`) compose the workspace UX; host-native Caddy on `***REDACTED-IP***` terminates TLS and gates with Basic auth.

**Tech Stack:** Node 22, TypeScript, Fastify, better-sqlite3, vanilla Web Components, host-native Caddy, Docker Compose.

**Spec:** [`docs/superpowers/specs/2026-05-14-hfs-demonstrator-design.md`](../specs/2026-05-14-hfs-demonstrator-design.md)

**Verification approach:** Per spec §13, no automated test infrastructure. Each task ends with a smoke-check command (curl, page load) with expected output stated explicitly. Use @superpowers:verification-before-completion before claiming a step done.

---

## Chunk 1: Project scaffolding & git

### Task 1.1: Initialize repo and gitignore

**Files:**
- Create: `.gitignore`, `README.md`

- [ ] **Step 1: `git init` and set default branch to `main`**

```bash
cd /Users/svenschuchardt/repos/HFS-Demonstrator
git init -b main
```

- [ ] **Step 2: Write `.gitignore`**

```
node_modules/
dist/
data/
*.sqlite
.env
.env.*
.DS_Store
.superpowers/
/tmp/
```

- [ ] **Step 3: Write `README.md` skeleton**

Sections: Overview (1 line + link to spec), Run locally, Deploy, Reseed, Project layout. Use spec §9 as source. Skip content for "Deploy" subsection — placeholder pointing to Task 6.3.

- [ ] **Step 4: Stage and commit existing docs + scaffolding**

```bash
git add .gitignore README.md docs/
git commit -m "chore: init repo with spec and plan"
```

Expected: `main` branch created with one commit containing the spec, plan, vault, and `.gitignore`.

### Task 1.2: Node project skeleton

**Files:**
- Create: `package.json`, `tsconfig.json`

> **Language note:** Server-side code is TypeScript executed via `tsx`. Frontend custom elements are **plain JavaScript** files (`.js`) served directly to the browser — no client build step. The SNOW developer's Now Experience component has its own build pipeline, so source-level TS in the browser would add tooling without value. See Chunk 5.

- [ ] **Step 1: Write `package.json`**

```json
{
  "name": "hfs-demonstrator",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "tsx watch server/index.ts",
    "start": "tsx server/index.ts",
    "reseed": "tsx scripts/reseed.ts"
  },
  "dependencies": {
    "fastify": "^5.0.0",
    "@fastify/static": "^8.0.0",
    "better-sqlite3": "^11.3.0"
  },
  "devDependencies": {
    "@types/node": "^22.7.0",
    "tsx": "^4.19.0",
    "typescript": "^5.6.0"
  }
}
```

- [ ] **Step 2: Write `tsconfig.json`**

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "Bundler",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "resolveJsonModule": true,
    "lib": ["ES2022", "DOM"],
    "types": ["node"]
  },
  "include": ["server/**/*", "scripts/**/*"]
}
```

- [ ] **Step 3: Install deps**

```bash
npm install
```

Expected: `node_modules/` populated, no errors. better-sqlite3 builds a native binding — verify with `node -e "require('better-sqlite3')"` exits 0.

- [ ] **Step 4: Commit**

```bash
git add package.json package-lock.json tsconfig.json
git commit -m "chore: node project skeleton (fastify, better-sqlite3, tsx)"
```

### Task 1.3: Docker scaffolding

**Files:**
- Create: `Dockerfile`, `docker-compose.yml`, `.dockerignore`

- [ ] **Step 1: Write `Dockerfile`**

```dockerfile
FROM node:22-alpine

# better-sqlite3 needs build tools at install time
RUN apk add --no-cache python3 make g++

WORKDIR /app

# Install deps separately for layer caching
COPY package*.json ./
RUN npm ci --omit=dev

# App sources
COPY tsconfig.json ./
COPY server ./server
COPY scripts ./scripts
COPY db ./db
COPY public ./public

# tsx is needed at runtime (we run TS directly, no build step)
RUN npm install -g tsx@4

ENV NODE_ENV=production
ENV PORT=8080
EXPOSE 8080

CMD ["tsx", "server/index.ts"]
```

- [ ] **Step 2: Write `docker-compose.yml`**

```yaml
services:
  hfs-demo:
    build: .
    container_name: hfs-demo
    ports:
      - "8080:8080"
    restart: unless-stopped
```

- [ ] **Step 3: Write `.dockerignore`**

```
node_modules
.git
.gitignore
docs
README.md
.superpowers
.DS_Store
deploy-to-prod.sh
```

- [ ] **Step 4: Commit (cannot build yet — server/db/public are empty)**

```bash
git add Dockerfile docker-compose.yml .dockerignore
git commit -m "chore: dockerfile and compose for single-container deploy"
```

---

## Chunk 2: Database layer

### Task 2.1: Schema

**Files:**
- Create: `db/schema.sql`

- [ ] **Step 1: Write `db/schema.sql` exactly as spec §5**

```sql
DROP TABLE IF EXISTS wm_task;
DROP TABLE IF EXISTS wm_order;

CREATE TABLE wm_order (
  sys_id              TEXT PRIMARY KEY,
  number              TEXT UNIQUE NOT NULL,
  status_code         INTEGER NOT NULL,
  construction_status TEXT,
  account             TEXT,
  city                TEXT,
  address             TEXT,
  unit_count          INTEGER,
  set_name            TEXT
);

CREATE TABLE wm_task (
  sys_id            TEXT PRIMARY KEY,
  number            TEXT UNIQUE NOT NULL,
  work_order        TEXT NOT NULL REFERENCES wm_order(sys_id),
  short_description TEXT NOT NULL,
  short_code        TEXT NOT NULL,
  state             TEXT NOT NULL,
  assignment_group  TEXT,
  sys_updated_on    TEXT
);

CREATE INDEX idx_task_wo ON wm_task(work_order);
```

- [ ] **Step 2: Commit**

```bash
git add db/schema.sql
git commit -m "feat(db): wm_order and wm_task schema"
```

### Task 2.2: Task column registry

**Files:**
- Create: `public/task-columns.json`

- [ ] **Step 1: Write the 17 canonical task entries**

Use spec §5 task list. Short codes from the mockup (`HV, UV, HV4, UV4, GP, LLD, PM, CV, SP, BF, GD, WB, HÜP, CW4, GFTA, ONT, PCH`). English labels from real ORD0001472 data.

```json
[
  {"name":"HV-S","short":"HV","label":"Standard House Visit","sequence":1},
  {"name":"UV-S","short":"UV","label":"Standard Unit Visit","sequence":2},
  {"name":"HV-NE4","short":"HV4","label":"House Visit NE4","sequence":3},
  {"name":"UV-NE4","short":"UV4","label":"Unit Visit NE4","sequence":4},
  {"name":"GIS Planung","short":"GP","label":"GIS Planning - NAS","sequence":5},
  {"name":"Fremdleitungsplan","short":"LLD","label":"Utility Lines Plan","sequence":6},
  {"name":"Genehmigungen","short":"PM","label":"Permits (VRAO / Aufbruch)","sequence":7},
  {"name":"Tiefbau","short":"CV","label":"Civil Works","sequence":8},
  {"name":"Spleißen","short":"SP","label":"Splicing","sequence":9},
  {"name":"Einblasen","short":"BF","label":"Blow-in Fiber","sequence":10},
  {"name":"Gartenbohrung","short":"GD","label":"Garden Drilling","sequence":11},
  {"name":"Hauseinführung","short":"WB","label":"Wall Breakthrough","sequence":12},
  {"name":"HÜP","short":"HÜP","label":"Install HÜP","sequence":13},
  {"name":"Leitungsweg NE4","short":"CW4","label":"Cable Way NE4","sequence":14},
  {"name":"GFTA","short":"GFTA","label":"Install GFTA","sequence":15},
  {"name":"ONT","short":"ONT","label":"Install ONT","sequence":16},
  {"name":"Patch","short":"PCH","label":"Patch","sequence":17}
]
```

- [ ] **Step 2: Verify it parses**

Run: `node -e "console.log(JSON.parse(require('fs').readFileSync('public/task-columns.json', 'utf8')).length)"`
Expected: `17`

- [ ] **Step 3: Commit**

```bash
git add public/task-columns.json
git commit -m "feat: 17-task canonical registry (name, short, label, sequence)"
```

### Task 2.3: Seed data — orders

**Files:**
- Create: `db/seed.sql`

- [ ] **Step 1: Append schema include**

Start `seed.sql` with `-- This file is applied after schema.sql; safe to run idempotently.` (Schema DROP/CREATE means the seed always re-applies cleanly.)

- [ ] **Step 2: Write 25 `INSERT INTO wm_order` rows**

Map the spec §7 story table to concrete rows. Example for ORD0012867:

```sql
INSERT INTO wm_order VALUES
  ('ord-0012867','ORD0012867',100,'Completed','Test1 Customer','Borken','Willbecke 12',1,'SDU-GFTAL-NE4'),
  ('ord-0012864','ORD0012864',100,'Completed','Test4 Customer','Borken','Willbecke 13',1,'SDU-GFTAL-NE4'),
  -- ... 23 more matching spec §7 story rows
;
```

Use the customer/address/set_name distribution implied by the story table and the XLSX extracts. WO numbers follow the 25-row sequence in spec §7.

- [ ] **Step 3: Sanity-check row count after each save**

```bash
sqlite3 ":memory:" ".read db/schema.sql" ".read db/seed.sql" "SELECT COUNT(*) FROM wm_order;"
```
Expected: `25`

- [ ] **Step 4: Commit orders portion**

```bash
git add db/seed.sql
git commit -m "feat(seed): 25 work orders covering all story patterns"
```

### Task 2.4: Seed data — tasks

**Files:**
- Modify: `db/seed.sql`

- [ ] **Step 1: For each WO, generate task INSERTs**

Per spec §7 applicability rule: for each (status_code, task) pair, look up the NAS ToBe sheet to decide whether the task applies. Tasks marked `unconsidered` for that status code are inserted with `state='not applicable'`; remaining tasks get a state matching the WO's story pattern.

Use `WOT0050001..0050425` as task numbers; `wot-0050001..` as sys_ids. `sys_updated_on` distributed across the last 30 days for tooltip variety.

Every WO gets **all 17 tasks** inserted — non-applicable ones with `state='not applicable'`. Final row count: 25 × 17 = **425 task rows**. This keeps the join trivial and the matrix dense; the frontend renders `—` for `not applicable`.

- [ ] **Step 2: Sanity-check counts**

```bash
sqlite3 ":memory:" ".read db/schema.sql" ".read db/seed.sql" \
  "SELECT COUNT(*) AS tasks, COUNT(DISTINCT work_order) AS wos FROM wm_task;"
```
Expected: `tasks=425, wos=25`

- [ ] **Step 3: Verify all 8 lifecycle states appear**

```bash
sqlite3 ":memory:" ".read db/schema.sql" ".read db/seed.sql" \
  "SELECT state, COUNT(*) FROM wm_task GROUP BY state ORDER BY 2 DESC;"
```
Expected: at least one row each for `Draft`, `Pending Dispatch`, `Assigned`, `Scheduled`, `Work In Progress`, `Done`, `Problem`, `not applicable`.

- [ ] **Step 4: Verify `Problem` rows exist on the "needs attention" stories**

```bash
sqlite3 ":memory:" ".read db/schema.sql" ".read db/seed.sql" \
  "SELECT o.number FROM wm_order o JOIN wm_task t ON t.work_order=o.sys_id WHERE t.state='Problem' GROUP BY o.number;"
```
Expected: at least `ORD0012848`, `ORD0012846`, `ORD0012836`, `ORD0012835` (per spec §7).

- [ ] **Step 5: Commit**

```bash
git add db/seed.sql
git commit -m "feat(seed): ~425 task rows across 25 WOs covering all 8 lifecycle states"
```

### Task 2.5: Database wrapper

**Files:**
- Create: `server/db.ts`

- [ ] **Step 1: Implement**

```typescript
import Database from "better-sqlite3";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";

const DB_PATH = process.env.DB_PATH ?? "/data/hfs.sqlite";
const SCHEMA = resolve("db/schema.sql");
const SEED = resolve("db/seed.sql");

function applySql(db: Database.Database, file: string) {
  const sql = readFileSync(file, "utf8");
  db.exec(sql);
}

export function openDb(): Database.Database {
  const db = new Database(DB_PATH);
  db.pragma("journal_mode = WAL");
  db.pragma("foreign_keys = ON");
  return db;
}

export function rebuildFromSeed(db: Database.Database) {
  applySql(db, SCHEMA);
  applySql(db, SEED);
}
```

- [ ] **Step 2: Reseed script `scripts/reseed.ts`**

```typescript
import { mkdirSync } from "node:fs";
import { dirname } from "node:path";
import { openDb, rebuildFromSeed } from "../server/db.js";

const DB_PATH = process.env.DB_PATH ?? "/data/hfs.sqlite";
mkdirSync(dirname(DB_PATH), { recursive: true });

const db = openDb();
rebuildFromSeed(db);
const orders = db.prepare("SELECT COUNT(*) AS n FROM wm_order").get() as { n: number };
const tasks = db.prepare("SELECT COUNT(*) AS n FROM wm_task").get() as { n: number };
console.log(`Reseeded: ${orders.n} orders, ${tasks.n} tasks at ${DB_PATH}`);
```

- [ ] **Step 3: Verify locally**

```bash
DB_PATH=./data/hfs.sqlite npm run reseed
```
Expected output: `Reseeded: 25 orders, 425 tasks at ./data/hfs.sqlite` and a `data/hfs.sqlite` file appears.

- [ ] **Step 4: Commit**

```bash
git add server/db.ts scripts/reseed.ts
git commit -m "feat(db): better-sqlite3 wrapper and reseed script"
```

---

## Chunk 3: Fastify server & REST API

### Task 3.1: Server bootstrap

**Files:**
- Create: `server/index.ts`, `server/routes/matrix.ts` (stub), `server/routes/work-order.ts` (stub), `server/routes/task.ts` (stub), `server/routes/task-columns.ts`

- [ ] **Step 0: Create empty route stubs so `server/index.ts` can import them**

Each of `server/routes/matrix.ts`, `server/routes/work-order.ts`, `server/routes/task.ts`:

```typescript
import type Database from "better-sqlite3";
import type { FastifyPluginAsync } from "fastify";
export default (_db: Database.Database): FastifyPluginAsync => async (_app) => {};
```

Real bodies arrive in Tasks 3.2–3.4.

- [ ] **Step 1: Implement boot**

```typescript
import Fastify from "fastify";
import fastifyStatic from "@fastify/static";
import { mkdirSync, existsSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { openDb, rebuildFromSeed } from "./db.js";
import matrixRoute from "./routes/matrix.js";
import workOrderRoute from "./routes/work-order.js";
import taskRoute from "./routes/task.js";
import taskColumnsRoute from "./routes/task-columns.js";

const PORT = Number(process.env.PORT ?? 8080);
const DB_PATH = process.env.DB_PATH ?? "/data/hfs.sqlite";

mkdirSync(dirname(DB_PATH), { recursive: true });
const db = openDb();
if (!existsSync(DB_PATH) || db.prepare("SELECT name FROM sqlite_master WHERE type='table' AND name='wm_order'").get() === undefined) {
  rebuildFromSeed(db);
}

const app = Fastify({ logger: true });

app.register(fastifyStatic, { root: resolve("public"), prefix: "/" });
app.register(matrixRoute(db), { prefix: "/api" });
app.register(workOrderRoute(db), { prefix: "/api" });
app.register(taskRoute(db), { prefix: "/api" });
app.register(taskColumnsRoute(), { prefix: "/api" });

app.setErrorHandler((err, req, reply) => {
  req.log.error(err);
  reply.status(500).send({ error: "internal", message: "Internal server error" });
});

app.listen({ port: PORT, host: "0.0.0.0" }).then(() => {
  app.log.info(`hfs-demo listening on :${PORT}`);
});
```

- [ ] **Step 2: Implement `server/routes/task-columns.ts`** — serves the registry via API for parity with the static file (spec §6 requires both)

```typescript
import type { FastifyPluginAsync } from "fastify";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";

export default (): FastifyPluginAsync => async (app) => {
  const columns = JSON.parse(readFileSync(resolve("public/task-columns.json"), "utf8"));
  app.get("/task-columns", async () => columns);
};
```

- [ ] **Step 3: Verify it boots**

```bash
DB_PATH=./data/hfs.sqlite npm start
# in another shell:
curl -s http://localhost:8080/task-columns.json | head -c 80
curl -s http://localhost:8080/api/task-columns | node -e "let d='';process.stdin.on('data',c=>d+=c).on('end',()=>{console.log(JSON.parse(d).length)})"
```
Expected: first 80 chars of the JSON registry, then `17`.

- [ ] **Step 4: Commit**

```bash
git add server/index.ts server/routes/*.ts
git commit -m "feat(server): fastify boot, static, GET /api/task-columns, route stubs"
```

### Task 3.2: Matrix endpoint

**Files:**
- Modify: `server/routes/matrix.ts`

- [ ] **Step 1: Implement**

```typescript
import type Database from "better-sqlite3";
import type { FastifyPluginAsync } from "fastify";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";

type WoRow = { sys_id: string; number: string; status_code: number; construction_status: string; account: string; city: string; address: string; unit_count: number; set_name: string };
type TaskRow = { work_order: string; short_description: string; state: string };

export default (db: Database.Database): FastifyPluginAsync => async (app) => {
  const columns = JSON.parse(readFileSync(resolve("public/task-columns.json"), "utf8"));

  app.get<{ Querystring: { list?: string } }>("/work-orders/matrix", async (req, reply) => {
    const list = req.query.list ?? "legacy";
    if (list !== "legacy" && list !== "attention") {
      return reply.status(400).send({ error: "bad_list", message: `Unknown list '${list}'. Allowed: legacy, attention.` });
    }

    let orderSql = "SELECT * FROM wm_order ORDER BY number DESC";
    if (list === "attention") {
      orderSql = `SELECT DISTINCT o.* FROM wm_order o JOIN wm_task t ON t.work_order = o.sys_id WHERE t.state = 'Problem' ORDER BY o.number DESC`;
    }
    const orders = db.prepare(orderSql).all() as WoRow[];

    const tasksByWo = new Map<string, Record<string, string>>();
    const taskRows = db.prepare("SELECT work_order, short_description, state FROM wm_task").all() as TaskRow[];
    for (const t of taskRows) {
      const m = tasksByWo.get(t.work_order) ?? {};
      m[t.short_description] = t.state;
      tasksByWo.set(t.work_order, m);
    }

    const rows = orders.map(o => ({ ...o, tasks: tasksByWo.get(o.sys_id) ?? {} }));
    return { columns, rows };
  });
};
```

- [ ] **Step 2: Smoke check**

```bash
curl -s "http://localhost:8080/api/work-orders/matrix?list=legacy" | node -e "let d='';process.stdin.on('data',c=>d+=c).on('end',()=>{const j=JSON.parse(d);console.log('rows',j.rows.length,'cols',j.columns.length,'sample',j.rows[0].number,j.rows[0].tasks['HV-S'])})"
```
Expected: `rows 25 cols 17 sample ORD0012867 Done` (or similar based on seed).

```bash
curl -s "http://localhost:8080/api/work-orders/matrix?list=attention" | node -e "let d='';process.stdin.on('data',c=>d+=c).on('end',()=>{console.log(JSON.parse(d).rows.length)})"
```
Expected: `4` (or however many spec §7 marks as Problem-carrying).

```bash
curl -s -o /dev/null -w "%{http_code}\n" "http://localhost:8080/api/work-orders/matrix?list=bogus"
```
Expected: `400`.

- [ ] **Step 3: Commit**

```bash
git add server/routes/matrix.ts
git commit -m "feat(api): GET /api/work-orders/matrix?list=legacy|attention with server-side pivot"
```

### Task 3.3: Work-order detail endpoint

**Files:**
- Modify: `server/routes/work-order.ts`

- [ ] **Step 1: Implement**

```typescript
import type Database from "better-sqlite3";
import type { FastifyPluginAsync } from "fastify";

export default (db: Database.Database): FastifyPluginAsync => async (app) => {
  app.get<{ Params: { sysId: string } }>("/work-orders/:sysId", async (req, reply) => {
    const { sysId } = req.params;
    if (!/^ord-\d{7,}$/.test(sysId)) {
      return reply.status(400).send({ error: "bad_sys_id", message: "sysId must look like 'ord-0012867'" });
    }
    const order = db.prepare("SELECT * FROM wm_order WHERE sys_id = ?").get(sysId);
    if (!order) {
      return reply.status(404).send({ error: "not_found", message: `Work order ${sysId} not found` });
    }
    const tasks = db.prepare("SELECT * FROM wm_task WHERE work_order = ? ORDER BY short_description").all(sysId);
    return { ...order, tasks };
  });
};
```

- [ ] **Step 2: Smoke check**

```bash
curl -s http://localhost:8080/api/work-orders/ord-0012867 | node -e "let d='';process.stdin.on('data',c=>d+=c).on('end',()=>{const j=JSON.parse(d);console.log(j.number, j.tasks.length)})"
```
Expected: `ORD0012867 17`.

```bash
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080/api/work-orders/ord-9999999
```
Expected: `404`.

- [ ] **Step 3: Commit**

```bash
git add server/routes/work-order.ts
git commit -m "feat(api): GET /api/work-orders/:sysId with 400/404 handling"
```

### Task 3.4: Task detail endpoint

**Files:**
- Modify: `server/routes/task.ts`

- [ ] **Step 1: Implement**

```typescript
import type Database from "better-sqlite3";
import type { FastifyPluginAsync } from "fastify";

export default (db: Database.Database): FastifyPluginAsync => async (app) => {
  app.get<{ Params: { sysId: string; taskName: string } }>("/work-orders/:sysId/tasks/:taskName", async (req, reply) => {
    const { sysId, taskName } = req.params;
    if (!/^ord-\d{7,}$/.test(sysId)) {
      return reply.status(400).send({ error: "bad_sys_id", message: "sysId must look like 'ord-0012867'" });
    }
    // Fastify already URL-decodes path params, so taskName is the literal canonical name
    const task = db.prepare("SELECT * FROM wm_task WHERE work_order = ? AND short_description = ?").get(sysId, taskName);
    if (!task) {
      return reply.status(404).send({ error: "not_found", message: `Task '${taskName}' not found on ${sysId}` });
    }
    return task;
  });
};
```

- [ ] **Step 2: Smoke check**

```bash
curl -s "http://localhost:8080/api/work-orders/ord-0012867/tasks/HV-S" | node -e "let d='';process.stdin.on('data',c=>d+=c).on('end',()=>{console.log(JSON.parse(d).state)})"
```
Expected: a valid state string.

```bash
curl -s "http://localhost:8080/api/work-orders/ord-0012867/tasks/Genehmigungen" -w "\n%{http_code}\n"
```
Expected: JSON body + `200`. URL-decoding handles the umlaut path segment for `HÜP` similarly: `curl --data-urlencode` or pre-encoded `H%C3%9CP`.

- [ ] **Step 3: Commit**

```bash
git add server/routes/task.ts
git commit -m "feat(api): GET /api/work-orders/:sysId/tasks/:taskName"
```

---

## Chunk 4: Frontend shell

### Task 4.1: HTML shell

**Files:**
- Create: `public/index.html`

- [ ] **Step 1: Write the shell**

```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>HFS Demo — Workspace</title>
  <link rel="stylesheet" href="/app.css">
  <script type="module" src="/components/tab-strip.js"></script>
  <script type="module" src="/components/wo-status-matrix.js"></script>
  <script type="module" src="/components/wo-detail-tab.js"></script>
  <script type="module" src="/components/task-detail-tab.js"></script>
</head>
<body>
  <header class="topbar">
    <div class="brand">DG</div>
    <nav><span>All</span><span>Favorites</span><span>History</span><span>Workspaces</span></nav>
    <div class="workspace-pill">HFS Demo Workspace ★</div>
  </header>
  <tab-strip>
    <button slot="tab" data-tab-id="matrix" class="active">Legacy Orders</button>
  </tab-strip>
  <main class="workspace">
    <aside class="sidebar">
      <div class="sidebar-section-title">My Lists</div>
      <button class="list-item active" data-list="legacy">Legacy Orders</button>
      <button class="list-item" data-list="attention">Needs Attention</button>
    </aside>
    <section class="content">
      <wo-status-matrix id="matrix-view" data-endpoint="/api/work-orders/matrix" data-list="legacy"></wo-status-matrix>
    </section>
  </main>
  <script type="module" src="/app.js"></script>
</body>
</html>
```

- [ ] **Step 2: Glue script `public/app.js`**

```javascript
// Wires sidebar list buttons to the matrix
document.querySelectorAll(".list-item").forEach(btn => {
  btn.addEventListener("click", () => {
    document.querySelectorAll(".list-item").forEach(b => b.classList.remove("active"));
    btn.classList.add("active");
    const matrix = document.getElementById("matrix-view");
    matrix.setAttribute("data-list", btn.dataset.list);
  });
});
```

- [ ] **Step 3: Smoke check**

Load `http://localhost:8080/` in a browser. Expected: top bar visible, sidebar with two buttons, empty `<wo-status-matrix>` element (renders nothing yet — component not built).

- [ ] **Step 4: Commit**

```bash
git add public/index.html public/app.js
git commit -m "feat(ui): workspace shell — topbar, sidebar, tab-strip slot"
```

### Task 4.2: CSS — Polaris family tokens

**Files:**
- Create: `public/app.css`

- [ ] **Step 1: Write CSS with `--hfs-*` tokens**

Cover: topbar (dark `#1b2734`), workspace-pill, tab-strip styling, sidebar (`#fafbfc` bg, teal `#1f8476` accent on active), content pane, table base styles (`font-size: 11px`, sticky thead, sticky first column via `position: sticky; left: 0; z-index: 1`), status-dot classes:
- `.dot.open` → gray `#9aa5b1` ring (no fill)
- `.dot.scheduled, .dot.wip` → filled `#3b82f6`
- `.dot.done` → filled `#10b981`
- `.dot.pending, .dot.assigned` → filled `#f59e0b`
- `.dot.problem` → filled `#dc2626`
- `.dot.na` → renders as em-dash `—` glyph, no circle

Body font-stack: `"Source Sans 3", -apple-system, BlinkMacSystemFont, "Segoe UI", system-ui, sans-serif`.

- [ ] **Step 2: Smoke check**

Reload `http://localhost:8080/`. Expected: topbar dark blue, sidebar light gray, teal active states, table fonts at 11px, no JS errors in console.

- [ ] **Step 3: Commit**

```bash
git add public/app.css
git commit -m "feat(ui): polaris-family CSS tokens and base layout"
```

---

## Chunk 5: Custom elements

### Task 5.1: `<tab-strip>` element

**Files:**
- Create: `public/components/tab-strip.js`

Per the language note in Task 1.2, custom elements ship as plain JavaScript.

**Event contract** the tab strip relies on (locked here, honored by Tasks 5.2–5.4):

- `wo:open` → `{detail: {woId, woNumber}}`
- `task:open` → `{detail: {woId, woNumber, taskName}}`
- `tab:close` → `{detail: {tabId}}`

- [ ] **Step 1: Implement**

```javascript
class TabStrip extends HTMLElement {
  constructor() {
    super();
    this.tabs = new Map(); // id -> {button, pane}
  }
  connectedCallback() {
    this.attachShadow({ mode: "open" });
    this.shadowRoot.innerHTML = `
      <style>
        :host { display:block; background:#fff; border-bottom:1px solid #d8dde3; }
        nav { display:flex; padding: 0 16px; }
        ::slotted(button[slot=tab]) {
          background:none; border:none; padding:10px 16px; cursor:pointer;
          font-size:13px; color:#5b6770; border-bottom:2px solid transparent;
        }
        ::slotted(button[slot=tab].active) {
          color:#1f8476; border-bottom-color:#1f8476; font-weight:600;
        }
      </style>
      <nav><slot name="tab"></slot></nav>
    `;
    document.addEventListener("wo:open",   e => this.openWoTab(e.detail));
    document.addEventListener("task:open", e => this.openTaskTab(e.detail));
    document.addEventListener("tab:close", e => this.closeTab(e.detail.tabId));

    // delegate clicks on slotted tab buttons
    this.addEventListener("click", e => {
      const btn = e.target.closest("button[data-tab-id]");
      if (btn) this.activate(btn.dataset.tabId);
    });
  }
  activate(tabId) {
    for (const t of this.querySelectorAll("button[slot=tab]")) {
      t.classList.toggle("active", t.dataset.tabId === tabId);
    }
    document.querySelectorAll("[data-tab-pane]").forEach(p => {
      p.hidden = p.dataset.tabPane !== tabId;
    });
  }
  closeTab(tabId) {
    if (tabId === "matrix") return; // matrix tab is non-closeable
    const t = this.tabs.get(tabId);
    if (!t) return;
    t.button.remove();
    t.pane.remove();
    this.tabs.delete(tabId);
    this.activate("matrix"); // fall back to matrix view
  }
  openWoTab({ woId, woNumber }) {
    const id = `wo-${woId}`;
    if (!this.tabs.has(id)) {
      const button = this._mkTabButton(id, woNumber);
      const pane = document.createElement("wo-detail-tab");
      pane.setAttribute("data-wo-id", woId);
      pane.setAttribute("data-wo-number", woNumber);
      pane.setAttribute("data-tab-pane", id);
      document.querySelector(".content").appendChild(pane);
      this.tabs.set(id, { button, pane });
    }
    this.activate(id);
  }
  openTaskTab({ woId, woNumber, taskName }) {
    const id = `task-${woId}-${taskName}`;
    if (!this.tabs.has(id)) {
      const button = this._mkTabButton(id, `${woNumber} · ${taskName}`);
      const pane = document.createElement("task-detail-tab");
      pane.setAttribute("data-wo-id", woId);
      pane.setAttribute("data-wo-number", woNumber);
      pane.setAttribute("data-task-name", taskName);
      pane.setAttribute("data-tab-pane", id);
      document.querySelector(".content").appendChild(pane);
      this.tabs.set(id, { button, pane });
    }
    this.activate(id);
  }
  _mkTabButton(id, label) {
    const b = document.createElement("button");
    b.slot = "tab";
    b.dataset.tabId = id;
    b.textContent = label;
    this.appendChild(b);
    return b;
  }
}
customElements.define("tab-strip", TabStrip);
```

- [ ] **Step 2: Update `index.html` script tags to point at `.js` files**

Verify Task 4.1's `index.html` references end in `.js` (it does); no change needed unless the file was authored with `.ts`.

- [ ] **Step 3: Make the existing static `data-tab-pane` for the matrix view explicit**

In `index.html`, add `data-tab-pane="matrix"` to the `<wo-status-matrix>` element so the `activate("matrix")` fallback works.

- [ ] **Step 4: Smoke check**

Reload page. Expected: tab strip renders with one tab "Legacy Orders" still active. Console shows no errors.

- [ ] **Step 5: Commit**

```bash
git add public/components/tab-strip.js public/index.html
git commit -m "feat(ui): <tab-strip> with wo:open / task:open / tab:close listeners"
```

### Task 5.2: `<wo-status-matrix>` element

**Files:**
- Create: `public/components/wo-status-matrix.js`

- [ ] **Step 1: Implement**

Class with shadow DOM. On `connectedCallback` and on `attributeChangedCallback('data-list')`, fetch `${endpoint}?list=${list}` and render a `<table>`.

Rendering rules:
- Sticky thead and sticky first column (`position: sticky; left:0`)
- First few cells: ORDER (clickable → emits `wo:open` with `{woId, woNumber}`), Status code, City, Address, Construction status
- One cell per column from `data.columns`, content = `<span class="dot ${stateClass}" data-state="${state}" title="${state} (updated ${sys_updated_on})">…</span>`
- **`stateClass` mapping (must match spec §4 status-glyph rule and §8 colour palette):**
  - `Draft` → `open` (gray ring, no fill — per spec §4 "open/draft")
  - `Pending Dispatch`, `Assigned` → `pending` (amber filled)
  - `Scheduled`, `Work In Progress` → `scheduled` (blue filled)
  - `Done` → `done` (green filled)
  - `Problem` → `problem` (red filled)
  - `not applicable` → `na` (renders as `—` glyph; no circle)
- Cell click on a dot dispatches `task:open` with `{woId, woNumber, taskName}` — must include `woNumber` so `<tab-strip>` (Task 5.1) can build the human-readable label and `<task-detail-tab>` (Task 5.4) can show it in its header
- ORDER cell click dispatches `wo:open` with `{woId, woNumber}` — same `woNumber` requirement
- Tooltip uses HTML `title` attribute (good enough for v1; HANDOVER notes that SNOW Polaris uses richer tooltips)
- Construction-status cell uses inline color matching the dot legend

`observedAttributes` returns `['data-list']`.

- [ ] **Step 2: Smoke check**

Reload page. Expected:
- 25 rows render
- All 17 task columns visible
- Status dots show appropriate colors (red dots on ORD0012848 etc.)
- Click "Needs Attention" in sidebar → matrix re-fetches and shows ~4 rows
- Click an ORDER number → tab appears (pane is empty — wo-detail-tab not built yet)
- Click a status dot → tab appears similarly

- [ ] **Step 3: Commit**

```bash
git add public/components/wo-status-matrix.js
git commit -m "feat(ui): <wo-status-matrix> with sticky col/header, status dots, drill-down events"
```

### Task 5.3: `<wo-detail-tab>` element

**Files:**
- Create: `public/components/wo-detail-tab.js`

- [ ] **Step 1: Implement**

Attributes: `data-wo-id`, `data-wo-number`, `data-tab-pane`.

On connect, fetch `/api/work-orders/${woId}`, render:
- Header card: number, customer, address, construction_status, set_name, with a close button (`×`) on the right
- Table of all tasks for this WO: short_description, state, assignment_group, sys_updated_on
- Each task row clickable → dispatches `task:open` with `{woId, woNumber: this.dataset.woNumber, taskName: row.short_description}` (same shape as `<wo-status-matrix>` dispatches)
- Close button click dispatches `tab:close` with `{tabId: this.dataset.tabPane}` so `<tab-strip>` removes both the button and this pane

Shadow DOM styles match the workspace palette.

- [ ] **Step 2: Smoke check**

Click ORD0012867 in matrix. Expected: new tab "ORD0012867" becomes active, pane shows header + 17 task rows. Click a task row → task tab opens.

- [ ] **Step 3: Commit**

```bash
git add public/components/wo-detail-tab.js
git commit -m "feat(ui): <wo-detail-tab> with header + task list and drill-through"
```

### Task 5.4: `<task-detail-tab>` element

**Files:**
- Create: `public/components/task-detail-tab.js`

- [ ] **Step 1: Implement**

Attributes: `data-wo-id`, `data-wo-number`, `data-task-name`, `data-tab-pane`. (All four populated by `<tab-strip>` in Task 5.1 from the `task:open` event detail.)

On connect, fetch `/api/work-orders/${woId}/tasks/${encodeURIComponent(taskName)}`, render:
- Header: `<task-name> on <woNumber>` (both come from attributes — no extra fetch)
- Body fields: state (with matching coloured dot per Task 5.2 mapping), assignment_group, sys_updated_on
- Close button dispatches `tab:close` with `{tabId: this.dataset.tabPane}`

- [ ] **Step 2: Smoke check**

Click a status dot in the matrix. Expected: task-detail tab opens, shows state matching the dot, assignment group, last update. Console clean.

- [ ] **Step 3: Smoke-check Genehmigungen Problem story**

Open `ORD0012848` matrix row, click the `Genehmigungen` (PM) dot. Expected: tab shows state = `Problem`.

- [ ] **Step 4: Commit**

```bash
git add public/components/task-detail-tab.js
git commit -m "feat(ui): <task-detail-tab> showing state, assignment, last-updated"
```

### Task 5.5: End-to-end smoke

- [ ] **Step 1: Click-through script (manual)**

1. Reload `http://localhost:8080/`. Matrix loads with 25 rows.
2. Hover `ORD0012865` row's `Genehmigungen` dot. Tooltip shows state + timestamp.
3. Click `ORD0012865` ORDER cell. New tab opens with WO detail.
4. Switch back to "Legacy Orders" tab. Matrix still there.
5. Click "Needs Attention" sidebar item. Matrix shrinks to Problem-bearing WOs.
6. Click `ORD0012848` → tab opens → click `Genehmigungen` row → task-detail tab opens.
7. Close every tab except Legacy Orders. No leftover panes in DOM (verify in devtools).

- [ ] **Step 2: Final commit if any fixes**

```bash
git add -u && git commit -m "chore: smoke-pass fixes" || echo "no changes"
```

---

## Chunk 6: Handover doc, deploy infrastructure, biztechbridge refactor

### Task 6.1: HANDOVER.md

**Files:**
- Create: `HANDOVER.md`

- [ ] **Step 1: Write the dev-facing doc**

Use spec §10 as the skeleton. Sections:
1. **Custom-element contracts** — copy attribute/event tables from spec §4
2. **API contract** — copy endpoint table from spec §6, framed as "your Scripted REST API must return these JSON shapes"
3. **Portability matrix** — table mapping each `public/` file to its SNOW counterpart
4. **CSS token mapping** — `--hfs-*` → Polaris `--now-*` equivalents (e.g. `--hfs-color-primary` → `--now-color-primary`)
5. **Lookup key reminder** — the `tasks` map in the matrix response is keyed by canonical German task name (`"HV-S"`, `"GIS Planung"`), not `short` or `label`
6. **Known gaps** — copy spec §4 Out-of-Scope list

- [ ] **Step 2: Commit**

```bash
git add HANDOVER.md
git commit -m "docs: HANDOVER.md for the SNOW developer"
```

### Task 6.2: Caddyfile snippet (documentary)

**Files:**
- Create: `Caddyfile.snippet`

- [ ] **Step 1: Write the documentary snippet**

```caddy
# Copy this block into /etc/caddy/Caddyfile on the host. Generate the bcrypt
# password with: caddy hash-password
hfs-demo.biztechbridge.com {
    basicauth {
        demo $2a$14$REPLACE_WITH_BCRYPT_HASH
    }
    reverse_proxy localhost:8080
}
```

- [ ] **Step 2: Commit**

```bash
git add Caddyfile.snippet
git commit -m "docs: caddyfile snippet reference (applied manually on host)"
```

### Task 6.3: Deploy script

**Files:**
- Create: `deploy-to-prod.sh`

- [ ] **Step 1: Mirror biztechbridge/deploy-to-prod.sh**

```bash
#!/usr/bin/env bash
set -euo pipefail
SERVER="***REDACTED-USER***@***REDACTED-IP***"
REMOTE_DIR="/home/***REDACTED-USER***/hfs-demonstrator"
LOCAL_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "→ Syncing source..."
rsync -az --delete \
  --exclude='.git' \
  --exclude='node_modules' \
  --exclude='dist' \
  --exclude='data' \
  --exclude='.DS_Store' \
  --exclude='.env*' \
  --exclude='.superpowers' \
  "$LOCAL_DIR/" "$SERVER:$REMOTE_DIR/"

echo "→ Building & restarting container..."
ssh "$SERVER" bash <<'REMOTE'
set -euo pipefail
cd /home/***REDACTED-USER***/hfs-demonstrator
sudo -n docker compose up --build -d --remove-orphans
sudo -n docker image prune -f
REMOTE

echo "✓ Deployed → https://hfs-demo.biztechbridge.com"
```

- [ ] **Step 2: `chmod +x deploy-to-prod.sh` and commit**

```bash
chmod +x deploy-to-prod.sh
git add deploy-to-prod.sh
git commit -m "chore: deploy script mirroring biztechbridge pattern"
```

### Task 6.4: README — finalize

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Fill in the deploy section** with these subsections

**A. Prerequisites**
- Local: Docker, Node 22, ssh access to `***REDACTED-USER***@***REDACTED-IP***`
- Server: Ubuntu 22.04+, host-native Caddy installed (see one-time setup)
- DNS: A record `hfs-demo.biztechbridge.com → ***REDACTED-IP***`

**B. One-time host setup** (executed once on the server)

```bash
sudo apt update
sudo apt install -y caddy
# Generate the basic-auth password hash:
caddy hash-password
# Append the hfs-demo block to /etc/caddy/Caddyfile (see Caddyfile.snippet for the template)
sudo nano /etc/caddy/Caddyfile
sudo caddy validate --config /etc/caddy/Caddyfile
sudo systemctl reload caddy
```

**C. biztechbridge refactor** — required before the first hfs-demo deploy because biztechbridge currently owns `:80`/`:443`. See [the biztechbridge repo](https://github.com/<owner>/biztechbridge) and Task 6.6 of this plan. After refactor biztechbridge runs on `:8081`.

**D. Per-deploy command**

```bash
./deploy-to-prod.sh
```

**E. Reseed**
- Edit `db/seed.sql` locally → `./deploy-to-prod.sh` (rebuilds image; ~30 s)
- Or on host: `ssh ***REDACTED-USER***@***REDACTED-IP*** 'cd hfs-demonstrator && sudo -n docker compose exec hfs-demo tsx scripts/reseed.ts'` (no image rebuild)

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs: README deploy + reseed instructions"
```

### Task 6.5: Local Docker validation (pre-deploy)

- [ ] **Step 1: Build & run image locally**

```bash
docker compose up --build -d
sleep 5
curl -s http://localhost:8080/api/work-orders/matrix?list=legacy | node -e "let d='';process.stdin.on('data',c=>d+=c).on('end',()=>{console.log('rows',JSON.parse(d).rows.length)})"
```
Expected: `rows 25`.

- [ ] **Step 2: Open `http://localhost:8080/` in browser, repeat Task 5.5 smoke**

Expected: identical behavior to `npm start`.

- [ ] **Step 3: Tear down**

```bash
docker compose down
```

### Task 6.6: biztechbridge refactor (sequenced before first hfs-demo deploy)

**Files:** (in `/Users/svenschuchardt/repos/biztechbridge/`)
- Modify: `Dockerfile`, `docker-compose.yml`

**Note: this touches a live site.** Do this in a separate session/PR on the biztechbridge repo, not bundled with the hfs-demo deploy. Plan a short maintenance window — biztechbridge will briefly 503 between the old container stopping and host Caddy reloading.

**Rollback path:** the previous biztechbridge container image is preserved by `docker image ls`. To revert: `docker compose down`, restore previous Caddyfile from snapshot (Step 3a below), restart the previous container manually on `:80`/`:443`.

- [ ] **Step 1: Change biztechbridge Dockerfile stage 2 to `nginx:alpine` serving `dist/` on container `:80`**

Replace the `caddy:2-alpine` stage with:

```dockerfile
FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
```

Remove the `COPY Caddyfile` line.

- [ ] **Step 2: Change `docker-compose.yml` to publish `8081:80`**

```yaml
services:
  web:
    build: .
    ports:
      - "8081:80"
    restart: unless-stopped
```

Drop `volumes:` (no more `caddy_data` / `caddy_config`) and the `443` mappings.

- [ ] **Step 3a: Snapshot current state**

On server, before any change:
```bash
sudo cp -a /etc/caddy /etc/caddy.bak.$(date +%s) 2>/dev/null || true
docker image ls --format '{{.Repository}}:{{.Tag}} {{.ID}}' | grep biztech > /home/***REDACTED-USER***/biztech-images.before
```

- [ ] **Step 3b: Build and start the refactored biztechbridge container, verify on `:8081` BEFORE touching host networking**

```bash
cd /home/***REDACTED-USER***/biztechbridge
sudo -n docker compose up --build -d --remove-orphans
sleep 3
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8081
```
Expected: `200`. If not — investigate before proceeding; existing biztechbridge container may still be bound to `:80`.

- [ ] **Step 3c: Stop any container still bound to `:80`/`:443`**

```bash
docker ps --format '{{.ID}} {{.Ports}}' | awk '/0.0.0.0:80->/ {print $1}' | xargs -r docker stop
```

- [ ] **Step 3d: Install host Caddy and write `/etc/caddy/Caddyfile`**

```bash
sudo apt update && sudo apt install -y caddy
```

Edit `/etc/caddy/Caddyfile`:
```caddy
biztechbridge.com, www.biztechbridge.com {
    reverse_proxy localhost:8081
}

hfs-demo.biztechbridge.com {
    basicauth { demo $2a$14$<hash> }
    reverse_proxy localhost:8080
}
```

```bash
sudo caddy validate --config /etc/caddy/Caddyfile
sudo systemctl reload caddy
curl -s -o /dev/null -w "%{http_code}\n" https://biztechbridge.com
```
Expected: `200` for biztechbridge after Caddy has issued the cert (first request may take a few seconds).

- [ ] **Step 4: Add DNS A record `hfs-demo.biztechbridge.com → ***REDACTED-IP***`** (external step at your DNS provider)

### Task 6.7: GitHub remote & push

- [ ] **Step 1: Create the GitHub repo** (private or public — your call) under your GitHub account, name `HFS-Demonstrator`. Do NOT initialize it with a README/LICENSE — we already have local commits.

- [ ] **Step 2: Add remote and push**

```bash
git remote add origin git@github.com:<your-username>/HFS-Demonstrator.git
git push -u origin main
```

- [ ] **Step 3: Record the URL** in `docs/vault/projects/hfs-demonstrator/project-overview.md` under "Related Files" so future sessions find it. Commit + push.

### Task 6.8: First hfs-demo deploy

- [ ] **Step 1: Run deploy**

```bash
./deploy-to-prod.sh
```

- [ ] **Step 2: Verify**

```bash
curl -u demo:<password> -s https://hfs-demo.biztechbridge.com/api/work-orders/matrix?list=legacy | node -e "let d='';process.stdin.on('data',c=>d+=c).on('end',()=>{console.log('rows',JSON.parse(d).rows.length)})"
```
Expected: `rows 25`.

Open `https://hfs-demo.biztechbridge.com/` in a browser, log in with basic auth, repeat Task 5.5 smoke checks against production.

- [ ] **Step 3: Tag the release and push**

```bash
git tag -a v0.1.0 -m "First demonstrator deploy"
git push --tags
```

**Rollback if deploy is broken:** `ssh ***REDACTED-USER***@***REDACTED-IP*** 'cd hfs-demonstrator && sudo -n docker compose down'`. The hfs-demo.biztechbridge.com URL will 502 (host Caddy still routes there, but nothing answers on `:8080`) — stakeholders just won't get to the demo until the next deploy. biztechbridge is unaffected.

---

## Final completion checklist

Before declaring done, verify per @superpowers:verification-before-completion:

- [ ] All 25 WOs render in the matrix at `https://hfs-demo.biztechbridge.com/`
- [ ] "Needs Attention" filter returns only Problem-bearing WOs
- [ ] Clicking an ORDER opens a WO-detail tab; clicking a status dot opens a task-detail tab
- [ ] Tooltip on status dot shows state + `sys_updated_on`
- [ ] Sticky first column stays visible during horizontal scroll
- [ ] Basic auth prompt appears; correct password lets through
- [ ] biztechbridge.com still serves correctly
- [ ] `HANDOVER.md` is in the repo root and references all four custom elements
- [ ] GitHub repo (public or private — user's choice) is published; URL noted in `docs/vault/projects/hfs-demonstrator/project-overview.md`

When all boxes are checked, the demonstrator is ready for the first business discussion and the JS handover to the SNOW developer.
