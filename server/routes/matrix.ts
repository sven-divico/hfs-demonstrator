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
