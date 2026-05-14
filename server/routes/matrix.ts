import type Database from "better-sqlite3";
import type { FastifyPluginAsync } from "fastify";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";

type CoRow = {
  uuid: string; number: string; order_date: string; customer_name: string;
  address: string; city: string; phone: string; scheduled_appointment: string | null;
  status_code: number; construction_status: string; unit_count: number; set_name: string;
};
type RfsRow = { sys_id: string; number: string; customer_order: string; rfs_type: "LMA" | "Connectivity" };
type TaskRow = { customer_order: string; short_description: string; state: string };

export default (db: Database.Database): FastifyPluginAsync => async (app) => {
  const columns = JSON.parse(readFileSync(resolve("public/task-columns.json"), "utf8"));

  app.get<{ Querystring: { list?: string; limit?: string; offset?: string } }>(
    "/work-orders/matrix",
    async (req, reply) => {
      const list = req.query.list ?? "legacy";
      if (list !== "legacy" && list !== "attention") {
        return reply.status(400).send({ error: "bad_list", message: `Unknown list '${list}'. Allowed: legacy, attention.` });
      }

      const limit  = clampInt(req.query.limit,  25, 1, 200);
      const offset = clampInt(req.query.offset, 0,  0, Number.MAX_SAFE_INTEGER);

      // Count + page over customer orders.
      const countSql = list === "attention"
        ? `SELECT COUNT(DISTINCT co.uuid) AS n
             FROM wm_customer_order co
             JOIN wm_rfs_order rfs ON rfs.customer_order = co.uuid
             JOIN wm_task t        ON t.rfs_order       = rfs.sys_id
            WHERE t.state = 'Problem'`
        : `SELECT COUNT(*) AS n FROM wm_customer_order`;
      const total = (db.prepare(countSql).get() as { n: number }).n;

      const baseSql = list === "attention"
        ? `SELECT DISTINCT co.*
             FROM wm_customer_order co
             JOIN wm_rfs_order rfs ON rfs.customer_order = co.uuid
             JOIN wm_task t        ON t.rfs_order       = rfs.sys_id
            WHERE t.state = 'Problem'
            ORDER BY co.number DESC
            LIMIT ? OFFSET ?`
        : `SELECT * FROM wm_customer_order ORDER BY number DESC LIMIT ? OFFSET ?`;
      const orders = db.prepare(baseSql).all(limit, offset) as CoRow[];

      // Fetch the two RFS orders + flattened tasks for just this page.
      const rfsByCo = new Map<string, { lma_order: RfsRow | null; connectivity_order: RfsRow | null }>();
      const tasksByCo = new Map<string, Record<string, string>>();

      if (orders.length > 0) {
        const placeholders = orders.map(() => "?").join(",");
        const coIds = orders.map(o => o.uuid);

        const rfsRows = db.prepare(
          `SELECT sys_id, number, customer_order, rfs_type FROM wm_rfs_order WHERE customer_order IN (${placeholders})`
        ).all(...coIds) as RfsRow[];
        for (const r of rfsRows) {
          const slot = rfsByCo.get(r.customer_order) ?? { lma_order: null, connectivity_order: null };
          if (r.rfs_type === "LMA") slot.lma_order = r;
          else slot.connectivity_order = r;
          rfsByCo.set(r.customer_order, slot);
        }

        const taskRows = db.prepare(
          `SELECT rfs.customer_order AS customer_order, t.short_description, t.state
             FROM wm_task t
             JOIN wm_rfs_order rfs ON rfs.sys_id = t.rfs_order
            WHERE rfs.customer_order IN (${placeholders})`
        ).all(...coIds) as TaskRow[];
        for (const t of taskRows) {
          const m = tasksByCo.get(t.customer_order) ?? {};
          m[t.short_description] = t.state;
          tasksByCo.set(t.customer_order, m);
        }
      }

      const rows = orders.map(o => ({
        ...o,
        lma_order:          rfsByCo.get(o.uuid)?.lma_order          ?? null,
        connectivity_order: rfsByCo.get(o.uuid)?.connectivity_order ?? null,
        tasks:              tasksByCo.get(o.uuid) ?? {},
      }));
      return { columns, rows, total, offset, limit };
    }
  );
};

function clampInt(raw: unknown, fallback: number, min: number, max: number): number {
  const n = Number.parseInt(String(raw ?? ""), 10);
  if (!Number.isFinite(n)) return fallback;
  return Math.max(min, Math.min(max, n));
}
