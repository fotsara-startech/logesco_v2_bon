# Guide de Configuration Complète Neon pour LOGESCO

Ce guide explique comment configurer une nouvelle base de données Neon PostgreSQL pour un nouveau client LOGESCO.

## 📋 Prérequis

1. Une base de données Neon créée et accessible
2. L'URL de connexion Neon (format: `postgresql://user:password@host/database?sslmode=require`)
3. Node.js et npm installés
4. Le projet LOGESCO cloné

## 🚀 Méthode Rapide (Recommandée)

### Étape 1: Configuration de l'environnement

Ajoutez votre URL Neon dans le fichier `.env`:

```env
CLOUD_DB_URL="postgresql://neondb_owner:votre_password@ep-xxx.us-east-1.aws.neon.tech/neondb?sslmode=require"
```

### Étape 2: Migration initiale

Exécutez la migration Prisma pour créer toutes les tables:

```bash
cd backend
npx prisma migrate deploy
```

### Étape 3: Configuration des triggers et date_modification

Exécutez le script automatique:

```bash
node setup-neon.js
```

Ce script va:
- ✅ Créer la fonction `update_date_modification()`
- ✅ Ajouter la colonne `date_modification` à toutes les tables
- ✅ Créer les triggers pour toutes les tables
- ✅ Initialiser les valeurs de `date_modification` pour les données existantes
- ✅ Afficher un rapport de vérification

### Étape 4: Vérification

Redémarrez votre serveur backend et vérifiez les logs. Vous ne devriez plus voir:

```
⚠️  stock_inventories: pas de date_modification sur Neon, pull complet...
⚠️  inventory_items: pas de date_modification sur Neon, pull complet...
```

## 🔧 Méthode Manuelle (Alternative)

Si vous préférez exécuter le SQL manuellement:

### Via Neon Console

1. Connectez-vous à [Neon Console](https://console.neon.tech/)
2. Sélectionnez votre projet
3. Allez dans **SQL Editor**
4. Copiez le contenu du fichier `prisma/migrations_pg/COMPLETE_NEON_SETUP.sql`
5. Collez et exécutez

### Via psql

```bash
psql "postgresql://user:password@host/database?sslmode=require" -f prisma/migrations_pg/COMPLETE_NEON_SETUP.sql
```

## 📊 Contenu du Script Complet

Le fichier `COMPLETE_NEON_SETUP.sql` regroupe:

1. **Fonction trigger** `update_date_modification()`
2. **Tables de base** (clients, utilisateurs, boutiques, produits, etc.)
3. **Tables transactionnelles** (ventes, commandes, mouvements, etc.)
4. **Tables de comptes** (comptes_clients, comptes_fournisseurs)
5. **Tables de stock** (stock, stock_boutiques, stock_inventories, inventory_items)
6. **Tables d'assignation** (user_boutique_assignments)
7. **Vérification finale** avec rapport détaillé

## 🔍 Vérification Post-Installation

### Vérifier les triggers

```sql
SELECT 
    schemaname,
    tablename,
    COUNT(*) as trigger_count
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE schemaname = 'public'
AND tgname LIKE '%date_modification%'
GROUP BY schemaname, tablename
ORDER BY tablename;
```

### Vérifier les colonnes date_modification

```sql
SELECT 
    table_name,
    column_name,
    data_type,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
AND column_name = 'date_modification'
ORDER BY table_name;
```

### Vérifier les données

```sql
SELECT 
    'stock_inventories' as table_name,
    COUNT(*) as total_rows,
    COUNT(date_modification) as rows_with_date_modification
FROM stock_inventories
UNION ALL
SELECT 
    'inventory_items',
    COUNT(*),
    COUNT(date_modification)
FROM inventory_items;
```

## 🎯 Impact sur la Synchronisation

### Avant la configuration

- ❌ Pull complet de toutes les données à chaque sync
- ❌ Charge réseau élevée (673+ enregistrements pour inventory_items)
- ❌ Temps de synchronisation long
- ❌ Logs répétitifs avec avertissements

### Après la configuration

- ✅ Pull incrémental uniquement des données modifiées
- ✅ Charge réseau minimale
- ✅ Temps de synchronisation rapide
- ✅ Logs propres sans avertissements

## 🐛 Dépannage

### Erreur: "function update_date_modification() does not exist"

Le script crée automatiquement la fonction. Si l'erreur persiste:

```sql
CREATE OR REPLACE FUNCTION update_date_modification()
RETURNS TRIGGER AS $$
BEGIN
    NEW.date_modification = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

### Erreur: "column date_modification does not exist"

Vérifiez que la migration Prisma a bien été exécutée:

```bash
npx prisma migrate deploy
```

### Erreur: "permission denied"

Assurez-vous que votre utilisateur Neon a les droits nécessaires:

```sql
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO votre_utilisateur;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO votre_utilisateur;
```

## 📝 Notes Importantes

1. **Idempotence**: Le script peut être exécuté plusieurs fois sans problème grâce aux clauses `IF NOT EXISTS` et `DROP TRIGGER IF EXISTS`

2. **Données existantes**: Le script initialise automatiquement `date_modification` pour les données existantes en utilisant d'autres colonnes de date (date_creation, date_vente, etc.)

3. **Performance**: L'ajout de colonnes et de triggers n'a pas d'impact significatif sur les performances

4. **Compatibilité**: Le script est compatible avec PostgreSQL 12+ (utilisé par Neon)

## 🔄 Maintenance

### Ajouter une nouvelle table

Si vous ajoutez une nouvelle table qui nécessite la synchronisation:

1. Ajoutez la colonne dans le schéma Prisma:
```prisma
model NouvelleTable {
  id               Int      @id @default(autoincrement())
  // ... autres champs
  dateModification DateTime @updatedAt @map("date_modification")
  
  @@map("nouvelle_table")
}
```

2. Créez une migration:
```bash
npx prisma migrate dev --name add_nouvelle_table
```

3. Ajoutez le trigger sur Neon:
```sql
DROP TRIGGER IF EXISTS update_nouvelle_table_date_modification ON nouvelle_table;
CREATE TRIGGER update_nouvelle_table_date_modification
    BEFORE UPDATE ON nouvelle_table
    FOR EACH ROW
    EXECUTE FUNCTION update_date_modification();
```

## 📞 Support

Pour toute question ou problème:
1. Vérifiez les logs du serveur backend
2. Consultez la documentation Neon: https://neon.tech/docs
3. Vérifiez les issues GitHub du projet

## 📚 Fichiers Associés

- `prisma/migrations_pg/COMPLETE_NEON_SETUP.sql` - Script SQL complet
- `setup-neon.js` - Script Node.js automatique
- `fix-inventory-neon.js` - Script spécifique pour inventory (legacy)
- `GUIDE_TRIGGERS_NEON.md` - Guide détaillé des triggers
- `ARCHITECTURE_SYNC_EXPLICATION.md` - Architecture de synchronisation

---

**Version**: 1.0  
**Date**: 2026-04-29  
**Auteur**: Équipe LOGESCO
