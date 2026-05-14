DROP TABLE IF EXISTS wm_task;
DROP TABLE IF EXISTS wm_order;

CREATE TABLE wm_order (
  sys_id              TEXT PRIMARY KEY,
  number              TEXT UNIQUE NOT NULL,
  status_code         INTEGER NOT NULL,
  construction_status TEXT,
  account             TEXT,
  city                TEXT,
  address             TEXT,
  unit_count          INTEGER,
  set_name            TEXT
);

CREATE TABLE wm_task (
  sys_id            TEXT PRIMARY KEY,
  number            TEXT UNIQUE NOT NULL,
  work_order        TEXT NOT NULL REFERENCES wm_order(sys_id),
  short_description TEXT NOT NULL,
  short_code        TEXT NOT NULL,
  state             TEXT NOT NULL,
  assignment_group  TEXT,
  sys_updated_on    TEXT
);

CREATE INDEX idx_task_wo ON wm_task(work_order);
