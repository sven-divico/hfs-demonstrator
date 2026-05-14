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

Target: `https://hfs-demo.biztechbridge.com` on `***REDACTED-IP***`.
Architecture: host-native Caddy (TLS + Basic auth) → Docker container on `:8080`.

### A. Prerequisites

**Local machine:**
- Docker (for local validation and image build)
- Node 22 (for local `npm start` / reseed)
- SSH access to `***REDACTED-USER***@***REDACTED-IP***`

**Server (Ubuntu 22.04+):**
- Host-native Caddy installed (see one-time setup below)
- Docker + Docker Compose

**DNS:**
- A record: `hfs-demo.biztechbridge.com → ***REDACTED-IP***`
  (the apex and `www` already point there via existing biztechbridge setup)

### B. One-time host setup

Run once on the server to install Caddy and add the hfs-demo site block:

```bash
sudo apt update
sudo apt install -y caddy

# Generate a bcrypt password hash for Basic auth.
# When prompted, enter the shared demo password. Copy the $2a$... output.
caddy hash-password

# Add the hfs-demo block to the host Caddyfile.
# Use Caddyfile.snippet in this repo as the template.
# Replace <password> with the bcrypt hash from the step above.
# Replace <your-username> with the basicauth username you want.
sudo nano /etc/caddy/Caddyfile

# Validate before reloading
sudo caddy validate --config /etc/caddy/Caddyfile
sudo systemctl reload caddy
```

> **Note:** All `<password>` and `<your-username>` placeholders in `Caddyfile.snippet` **must** be replaced with real values before reloading Caddy. The snippet is documentary only — it is not applied automatically.

### C. biztechbridge refactor

Before the first hfs-demo deploy, the biztechbridge container must be refactored to stop binding the host's `:80`/`:443` directly. That work moves TLS to host-native Caddy and rebinds biztechbridge to `localhost:8081`.

See [spec §11.1](docs/superpowers/specs/2026-05-14-hfs-demonstrator-design.md#111-one-time-host-setup--host-native-caddy--biztechbridge-refactor) and Task 6.6 of the implementation plan for the step-by-step instructions. This is a separate change on the biztechbridge repo and requires a brief maintenance window.

### D. Per-deploy command

After one-time setup is done, every subsequent deploy is a single command:

```bash
./deploy-to-prod.sh
```

This rsync-es the source (excluding `.git`, `node_modules`, `dist`, `data`, `.env*`, `.superpowers`) to the server, then ssh-es in to rebuild the Docker image and restart the container. Host Caddy requires no reload for routine deploys.

### E. Reseed

Two paths for updating seed data without a full code change:

**Path 1 — Edit and redeploy (~30 s, rebuilds image):**
```bash
# Edit db/seed.sql locally, then:
./deploy-to-prod.sh
```

**Path 2 — In-place on the server (no image rebuild, immediate):**
```bash
ssh ***REDACTED-USER***@***REDACTED-IP*** \
  'cd hfs-demonstrator && sudo -n docker compose exec hfs-demo tsx scripts/reseed.ts'
```

---

## Reseed (local)

```bash
DB_PATH=./data/hfs.sqlite npm run reseed
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
