-- Schéma commun Sentinel-X (base unique, image backend_db).
-- Exécuté seulement à la création du volume : sur une base existante, appliquer les
-- changements à la main (make db-sql F=... depuis main/).

CREATE EXTENSION IF NOT EXISTS timescaledb;

-- Objets IoT (nom, type, topic MQTT, dernière activité)
CREATE TABLE devices (
  id           SERIAL PRIMARY KEY,
  name         TEXT NOT NULL UNIQUE,
  type         TEXT NOT NULL,
  mqtt_topic   TEXT NOT NULL UNIQUE,
  last_seen    TIMESTAMPTZ,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Mesures horodatées par objet (format long : une métrique par ligne)
CREATE TABLE measurements (
  id           BIGSERIAL PRIMARY KEY,
  device_id    INT NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
  metric       TEXT NOT NULL,
  value        DOUBLE PRECISION NOT NULL,
  ts           TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_meas_device_ts ON measurements (device_id, ts DESC);

-- Alertes affichées par le dashboard : écrites par le service de détection (backend-iot-alerts,
-- détection temps réel + alertes brutes de l'ESP), lues et acquittées par backend-api (db.js).
CREATE TABLE alerts (
  id              UUID        PRIMARY KEY,
  time            TIMESTAMPTZ NOT NULL DEFAULT now(),
  device_id       TEXT,
  source          TEXT        NOT NULL,
  severity        TEXT        NOT NULL CHECK (severity IN ('critical','high','medium','low')),
  title           TEXT        NOT NULL,
  description     TEXT        NOT NULL DEFAULT '',
  metadata        JSONB       NOT NULL DEFAULT '{}',
  acknowledged    BOOLEAN     NOT NULL DEFAULT false,
  acknowledged_at TIMESTAMPTZ,
  acknowledged_by TEXT
);
CREATE INDEX idx_alerts_time ON alerts (time DESC);
CREATE INDEX idx_alerts_device_time ON alerts (device_id, time DESC);

-- Commandes envoyées à l'ESP (buzzer, LEDs) et leur acquittement
CREATE TABLE commands (
  id           BIGSERIAL PRIMARY KEY,
  time         TIMESTAMPTZ NOT NULL DEFAULT now(),
  device_id    TEXT        NOT NULL,
  action       TEXT        NOT NULL,
  params       JSONB,
  acked_at     TIMESTAMPTZ
);

-- Comptes du dashboard
CREATE TABLE users (
  id            SERIAL PRIMARY KEY,
  username      TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  role          TEXT NOT NULL DEFAULT 'viewer'
);
