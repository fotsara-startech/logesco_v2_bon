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

Sur ta machine de développement, ouvre PowerShell **en tant qu'administrateur** dans le dossier `backend/` :

### 2.1 — Sauvegarder les migrations SQLite et basculer vers PostgreSQL

```powershell
# 1. Renommer les migrations SQLite actuelles
Rename-Item -Path "prisma\migrations" -NewName "migrations_sqlite_bak"

# 2. Copier les migrations PostgreSQL à la place
Copy-Item -Path "prisma\migrations_pg\*" -Destination "prisma\migrations" -Recurse -Force

# 3. Nettoyer le sous-dossier imbriqué parasites (si présent)
Remove-Item -Recurse -Force "prisma\migrations\migrations" -ErrorAction SilentlyContinue
```

### 2.2 — Déployer le schéma PostgreSQL sur Neon

```powershell
# Définir la connection string Neon du client
$env:DATABASE_URL="[COLLE ICI LA CONNECTION STRING NEON]"

# Exemple :
# $env:DATABASE_URL="postgresql://neondb_owner:npg_2AqZ4TJDMzSu@ep-flat-term-alategot-pooler.c-3.eu-central-1.aws.neon.tech/neondb?sslmode=require&channel_binding=require"

# Déployer
npx prisma migrate deploy --schema=prisma/schema.postgresql.prisma
```

Tu dois voir : `No pending migrations to apply` ✅

### 2.3 — Restaurer les migrations SQLite

```powershell
# Restaurer pour la prochaine utilisation locale
Remove-Item -Recurse -Force "prisma\migrations"
Rename-Item -Path "prisma\migrations_sqlite_bak" -NewName "migrations"
```

### ⚠️ Dépannage des migrations PostgreSQL

Si tu vois des erreurs lors du déploiement, voici comment les résoudre :

**Erreur : "syntax error at or near AUTOINCREMENT"**
→ Tu as copié les migrations SQLite au lieu de PostgreSQL. Recommence à l'étape 2.1.

**Erreur : "column 'date_creation' specified more than once"**
→ Il y a un doublon dans la migration. Ouvre `prisma/migrations/20260423221732_init_postgresql/migration.sql` et cherche les lignes dupliquées (ex: deux fois `"date_creation" TIMESTAMP(3)`). Supprime l'une des deux, puis relance.

**Erreur : "Could not find the migration file at migration.sql"**
→ Le sous-dossier `migrations/migrations` imbriqué interfère. Exécute :
```powershell
Remove-Item -Recurse -Force "prisma\migrations\migrations"
npx prisma migrate deploy --schema=prisma/schema.postgresql.prisma
```

**Erreur : "migrate found failed migrations"**
→ Une migration précédente a échoué et bloque le déploiement. Marque-la comme annulée :
```powershell
npx prisma migrate resolve --rolled-back "20251106124948_init_with_licenses" --schema=prisma/schema.postgresql.prisma
npx prisma migrate resolve --rolled-back "20260423221732_init_postgresql" --schema=prisma/schema.postgresql.prisma
npx prisma migrate deploy --schema=prisma/schema.postgresql.prisma
```

---

## ÉTAPE 3 — Préparer le fichier .env du client

⚠️ **IMPORTANT** : Ne modifie **pas** le `.env` de ta machine de développement. Prépare un nouveau fichier `.env` destiné à la machine du client.

Sur la machine du **client**, dans le dossier `backend/`, crée ou modifie le fichier `.env` :

```env
# Environnement
NODE_ENV=production
PORT=8080

# Base de données locale (SQLite — fallback offline)
DATABASE_PROVIDER="sqlite"
DATABASE_URL="file:./database/logesco.db"

# Base de données cloud (Neon — sync en ligne)
# ⚠️ REMPLACE PAR LA CONNECTION STRING NEON DU CLIENT
CLOUD_DB_URL="postgresql://neondb_owner:npg_2AqZ4TJDMzSu@ep-flat-term-alategot-pooler.c-3.eu-central-1.aws.neon.tech/neondb?sslmode=require&channel_binding=require"

# JWT — CHANGE cette valeur pour chaque client
# Format : logesco-[nom-client]-secret-[année]-[random]
JWT_SECRET=logesco-pharmacie-centrale-secret-2026-ax7k9mq2
JWT_EXPIRES_IN=365d
JWT_REFRESH_EXPIRES_IN=365d

# API
API_VERSION=v1
CORS_ORIGIN=*
LOG_LEVEL=info
```

### Points importants :

- **`CLOUD_DB_URL`** : doit pointer vers **la BD Neon du client** (celle créée à l'étape 1)
- **`JWT_SECRET`** : doit être unique et complexe pour chaque client (change la partie `[random]`)
- **`NODE_ENV`** : doit être `production` sur la machine du client
- **Garde ce fichier sécurisé** : ne le partage jamais publiquement (il contient le mot de passe Neon)

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

Au premier démarrage du backend sur la machine du client, il va :

1. Détecter que Neon est vide
2. Charger toutes les données locales (SQLite) 
3. Envoyer tout vers Neon automatiquement

### Logs attendus au démarrage

```
☁️  Connexion Neon établie — mode hybride actif
📦 Neon vide — démarrage de la sync initiale...
  ✓ user_roles: 12 enregistrements
  ✓ utilisateurs: 3 enregistrements
  ✓ produits: 147 enregistrements
  ✓ ventes: 89 enregistrements
  ...
✅ Sync initiale terminée — 1247 enregistrements envoyés vers Neon
🔄 Mode sync: hybrid
```

### Diagnostic

- **Tu vois `Mode sync: local-only`** → `CLOUD_DB_URL` est absent ou vide dans `.env`. Ajoute-la et redémarre.
- **Tu vois `Mode sync: offline-fallback`** → Problème de connexion internet ou URL Neon incorrecte. Vérifie la connexion et l'URL.
- **Les logs montrent des erreurs de sync** → Vérifie que `CLOUD_DB_URL` est correct et que ta BD Neon est bien initialisée (étape 2).

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

## Checklist finale avant de remettre les clés au client

- [ ] BD Neon créée et initialisée (étape 1-2)
- [ ] `.env` du client préparé avec `CLOUD_DB_URL` correct (étape 3)
- [ ] Backend installé et démarre sans erreur (étape 4)
- [ ] Logs affichent `Mode sync: hybrid` (étape 5)
- [ ] Une vente test créée dans l'app Flutter
- [ ] La vente apparaît dans Neon après ~30 secondes
- [ ] L'app fonctionne sans internet (mode offline)
- [ ] L'app re-synchronise après reconnexion internet
- [ ] Plusieurs utilisateurs voient les mêmes données en temps réel

---

## En cas de problème

### Mode sync persistant "offline-fallback" ou "local-only"

**Causes possibles :**
1. `CLOUD_DB_URL` absent ou vide dans `.env`
2. Connection string Neon incorrecte
3. Pas d'accès internet

**Solutions :**
```powershell
# Vérifie que CLOUD_DB_URL est définie
Get-Content "backend\.env" | Select-String CLOUD_DB_URL

# Redémarre le backend après correction
```

### Les données ne se synchronisent pas entre utilisateurs

**Causes possibles :**
1. Tous les backends ne pointent pas vers la **même** `CLOUD_DB_URL`
2. BD Neon non initialisée correctement
3. Erreurs de sync dans les logs

**Solutions :**
- Vérifie que tous les `.env` utilisent la même `CLOUD_DB_URL`
- Attends 30-60 secondes (cycle de sync automatique)
- Consulte les logs du backend pour des erreurs détaillées
- Relance le backend

### Erreur "AUTOINCREMENT" ou "date_creation specified more than once"

→ Les migrations SQLite sont en place au lieu de PostgreSQL
→ Refais l'étape 2.1 en copiant correctement les migrations PostgreSQL

### Réinitialiser complètement la synchronisation (cas extrême)

**⚠️ ATTENTION : Cette opération efface TOUTES les données Neon**

1. Accède à [console.neon.tech](https://console.neon.tech)
2. Va dans le SQL Editor
3. Exécute (à tes risques) :
```sql
TRUNCATE TABLE ventes, ventes_detail, ventes_proforma CASCADE;
TRUNCATE TABLE produits, categories_produits CASCADE;
TRUNCATE TABLE utilisateurs, user_roles CASCADE;
TRUNCATE TABLE fournisseurs, approvisionnements CASCADE;
TRUNCATE TABLE historique_stock, stock_inventories CASCADE;
TRUNCATE TABLE cash_movements, cash_sessions CASCADE;
TRUNCATE TABLE financial_movements CASCADE;
TRUNCATE TABLE comptes_clients CASCADE;
TRUNCATE TABLE transferts_stock CASCADE;
```
4. Redémarre le backend — la sync initiale se relancera automatiquement
