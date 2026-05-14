import type { FastifyPluginAsync } from "fastify";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";

export default (): FastifyPluginAsync => async (app) => {
  const columns = JSON.parse(readFileSync(resolve("public/task-columns.json"), "utf8"));
  app.get("/task-columns", async () => columns);
};
