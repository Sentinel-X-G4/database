# BDD PostgreSQL – Sentinel-X (G4 EPSI)

Base de données **unique** du projet. Elle est utilisée par le **service de détection**
(`backend-iot-alerts`, qui écrit) et le **Backend API** (`backend-api`, qui lit et acquitte).

Ce dépôt ne contient que l'image (`Dockerfile`) et le schéma (`db/init/`). Elle est lancée
par le `docker-compose.yml` du dépôt [`main`](https://github.com/Sentinel-X-G4/main) :
service `db`, conteneur `g4-db`, volume `pg-data`, réseau interne `sentinel-data`.

## Caractéristiques

| Élément | Valeur |
|---|---|
| Image | `timescale/timescaledb:latest-pg16` + schéma intégré |
| Nom d'hôte (réseau Docker) | `db` |
| Port | `5432` (non publié sur l'hôte) |
| Base / utilisateur / mot de passe | `POSTGRES_DB` / `POSTGRES_USER` / `POSTGRES_PASSWORD` du `.env` de `main` |
| Réseau | `sentinel-data` (`internal: true`, sans accès externe) |
| Données | volume Docker `pg-data` |

## Schéma (`db/init/`, exécuté uniquement au 1er démarrage, volume vide)

| Fichier | Contenu |
|---|---|
| `01_schema.sql` | `devices`, `measurements`, `alerts`, `commands`, `users` |
| `02_detection.sql` | schéma `detection` : mesures brutes, caméra, features, prédictions, sessions (hypertables) |
| `03_notify.sql` | triggers `NOTIFY` (`sentinel_alerts`, `sentinel_devices`) écoutés par backend-api |

| Table | Écrite par | Lue par |
|---|---|---|
| `alerts` | détection (activation feu / gaz / présence, alertes ESP) | backend-api (liste, stats, acquittement) |
| `detection.predictions` | détection (changement d'état + heartbeat 10 s) | backend-api (état des appareils) |
| `detection.sensor_readings`, `camera_events`, `feature_windows`, `recording_sessions` | détection | détection (jeu d'entraînement) |
| `devices`, `measurements`, `commands`, `users` | — (prévues : objets, comptes du dashboard) | — |

`02_detection.sql` doit rester aligné sur `detection_service/storage/tables.py`, et
`alerts` sur `backend-api/db.js` : aucun service ne crée de table.

## Exploitation (depuis `main/`)

```bash
make db                      # console SQL
make db-sql F=migration.sql  # appliquer un changement sur une base existante
make db-backup               # sauvegarde dans backups/
make db-reset                # SUPPRIME les données et rejoue db/init (confirmation)
```

Modifier `db/init/` n'a d'effet qu'à la création du volume : sur une base existante,
écrire le `ALTER` correspondant et l'appliquer avec `make db-sql`.
