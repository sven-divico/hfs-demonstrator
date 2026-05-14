import { mkdirSync } from "node:fs";
import { dirname } from "node:path";
import { openDb, rebuildFromSeed } from "../server/db.js";

const DB_PATH = process.env.DB_PATH ?? "/data/hfs.sqlite";
mkdirSync(dirname(DB_PATH), { recursive: true });

const db = openDb();
rebuildFromSeed(db);
const orders = db.prepare("SELECT COUNT(*) AS n FROM wm_order").get() as { n: number };
const tasks = db.prepare("SELECT COUNT(*) AS n FROM wm_task").get() as { n: number };
console.log(`Reseeded: ${orders.n} orders, ${tasks.n} tasks at ${DB_PATH}`);
