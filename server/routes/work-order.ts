import type Database from "better-sqlite3";
import type { FastifyPluginAsync } from "fastify";
export default (_db: Database.Database): FastifyPluginAsync => async (_app) => {};
