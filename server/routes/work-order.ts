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
