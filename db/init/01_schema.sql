CREATE TABLE devices (
  id           SERIAL PRIMARY KEY,
  name         TEXT NOT NULL UNIQUE,
  type         TEXT NOT NULL,
  mqtt_topic   TEXT NOT NULL UNIQUE,
  last_seen    TIMESTAMPTZ,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE measurements (
  id           BIGSERIAL PRIMARY KEY,
  device_id    INT NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
  metric       TEXT NOT NULL,
  value        DOUBLE PRECISION NOT NULL,
  ts           TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_meas_device_ts ON measurements (device_id, ts DESC);

CREATE TABLE alerts (
  id           BIGSERIAL PRIMARY KEY,
  device_id    INT REFERENCES devices(id) ON DELETE SET NULL,
  severity     TEXT NOT NULL CHECK (severity IN ('info','warning','critical')),
  message      TEXT NOT NULL,
  acknowledged BOOLEAN NOT NULL DEFAULT false,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE users (
  id            SERIAL PRIMARY KEY,
  username      TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  role          TEXT NOT NULL DEFAULT 'viewer'
);
