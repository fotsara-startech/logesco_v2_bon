# Migrations PostgreSQL pour Neon

Ce dossier contient tous les scripts SQL nécessaires pour configurer et maintenir une base de données Neon PostgreSQL pour LOGESCO.

## 📁 Fichiers

### 🌟 Fichier Principal (À utiliser pour les nouveaux clients)

- **`COMPLETE_NEON_SETUP.sql`** ⭐
  - Script complet regroupant TOUTES les migrations
  - À exécuter une seule fois pour un nouveau client
  - Contient: fonction trigger + ajout date_modification + création triggers
  - **C'est le seul fichier dont vous avez besoin !**

### 📜 Fichiers Historiques (Pour référence uniquement)

- `add_update_triggers.sql` - Triggers de base (inclus dans COMPLETE_NEON_SETUP.sql)
- `add_date_modification_missing_tables.sql` - Tables transactionnelles (inclus dans COMPLETE_NEON_SETUP.sql)
- `fix_inventory_date_modification.sql` - Fix inventory (inclus dans COMPLETE_NEON_SETUP.sql)

### 📂 Dossier de Migration Initiale

- `20260423221732_init_postgresql/` - Migration Prisma initiale (créée automatiquement)

## 🚀 Utilisation

### Pour un nouveau client

**Option 1: Script automatique (Recommandé)**
```bash
cd backend
node setup-neon.js
```

**Option 2: Exécution manuelle**
```bash
# Via psql
psql "postgresql://..." -f prisma/migrations_pg/COMPLETE_NEON_SETUP.sql

# Ou via Neon Console SQL Editor
# Copier/coller le contenu de COMPLETE_NEON_SETUP.sql
```

## 📖 Documentation

- `../../SETUP_NOUVEAU_CLIENT.md` - Guide rapide (3 étapes)
- `../../GUIDE_SETUP_NEON_COMPLET.md` - Guide détaillé complet
- `../../GUIDE_TRIGGERS_NEON.md` - Documentation des triggers

## ⚠️ Important

- **Ne pas** exécuter les fichiers historiques séparément
- **Toujours** utiliser `COMPLETE_NEON_SETUP.sql` pour les nouveaux clients
- Le script est **idempotent** (peut être exécuté plusieurs fois sans problème)

## 🔄 Ordre d'Exécution pour Nouveau Client

1. Créer la base de données Neon
2. Configurer `CLOUD_DB_URL` dans `.env`
3. Exécuter `npx prisma migrate deploy` (crée les tables)
4. Exécuter `node setup-neon.js` (configure les triggers)
5. Redémarrer le serveur backend

## 📊 Vérification

Après l'exécution, vérifiez que:
- ✅ Toutes les tables ont la colonne `date_modification`
- ✅ Tous les triggers sont créés
- ✅ Les logs ne montrent plus de "pull complet"

## 🐛 Dépannage

Si vous rencontrez des problèmes:
1. Consultez `../../GUIDE_SETUP_NEON_COMPLET.md`
2. Vérifiez les logs du serveur backend
3. Vérifiez que la migration Prisma a réussi

---

**Dernière mise à jour**: 2026-04-29
