# Prochaines Étapes — Déploiement du Fix

## Situation Actuelle

✅ **Complété**:
- sync-service.js reécrit avec logique robuste
- Migrations Prisma créées (`add_date_modification_columns`)
- Schema.prisma mis à jour avec les colonnes manquantes
- Documents de correction et guide créés
- Script de validation implémenté

❌ **À Faire**:
- Appliquer les migrations à votre BD locale
- Redémarrer le backend et tester
- Vérifier les logs de sync
- Valider que le pull delta fonctionne

---

## Étapes de Déploiement Local

### Étape 1: Backup de la BD Locale

**Objectif**: Avoir un backup en cas de problème

```bash
# Depuis le dossier backend
cp database/logesco.db database/logesco.db.backup.$(date +%Y%m%d_%H%M%S)

# Vérifier
ls -lh database/logesco.db*
```

### Étape 2: Appliquer les Migrations

**Objectif**: Ajouter les colonnes `date_modification` aux tables

```bash
# Depuis le dossier backend
npx prisma migrate deploy

# Output attendu:
# 1 migration needed
# Database migration finished
```

#### Si vous avez une erreur

```bash
# Vérifier l'état des migrations
npx prisma migrate status

# Réinitialiser si nécessaire (ATTENTION: perte de données!)
# npx prisma migrate reset --force
```

### Étape 3: Vérifier les Colonnes

**Objectif**: S'assurer que les colonnes existent dans SQLite

```bash
# Depuis le dossier backend
sqlite3 database/logesco.db

# Dans SQLite CLI:
.schema transactions_comptes
.schema stock_inventories
.schema inventory_items

# Vérifier qu'il y a une colonne `date_modification` dans chaque table

# Quitter SQLite
.quit
```

**Output attendu** (pour `transactions_comptes`):
```sql
CREATE TABLE "transactions_comptes" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  "type_compte" TEXT NOT NULL,
  "compte_id" INTEGER NOT NULL,
  ...
  "date_transaction" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "date_modification" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  ...
);
```

### Étape 4: Redémarrer le Backend

**Objectif**: Charger la BD mise à jour et lancer le sync

```bash
# Arrêter le backend (Ctrl+C si en cours d'exécution)

# Depuis le dossier backend
npm run dev

# Logs attendus:
# ☁️  CLOUD_DB_URL non défini — mode 100% local activé
# 🔄 SyncService V2: initialisation avec Event Sourcing...
# ✅ Aucune opération en attente — journal à jour
# ✅ SyncService V2 démarré (Event Sourcing + Hybrid Mode)
```

### Étape 5: Tester la Synchronisation

**Objectif**: Vérifier que tout fonctionne sans erreurs

```bash
# Terminal 1: Backend en cours d'exécution (npm run dev)

# Terminal 2: Tester un endpoint
curl http://localhost:8080/api/v1/accounts/suppliers \
  -H "Authorization: Bearer YOUR_TOKEN"

# Vérifier les logs du Terminal 1:
# Pas de "date_modification" errors
# Les sync operations doivent se faire normalement
```

### Étape 6: Valider le Schéma

**Objectif**: Confirmer que toutes les migrations sont en place

```bash
# Depuis le dossier backend
node validate-schema-migrations.js

# Output:
# ✅ Table: transactions_comptes
#    ✓ id
#    ✓ date_transaction
#    ✓ date_modification
#
# ✅ Toutes les migrations sont appliquées correctement!
```

---

## Troubleshooting

### Problème 1: "FAILED validate.db Migration failed"

**Solution**:
```bash
# Rollback de la migration
npx prisma migrate resolve --rolled-back add_date_modification_columns

# Réappliquer
npx prisma migrate deploy
```

### Problème 2: "column ... already exists"

**Possible que la migration a déjà été appliquée**:
```bash
# Vérifier l'état
npx prisma migrate status

# Si "up to date", tout va bien
```

### Problème 3: Toujours des erreurs "date_modification"

**Vérifier que les logs montrent le bon service**:
```bash
# Doit voir:
✅ SyncService V2 démarré (Event Sourcing + Hybrid Mode)

# PAS:
✅ SyncService V1 démarré

# Si c'est V1, vérifier que CLOUD_DB_URL est défini dans .env
# ou que vous n'avez pas une ancienne instance en cours
```

### Problème 4: Backend ne démarre pas

```bash
# 1. Vérifier les dépendances
npm install

# 2. Vérifier Prisma client
npx prisma generate

# 3. Réessayer
npm run dev
```

---

## Checklist de Validation

- [ ] Backup de BD créé
- [ ] Migrations appliquées avec succès
- [ ] Colonnes `date_modification` visibles dans SQLite
- [ ] Backend démarre sans erreurs
- [ ] Logs montrent V2 Event Sourcing
- [ ] Pas d'erreur "date_modification" dans les logs
- [ ] Test d'API réussi
- [ ] Script validate-schema-migrations.js passe

---

## Déploiement Client (Après Validation)

### Email aux Clients Existants

```
Sujet: Mise à jour LOGESCO – Synchronisation améliorée

Cher client,

Une mise à jour critique de LOGESCO est disponible.
Elle améliore significativement la synchronisation des données.

**Quand**: Ce jour-même (déploiement 0-downtime)
**Impact**: Aucun (tout automatique)
**Durée**: 5 minutes

Ce que vous verrez:
✅ Backend redémarrage (peut causer 1-2 sec déconnexion)
✅ Synchronisation automatique (2-10 min selon volume)

Pas d'action requise — tout est automatique.

Pour toute question: support@logesco.com
```

### Steps Déploiement Prod

1. **Alpha**: 1-2 clients volontaires → 24h de monitoring
2. **Beta**: 10% de la base clients → 48h de monitoring  
3. **Production**: Tous les clients → monitoring continu

---

## Monitoring Post-Déploiement

### Logs à Vérifier (24h après)

```bash
# Aucune de ces erreurs ne doit apparaître:
# ❌ table ... has no column named date_modification
# ❌ transactions_comptes merge échoué
# ❌ stock_inventories merge échoué
# ❌ inventory_items merge échoué
```

### Métriques à Tracker

- ✅ Temps de startup < 5 secondes
- ✅ Erreurs sync = 0
- ✅ Operation log vide (toutes synced)
- ✅ Clients rapportent aucun problème

---

## Documentation pour les Futurs Clients

### Inclure dans l'Installation

Tous les nouveaux clients auront automatiquement:
- ✅ Les migrations `add_date_modification_columns`
- ✅ Le schema.prisma à jour
- ✅ Le sync-service V2 avec fallback robuste
- ✅ La validation de schéma au démarrage

### Template d'Onboarding

```markdown
# 3. Synchronisation (Automatique)

LOGESCO utilise Event Sourcing pour la synchronisation:
- ✅ Aucun risque de perte de données
- ✅ Fonctionne hors-ligne
- ✅ Sync automatique quand possible
- ✅ Audit trail complet

Tout fonctionne automatiquement — pas de configuration requise.
```

---

## Questions / Support

Si vous rencontrez des problèmes:

1. **Vérifier les logs** → chercher "error" ou "❌"
2. **Valider le schéma** → `node validate-schema-migrations.js`
3. **Consulter la documentation** → `docs/EVENT_SOURCING/`
4. **Contacter le support** → support@logesco.com

---

**Document mis à jour**: 2026-06-05
**Statut**: Prêt pour déploiement
**Durée estimée**: 30 minutes (avec testing)
