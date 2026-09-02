# Changelog - Configuration Neon

## 2026-04-29 - Version 1.0 - Configuration Unifiée

### 🎯 Objectif
Créer un script SQL unique regroupant toutes les migrations nécessaires pour configurer une nouvelle base de données Neon pour LOGESCO.

### ✅ Problèmes Résolus

#### 1. Sessions de Caisse - `boutiqueId` null
**Problème**: Le `boutiqueId` était toujours `null` dans la table `cash_sessions` malgré que le backend le reçoive correctement.

**Cause**: 
- Le `boutiqueId` n'était pas inclus dans les réponses API formatées
- Le middleware de sync utilisait des noms de colonnes en camelCase au lieu de snake_case
- Le pull depuis Neon écrasait la valeur locale avec `null`

**Solution**:
- Ajout de `boutiqueId` dans toutes les réponses formatées (`formattedSession`)
- Correction des noms de colonnes dans `sync-middleware.js` (camelCase → snake_case)
- Fichiers modifiés:
  - `backend/src/routes/cash-sessions.js` (3 endroits)
  - `backend/src/middleware/sync-middleware.js`

#### 2. Inventaires - Synchronisation répétitive
**Problème**: Les tables `stock_inventories` et `inventory_items` étaient synchronisées en mode "pull complet" à chaque fois, générant des logs répétitifs.

**Cause**: Ces tables n'avaient pas de colonne `date_modification` sur Neon, empêchant la synchronisation incrémentale.

**Solution**:
- Ajout de la colonne `date_modification` sur Neon
- Création des triggers pour mettre à jour automatiquement cette colonne
- Script: `fix-inventory-neon.js`

### 📦 Fichiers Créés

#### Scripts SQL
1. **`prisma/migrations_pg/COMPLETE_NEON_SETUP.sql`** ⭐
   - Script SQL complet regroupant toutes les migrations
   - Sections:
     - Fonction trigger `update_date_modification()`
     - Tables de base (clients, utilisateurs, boutiques, etc.)
     - Tables transactionnelles (ventes, commandes, mouvements, etc.)
     - Tables de comptes (comptes_clients, comptes_fournisseurs)
     - Tables de stock (stock, stock_boutiques, inventories)
     - Tables d'assignation (user_boutique_assignments)
     - Vérification finale avec rapport

2. **`prisma/migrations_pg/fix_inventory_date_modification.sql`**
   - Script spécifique pour les inventaires (legacy, inclus dans COMPLETE_NEON_SETUP.sql)

#### Scripts Node.js
1. **`setup-neon.js`** ⭐
   - Script automatique pour exécuter COMPLETE_NEON_SETUP.sql
   - Gestion des erreurs et affichage des résultats
   - Usage: `node setup-neon.js`

2. **`fix-inventory-neon.js`**
   - Script spécifique pour les inventaires (legacy)

#### Documentation
1. **`GUIDE_SETUP_NEON_COMPLET.md`** ⭐
   - Guide détaillé complet
   - Méthodes d'installation (automatique et manuelle)
   - Vérifications post-installation
   - Dépannage
   - Maintenance

2. **`SETUP_NOUVEAU_CLIENT.md`** ⭐
   - Guide rapide en 3 étapes
   - Pour les nouveaux clients

3. **`FIX_INVENTORY_SYNC.md`**
   - Guide spécifique pour le problème des inventaires (legacy)

4. **`prisma/migrations_pg/README.md`**
   - Index des fichiers de migration
   - Guide d'utilisation

5. **`CHANGELOG_NEON_SETUP.md`** (ce fichier)
   - Historique des changements

### 🔧 Modifications du Code

#### `backend/src/routes/cash-sessions.js`
```javascript
// Ajout de boutiqueId dans formattedSession (3 endroits)
const formattedSession = {
  id: newSession.id,
  caisseId: newSession.caisseId,
  boutiqueId: newSession.boutiqueId,  // ← AJOUTÉ
  // ...
};
```

#### `backend/src/middleware/sync-middleware.js`
```javascript
// Correction des noms de colonnes pour cash_sessions
'/cash-sessions': {
  table: 'cash_sessions', model: 'cashSession',
  allowedColumns: [
    'id','caisse_id','utilisateur_id','boutique_id',  // ← snake_case
    'solde_ouverture','solde_fermeture','date_ouverture',
    'date_fermeture','is_active','metadata','solde_attendu','ecart'
  ]
},
```

#### `backend/src/services/sync-service.js`
```javascript
// Ajout de logs de debug (temporaires, retirés ensuite)
if (tableName === 'cash_sessions') {
  console.log(`🔍 [SYNC] Données envoyées à Neon:`, row);
}
```

### 📊 Impact

#### Avant
- ❌ `boutiqueId` null dans `cash_sessions`
- ❌ Pull complet de 673+ enregistrements à chaque sync pour `inventory_items`
- ❌ Logs répétitifs avec avertissements
- ❌ Charge réseau élevée
- ❌ Configuration manuelle complexe pour nouveaux clients

#### Après
- ✅ `boutiqueId` correctement synchronisé
- ✅ Pull incrémental uniquement des données modifiées
- ✅ Logs propres sans avertissements
- ✅ Charge réseau minimale
- ✅ Configuration automatique en 1 commande: `node setup-neon.js`

### 🎓 Leçons Apprises

1. **Toujours inclure tous les champs dans les réponses API** pour que le middleware de sync puisse les capturer
2. **Utiliser snake_case pour les noms de colonnes PostgreSQL** dans les configurations
3. **Ajouter date_modification à toutes les tables** pour permettre la synchronisation incrémentale
4. **Créer des scripts idempotents** qui peuvent être exécutés plusieurs fois sans problème
5. **Regrouper les migrations** pour simplifier le déploiement chez les clients

### 🔄 Processus de Setup pour Nouveau Client

**Avant** (complexe):
1. Exécuter `npx prisma migrate deploy`
2. Exécuter `add_update_triggers.sql`
3. Exécuter `add_date_modification_missing_tables.sql`
4. Exécuter `fix_inventory_date_modification.sql`
5. Vérifier manuellement chaque étape

**Après** (simple):
1. Configurer `CLOUD_DB_URL` dans `.env`
2. Exécuter `npx prisma migrate deploy`
3. Exécuter `node setup-neon.js`
4. ✅ Terminé !

### 📝 Notes Techniques

#### Fonction Trigger
```sql
CREATE OR REPLACE FUNCTION update_date_modification()
RETURNS TRIGGER AS $$
BEGIN
    NEW.date_modification = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

Cette fonction est appelée automatiquement avant chaque UPDATE sur les tables configurées.

#### Idempotence
Le script utilise:
- `ADD COLUMN IF NOT EXISTS` pour les colonnes
- `DROP TRIGGER IF EXISTS` avant `CREATE TRIGGER` pour les triggers
- `CREATE OR REPLACE FUNCTION` pour la fonction

Cela permet d'exécuter le script plusieurs fois sans erreur.

### 🚀 Prochaines Étapes

1. ✅ Tester le script sur plusieurs bases Neon
2. ✅ Documenter le processus pour l'équipe
3. ⏳ Créer un script de vérification automatique
4. ⏳ Ajouter des tests automatisés
5. ⏳ Créer un dashboard de monitoring de la sync

### 👥 Contributeurs

- Équipe LOGESCO
- Date: 2026-04-29

---

**Version**: 1.0  
**Status**: ✅ Production Ready
