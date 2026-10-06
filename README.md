# BDD PostgreSQL – Projet G4 EPSI

Base de données du projet, déployée en conteneur Docker. Elle est utilisée par le **Backend IoT (gestion + alertes)** et le **Backend API**.

## Caractéristiques

| Élément | Valeur |
|---|---|
| Image | `postgres:16-alpine` |
| Conteneur | `g4-db` |
| Nom d'hôte (réseau Docker) | `db` |
| Port | `5432` (non publié sur l'hôte) |
| Base | `g4_epsi` |
| Utilisateur | `epsi` |
| Mot de passe | fichier `secrets/db_password.txt` (non versionné) |
| Réseau | `backend` (`internal: true`, sans accès externe) |
| Données | volume Docker `pgdata` |

## Arborescence

```
g4/
├── docker-compose.yml
├── db/
│   └── init/
│       └── 01_schema.sql      # exécuté uniquement au 1er démarrage (volume vide)
└── secrets/
    └── db_password.txt        # à créer, ne jamais commiter
```

## Démarrage

```bash
# 1. Créer le mot de passe (sans retour à la ligne)
openssl rand -base64 24 | tr -d '\n' > secrets/db_password.txt
chmod 600 secrets/db_password.txt

# 2. Lancer
docker compose up -d

# 3. Vérifier
docker compose ps                                        # état "healthy"
docker exec -it g4-db psql -U epsi -d g4_epsi -c '\dt'   # liste des tables
```

## Schéma

| Table | Rôle |
|---|---|
| `devices` | Objets IoT (nom, type, topic MQTT, dernière activité) |
| `measurements` | Mesures horodatées par objet (index `device_id, ts DESC`) |
| `alerts` | Alertes (gravité `info`/`warning`/`critical`, acquittement) |
| `users` | Comptes du dashboard (hash du mot de passe, rôle) |

Détail complet dans `db/init/01_schema.sql`.

## Connexion depuis un autre service

Le service doit rejoindre le réseau `backend` dans le compose :

```yaml
services:
  api:
    networks: [backend]
    depends_on:
      db:
        condition: service_healthy
    environment:
      DB_HOST: db
      DB_PORT: 5432
      DB_NAME: g4_epsi
      DB_USER: epsi
      DB_PASSWORD_FILE: /run/secrets/db_password
```

Chaîne de connexion type : `postgresql://epsi:<mot_de_passe>@db:5432/g4_epsi`

## Exploitation

```bash
docker compose logs -f db                                # logs
docker exec -it g4-db psql -U epsi -d g4_epsi            # console SQL

# Sauvegarde
docker exec g4-db pg_dump -U epsi g4_epsi > backup_$(date +%F).sql

# Restauration
docker exec -i g4-db psql -U epsi -d g4_epsi < backup_AAAA-MM-JJ.sql

# Repartir de zéro (SUPPRIME les données, rejoue 01_schema.sql)
docker compose down -v && docker compose up -d
```

## Remarques

- Aucun port n'est publié : la BDD n'est joignable que depuis les conteneurs du réseau `backend`.
- Modifier `01_schema.sql` n'a d'effet qu'après recréation du volume (`down -v`).
- Pour du débogage depuis l'hôte, publier temporairement `127.0.0.1:5432:5432` et retirer `internal: true`, puis revenir à la configuration initiale.
