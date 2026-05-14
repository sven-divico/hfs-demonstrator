import Database from "better-sqlite3";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";

const DB_PATH = process.env.DB_PATH ?? "/data/hfs.sqlite";
const SCHEMA = resolve("db/schema.sql");
const SEED = resolve("db/seed.sql");

function applySql(db: Database.Database, file: string) {
  const sql = readFileSync(file, "utf8");
  db.exec(sql);
}

export function openDb(): Database.Database {
  const db = new Database(DB_PATH);
  db.pragma("journal_mode = WAL");
  db.pragma("foreign_keys = ON");
  return db;
}

export function rebuildFromSeed(db: Database.Database) {
  applySql(db, SCHEMA);
  applySql(db, SEED);
}
