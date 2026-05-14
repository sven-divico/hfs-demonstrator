import type Database from "better-sqlite3";
import type { FastifyPluginAsync } from "fastify";

export default (db: Database.Database): FastifyPluginAsync => async (app) => {
  // Look up a single task on a Customer Order by canonical task name.
  // The task lives on one of the two child RFS orders — we don't make the
  // caller care which one.
  app.get<{ Params: { uuid: string; taskName: string } }>(
    "/customer-orders/:uuid/tasks/:taskName",
    async (req, reply) => {
      const { uuid, taskName } = req.params;
      if (!/^co-\d{7,}$/.test(uuid)) {
        return reply.status(400).send({ error: "bad_uuid", message: "uuid must look like 'co-0010001'" });
      }
      const task = db.prepare(
        `SELECT t.* FROM wm_task t
           JOIN wm_rfs_order rfs ON rfs.sys_id = t.rfs_order
          WHERE rfs.customer_order = ? AND t.short_description = ?`
      ).get(uuid, taskName);
      if (!task) {
        return reply.status(404).send({ error: "not_found", message: `Task '${taskName}' not found on ${uuid}` });
      }
      return task;
    }
  );
};
