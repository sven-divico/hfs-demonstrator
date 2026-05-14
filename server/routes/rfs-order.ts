import type Database from "better-sqlite3";
import type { FastifyPluginAsync } from "fastify";

export default (db: Database.Database): FastifyPluginAsync => async (app) => {
  app.get<{ Params: { sysId: string } }>("/rfs-orders/:sysId", async (req, reply) => {
    const { sysId } = req.params;
    if (!/^rfs-\d{7,}$/.test(sysId)) {
      return reply.status(400).send({ error: "bad_sys_id", message: "sysId must look like 'rfs-0020001'" });
    }
    const rfs = db.prepare("SELECT * FROM wm_rfs_order WHERE sys_id = ?").get(sysId) as Record<string, unknown> | undefined;
    if (!rfs) {
      return reply.status(404).send({ error: "not_found", message: `RFS order ${sysId} not found` });
    }
    const co = db.prepare("SELECT * FROM wm_customer_order WHERE uuid = ?").get(rfs.customer_order) as Record<string, unknown>;
    const tasks = db.prepare(
      "SELECT * FROM wm_task WHERE rfs_order = ? ORDER BY short_description"
    ).all(sysId);
    return { ...rfs, customer_order: co, tasks };
  });
};
