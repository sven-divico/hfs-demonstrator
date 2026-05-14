DROP TABLE IF EXISTS wm_task;
DROP TABLE IF EXISTS wm_rfs_order;
DROP TABLE IF EXISTS wm_customer_order;

-- Business-facing entity. Matrix rows are CO rows.
CREATE TABLE wm_customer_order (
  uuid                  TEXT PRIMARY KEY,           -- 'co-NNNNNNN', used as path param
  number                TEXT UNIQUE NOT NULL,       -- 'CO-26-XXXX-XXXX' (Crockford base32)
  order_date            TEXT,
  customer_name         TEXT,
  address               TEXT,
  city                  TEXT,
  phone                 TEXT,
  scheduled_appointment TEXT,                       -- nullable ISO datetime
  status_code           INTEGER NOT NULL,
  construction_status   TEXT,
  unit_count            INTEGER,
  set_name              TEXT
);

-- TMF RFS work order. Two per Customer Order: one LMA, one Connectivity.
-- LMA owns 16 of the 17 canonical tasks; Connectivity owns only ONT.
CREATE TABLE wm_rfs_order (
  sys_id          TEXT PRIMARY KEY,
  number          TEXT UNIQUE NOT NULL,
  customer_order  TEXT NOT NULL REFERENCES wm_customer_order(uuid),
  rfs_type        TEXT NOT NULL CHECK (rfs_type IN ('LMA','Connectivity'))
);

CREATE TABLE wm_task (
  sys_id            TEXT PRIMARY KEY,
  number            TEXT UNIQUE NOT NULL,
  rfs_order         TEXT NOT NULL REFERENCES wm_rfs_order(sys_id),
  rfs_type          TEXT NOT NULL,                  -- denormalised for cheap matrix joins
  short_description TEXT NOT NULL,
  short_code        TEXT NOT NULL,
  state             TEXT NOT NULL,
  assignment_group  TEXT,
  sys_updated_on    TEXT
);

CREATE INDEX idx_rfs_co   ON wm_rfs_order(customer_order);
CREATE INDEX idx_task_rfs ON wm_task(rfs_order);
