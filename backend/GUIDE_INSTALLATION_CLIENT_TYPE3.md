# Guide d'installation — Client Type 3 (Hybride Local + Cloud)

## Vue d'ensemble

Le client Type 3 dispose d'un backend qui tourne en local sur sa machine,
connecté à une base de données PostgreSQL hébergée sur Neon.tech.
Tous les utilisateurs de l'entreprise partagent la même BD cloud.
L'app fonctionne même sans internet (mode offline-fallback).

---

## Prérequis

- Accès à ton compte [neon.tech](https://neon.tech)
- L'installeur LOGESCO (backend + Flutter)
- Accès à la machine du client (ou accès distant)

---

## ÉTAPE 1 — Créer le projet Neon pour le client

1. Connecte-toi sur [console.neon.tech](https://console.neon.tech)
2. Clique **"New Project"**
3. Remplis :
   - **Project name** : `logesco-[nom-client]` (ex: `logesco-pharmacie-centrale`)
   - **Region** : choisir la plus proche (ex: `EU Frankfurt` pour l'Afrique)
   - **PostgreSQL version** : 16
4. Clique **"Create Project"**
5. Neon affiche la **Connection String** — copie-la immédiatement :
   ```
   postgresql://neondb_owner:MOT_DE_PASSE@ep-xxx.aws.neon.tech/neondb?sslmode=require
   ```
   ⚠️ Garde cette URL en lieu sûr, tu en auras besoin à l'étape 3.

---

## ÉTAPE 2 — Initialiser la base de données sur Neon

Sur ta machine de développement, ouvre un terminal dans le dossier `backend/` :

```powershell
# Windows PowerShell
$env:DATABASE_URL="[COLLE ICI LA CONNECTION STRING NEON]"

# Swap migrations SQLite → PostgreSQL
Move-Item -Path "prisma\migrations" -Destination "prisma\migrations_sqlite_bak"
Copy-Item -Path "prisma\migrations_pg" -Destination "prisma\migrations" -Recurse

# Déployer le schema
npx prisma migrate deploy --schema=prisma/schema.postgresql.prisma

# Remettre les migrations SQLite
Remove-Item -Recurse -Force "prisma\migrations"
Move-Item -Path "prisma\migrations_sqlite_bak" -Destination "prisma\migrations"
```

✅ Si tu vois `All migrations have been successfully applied` → la BD est prête.

---

## ÉTAPE 3 — Préparer le fichier .env du client

Dans le dossier `backend/`, crée ou modifie le fichier `.env` avec les valeurs
spécifiques à ce client :

```env
# Environnement
NODE_ENV=production
PORT=8080

# Base de données locale (SQLite — fallback offline)
DATABASE_PROVIDER="sqlite"
DATABASE_URL="file:./database/logesco.db"

# Base de données cloud (Neon — sync en ligne)
CLOUD_DB_URL="postgresql://neondb_owner:MOT_DE_PASSE@ep-xxx.aws.neon.tech/neondb?sslmode=require"

# JWT — CHANGE cette valeur pour chaque client !
JWT_SECRET=logesco-[nom-client]-secret-[année]-[random]
JWT_EXPIRES_IN=365d
JWT_REFRESH_EXPIRES_IN=365d

# API
API_VERSION=v1
CORS_ORIGIN=*
LOG_LEVEL=info
```

⚠️ **Important** :
- Remplace `CLOUD_DB_URL` par la connection string Neon du client
- Change `JWT_SECRET` — utilise une valeur unique par client
- Ne partage jamais ce fichier `.env` publiquement

---

## ÉTAPE 4 — Installer le backend sur la machine du client

### Option A — Installation via l'installeur (recommandé)

1. Lance l'installeur LOGESCO sur la machine du client
2. L'installeur copie le backend dans `C:\Program Files\LOGESCO\backend\`
3. **Remplace le fichier `.env`** dans ce dossier par celui préparé à l'étape 3
4. Démarre le service LOGESCO

### Option B — Installation manuelle

1. Copie le dossier `backend/` sur la machine du client
2. Ouvre un terminal dans ce dossier
3. Lance :
   ```bash
   npm install
   npm start
   ```
4. Vérifie que le serveur démarre avec `Mode sync: hybrid` dans les logs

---

## ÉTAPE 5 — Vérifier la synchronisation initiale

Au premier démarrage, le backend détecte que Neon est vide et envoie
automatiquement toutes les données locales vers Neon.

Dans les logs du backend, tu dois voir :

```
☁️  Connexion Neon établie — mode hybride actif
📦 Neon vide — démarrage de la sync initiale...
  ✓ user_roles: X enregistrements
  ✓ utilisateurs: X enregistrements
  ✓ produits: X enregistrements
  ...
✅ Sync initiale terminée — X enregistrements envoyés vers Neon
🔄 Mode sync: hybrid
```

Si tu vois `Mode sync: local-only` → vérifie que `CLOUD_DB_URL` est bien défini dans `.env`.
Si tu vois `Mode sync: offline-fallback` → internet indisponible, la sync reprendra automatiquement.

---

## ÉTAPE 6 — Configurer l'app Flutter (client)

Dans l'app Flutter, configure l'URL du backend local dans les paramètres :

```
http://localhost:8080
```

ou si l'app tourne sur une autre machine du réseau local :

```
http://[IP-MACHINE-SERVEUR]:8080
```

---

## ÉTAPE 7 — Vérification finale

Teste les points suivants avant de remettre les clés au client :

- [ ] L'app Flutter se connecte au backend local
- [ ] Une vente test apparaît dans l'app
- [ ] Après 30 secondes, la vente est visible sur [console.neon.tech](https://console.neon.tech) → SQL Editor → `SELECT * FROM ventes`
- [ ] Coupe internet → l'app continue de fonctionner
- [ ] Reconnecte internet → les données hors ligne se synchronisent

---

## Résumé des coûts pour ce client

| Service | Plan | Coût/mois |
|---|---|---|
| Neon.tech (BD cloud) | Free tier | **0 $** |
| Backend local | Sur machine client | **0 $** |
| **Total infrastructure** | | **0 $/mois** |

Le client ne paie que la licence LOGESCO.

---

## En cas de problème

### "Mode sync: offline-fallback" en permanence
→ Vérifie la connexion internet de la machine
→ Vérifie que `CLOUD_DB_URL` est correct dans `.env`
→ Teste la connexion Neon depuis [console.neon.tech](https://console.neon.tech)

### "Mode sync: local-only"
→ `CLOUD_DB_URL` est absent ou vide dans `.env`
→ Ajoute la variable et redémarre le backend

### Les données ne se voient pas entre utilisateurs
→ Vérifie que tous les backends pointent vers la **même** `CLOUD_DB_URL`
→ Attends 30 secondes (cycle de sync)
→ Vérifie les logs pour des erreurs de sync

### Réinitialiser la sync (cas extrême)
Sur [console.neon.tech](https://console.neon.tech) → SQL Editor :
```sql
-- Vider toutes les tables (ATTENTION : irréversible)
TRUNCATE TABLE ventes, produits, utilisateurs CASCADE;
```
Puis redémarre le backend — la sync initiale se relancera automatiquement.
