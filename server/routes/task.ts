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
