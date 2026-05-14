import type Database from "better-sqlite3";
import type { FastifyPluginAsync } from "fastify";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";

type WoRow = { sys_id: string; number: string; status_code: number; construction_status: string; account: string; city: string; address: string; unit_count: number; set_name: string };
type TaskRow = { work_order: string; short_description: string; state: string };

export default (db: Database.Database): FastifyPluginAsync => async (app) => {
  const columns = JSON.parse(readFileSync(resolve("public/task-columns.json"), "utf8"));

  app.get<{ Querystring: { list?: string; limit?: string; offset?: string } }>(
    "/work-orders/matrix",
    async (req, reply) => {
      const list = req.query.list ?? "legacy";
      if (list !== "legacy" && list !== "attention") {
        return reply.status(400).send({ error: "bad_list", message: `Unknown list '${list}'. Allowed: legacy, attention.` });
      }

      // Pagination: accept ?limit (default 25, max 200) and ?offset (default 0).
      // Shape mirrors what a SNOW Scripted REST list endpoint typically exposes
      // — easy 1:1 port to sysparm_limit / sysparm_offset on the SNOW side.
      const limit  = clampInt(req.query.limit,  25, 1, 200);
      const offset = clampInt(req.query.offset, 0,  0, Number.MAX_SAFE_INTEGER);

      const countSql = list === "attention"
        ? `SELECT COUNT(DISTINCT o.sys_id) AS n FROM wm_order o JOIN wm_task t ON t.work_order = o.sys_id WHERE t.state = 'Problem'`
        : `SELECT COUNT(*) AS n FROM wm_order`;
      const total = (db.prepare(countSql).get() as { n: number }).n;

      const baseSql = list === "attention"
        ? `SELECT DISTINCT o.* FROM wm_order o JOIN wm_task t ON t.work_order = o.sys_id WHERE t.state = 'Problem' ORDER BY o.number DESC LIMIT ? OFFSET ?`
        : `SELECT * FROM wm_order ORDER BY number DESC LIMIT ? OFFSET ?`;
      const orders = db.prepare(baseSql).all(limit, offset) as WoRow[];

      // Only fetch tasks for the WOs in this page.
      const tasksByWo = new Map<string, Record<string, string>>();
      if (orders.length > 0) {
        const placeholders = orders.map(() => "?").join(",");
        const taskRows = db.prepare(
          `SELECT work_order, short_description, state FROM wm_task WHERE work_order IN (${placeholders})`
        ).all(...orders.map(o => o.sys_id)) as TaskRow[];
        for (const t of taskRows) {
          const m = tasksByWo.get(t.work_order) ?? {};
          m[t.short_description] = t.state;
          tasksByWo.set(t.work_order, m);
        }
      }

      const rows = orders.map(o => ({ ...o, tasks: tasksByWo.get(o.sys_id) ?? {} }));
      return { columns, rows, total, offset, limit };
    }
  );
};

function clampInt(raw: unknown, fallback: number, min: number, max: number): number {
  const n = Number.parseInt(String(raw ?? ""), 10);
  if (!Number.isFinite(n)) return fallback;
  return Math.max(min, Math.min(max, n));
}
