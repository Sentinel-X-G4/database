# Base de données unique de Sentinel-X : PostgreSQL 16 + TimescaleDB (séries temporelles
# du service de détection). Le schéma est intégré à l'image et joué au premier démarrage
# (volume vide). Lancée par le docker-compose de Sentinel-X-G4/main.
FROM timescale/timescaledb:latest-pg16

COPY db/init/ /docker-entrypoint-initdb.d/

HEALTHCHECK --interval=10s --timeout=5s --retries=5 \
    CMD pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB" || exit 1
