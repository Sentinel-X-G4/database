-- Base existante (volume créé avant ce changement) : depuis main/,
--   make db-sql F=services/database/db/migrations/2026-10-07_camera_state.sql
-- Les nouvelles bases l'ont déjà (db/init/02_detection.sql). Rejouable sans risque.

-- Dernier état de chaque caméra (sentinelx/{device_id}/camera), une ligne par device_id : écrit
-- à chaque changement et au moins toutes les 10 s (updated_at = fraîcheur), lu par backend-api
CREATE TABLE IF NOT EXISTS detection.camera_state (
    device_id  TEXT        PRIMARY KEY,
    updated_at TIMESTAMPTZ NOT NULL,
    device_ts  BIGINT,
    person     BOOLEAN     NOT NULL,
    identity   TEXT,                       -- none | authorized | unknown (null : reconnaissance désactivée)
    names      JSONB       NOT NULL,       -- personnes autorisées reconnues
    faces      JSONB       NOT NULL        -- visages vus : [{"name": "Alice" | null}]
);
