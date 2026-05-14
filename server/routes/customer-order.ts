import type Database from "better-sqlite3";
import type { FastifyPluginAsync } from "fastify";

type CoRow = Record<string, unknown>;
type RfsRow = { sys_id: string; number: string; rfs_type: "LMA" | "Connectivity" };

export default (db: Database.Database): FastifyPluginAsync => async (app) => {
  app.get<{ Params: { uuid: string } }>("/customer-orders/:uuid", async (req, reply) => {
    const { uuid } = req.params;
    if (!/^co-\d{7,}$/.test(uuid)) {
      return reply.status(400).send({ error: "bad_uuid", message: "uuid must look like 'co-0010001'" });
    }
    const co = db.prepare("SELECT * FROM wm_customer_order WHERE uuid = ?").get(uuid) as CoRow | undefined;
    if (!co) {
      return reply.status(404).send({ error: "not_found", message: `Customer order ${uuid} not found` });
    }
    const rfs = db.prepare(
      "SELECT sys_id, number, rfs_type FROM wm_rfs_order WHERE customer_order = ? ORDER BY rfs_type"
    ).all(uuid) as RfsRow[];
    const lma  = rfs.find(r => r.rfs_type === "LMA")          ?? null;
    const conn = rfs.find(r => r.rfs_type === "Connectivity") ?? null;

    // Flattened 17-task list across both RFS, ordered by task-columns sequence.
    const tasks = db.prepare(
      `SELECT t.* FROM wm_task t
         JOIN wm_rfs_order rfs ON rfs.sys_id = t.rfs_order
        WHERE rfs.customer_order = ?
        ORDER BY t.short_description`
    ).all(uuid);

    return { ...co, lma_order: lma, connectivity_order: conn, tasks };
  });
};
