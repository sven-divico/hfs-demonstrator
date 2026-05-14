import Fastify from "fastify";
import fastifyStatic from "@fastify/static";
import { mkdirSync, existsSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { openDb, rebuildFromSeed } from "./db.js";
import matrixRoute from "./routes/matrix.js";
import workOrderRoute from "./routes/work-order.js";
import taskRoute from "./routes/task.js";
import taskColumnsRoute from "./routes/task-columns.js";

const PORT = Number(process.env.PORT ?? 8080);
const DB_PATH = process.env.DB_PATH ?? "/data/hfs.sqlite";

mkdirSync(dirname(DB_PATH), { recursive: true });
const db = openDb();
if (!existsSync(DB_PATH) || db.prepare("SELECT name FROM sqlite_master WHERE type='table' AND name='wm_order'").get() === undefined) {
  rebuildFromSeed(db);
}

const app = Fastify({ logger: true });

app.register(fastifyStatic, { root: resolve("public"), prefix: "/" });
app.register(matrixRoute(db), { prefix: "/api" });
app.register(workOrderRoute(db), { prefix: "/api" });
app.register(taskRoute(db), { prefix: "/api" });
app.register(taskColumnsRoute(), { prefix: "/api" });

app.setErrorHandler((err, req, reply) => {
  req.log.error(err);
  reply.status(500).send({ error: "internal", message: "Internal server error" });
});

app.listen({ port: PORT, host: "0.0.0.0" }).then(() => {
  app.log.info(`hfs-demo listening on :${PORT}`);
});
