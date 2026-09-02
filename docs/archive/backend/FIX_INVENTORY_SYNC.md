# Fix : Synchronisation répétitive des inventory_items

## Problème

Les logs montrent que `stock_inventories` et `inventory_items` sont synchronisés en mode "pull complet" à chaque fois :

```
⚠️  stock_inventories: pas de date_modification sur Neon, pull complet...
⚠️  inventory_items: pas de date_modification sur Neon, pull complet...
```

Cela se produit parce que ces tables n'ont pas de colonne `date_modification` sur Neon, donc le système ne peut pas faire de synchronisation incrémentale.

## Solution

Exécuter le script SQL suivant sur votre base de données Neon pour ajouter la colonne `date_modification` et les triggers nécessaires.

### Méthode 1 : Via l'interface web Neon

1. Connectez-vous à [Neon Console](https://console.neon.tech/)
2. Sélectionnez votre projet
3. Allez dans **SQL Editor**
4. Copiez et exécutez le contenu du fichier : `prisma/migrations_pg/fix_inventory_date_modification.sql`

### Méthode 2 : Via psql en ligne de commande

```bash
# Depuis le dossier backend
psql "postgresql://neondb_owner:npg_yIX5v0stjMlq@ep-still-snow-a41z9iyh.us-east-1.aws.neon.tech/neondb?sslmode=require" -f prisma/migrations_pg/fix_inventory_date_modification.sql
```

### Méthode 3 : Via Node.js (script automatique)

Créez et exécutez ce script :

```javascript
// fix-inventory-neon.js
const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

async function fixInventoryTables() {
  const client = new Client({
    connectionString: process.env.CLOUD_DB_URL
  });

  try {
    await client.connect();
    console.log('✅ Connecté à Neon');

    const sql = fs.readFileSync(
      path.join(__dirname, 'prisma/migrations_pg/fix_inventory_date_modification.sql'),
      'utf8'
    );

    await client.query(sql);
    console.log('✅ Migration exécutée avec succès');

    // Vérification
    const result = await client.query(`
      SELECT 
        'stock_inventories' as table_name,
        COUNT(*) as total_rows,
        COUNT(date_modification) as rows_with_date_modification
      FROM stock_inventories
      UNION ALL
      SELECT 
        'inventory_items' as table_name,
        COUNT(*) as total_rows,
        COUNT(date_modification) as rows_with_date_modification
      FROM inventory_items
    `);

    console.log('\n📊 Vérification :');
    console.table(result.rows);

  } catch (error) {
    console.error('❌ Erreur:', error.message);
  } finally {
    await client.end();
  }
}

fixInventoryTables();
```

Puis exécutez :

```bash
node fix-inventory-neon.js
```

## Vérification

Après avoir exécuté le script, redémarrez votre serveur backend. Les logs ne devraient plus afficher :

```
⚠️  stock_inventories: pas de date_modification sur Neon, pull complet...
⚠️  inventory_items: pas de date_modification sur Neon, pull complet...
```

Au lieu de cela, vous devriez voir des synchronisations incrémentielles normales.

## Impact

- **Avant** : Pull complet de 673+ enregistrements à chaque synchronisation
- **Après** : Pull incrémental uniquement des enregistrements modifiés depuis la dernière sync

Cela réduira considérablement la charge réseau et le temps de synchronisation.
