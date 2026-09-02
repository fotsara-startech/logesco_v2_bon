# Synchronisation des Mouvements Financiers et de Caisse Activée

## Changements Effectués

### ✅ Tables Maintenant Synchronisées

1. **financial_movements** (Mouvements Financiers)
   - Dépenses et revenus de chaque boutique
   - Isolés par `boutiqueId`
   - Synchronisés vers Neon

2. **cash_movements** (Mouvements de Caisse)
   - Traçabilité de chaque opération de caisse
   - Isolés par `boutiqueId`
   - Synchronisés vers Neon

### Modifications Apportées

#### 1. Middleware de Sync (`backend/src/middleware/sync-middleware.js`)

**Avant**:
```javascript
'/financial-movements': { 
  skip: true  // Désactivé
},
```

**Après**:
```javascript
'/financial-movements': { 
  table: 'financial_movements', 
  model: 'financialMovement',
  allowedColumns: [
    'id','reference','sessionId','boutiqueId','montant','categorieId',
    'description','date','utilisateurId','notes','dateCreation','dateModification'
  ]
},
```

#### 2. Service Financial Movement (`backend/src/services/financial-movement.js`)

**Ajouté**: Enqueue du cash_movement après création
```javascript
const cashMovement = await this.prisma.cashMovement.create({...});

// Enqueue le mouvement de caisse pour sync
if (this.syncService) {
  await this.syncService.enqueue('cash_movements', 'INSERT', cashMovement);
}
```

#### 3. Service de Sync (`backend/src/services/sync-service.js`)

**Ajouté aux PULL_TABLES**:
```javascript
const PULL_TABLES = [
  // ...
  'cash_sessions',
  'cash_movements',        // ← Ajouté
  'financial_movements',   // ← Ajouté
  'ventes',
  // ...
];
```

**Ajouté à l'ordre de priorité**:
```javascript
CASE table_name
  WHEN 'cash_sessions' THEN 7
  WHEN 'cash_movements' THEN 10        // ← Ajouté
  WHEN 'financial_movements' THEN 11   // ← Ajouté
  WHEN 'ventes' THEN 12
```

## Comment Ça Fonctionne

### Création d'une Dépense

```
1. User crée une dépense (boutiqueId = 7)
   ↓
2. Backend crée financial_movement (boutiqueId = 7)
   ↓
3. Middleware enqueue financial_movement
   ↓
4. Backend crée cash_movement (boutiqueId = 7)
   ↓
5. Service enqueue cash_movement
   ↓
6. Backend met à jour cash_session
   ↓
7. Service enqueue cash_session
   ↓
8. Sync service envoie tout à Neon (30s)
   ↓
9. Neon contient:
   - financial_movement (boutiqueId = 7) ✅
   - cash_movement (boutiqueId = 7) ✅
   - cash_session (boutiqueId = 7) ✅
```

### Isolation par Boutique

Chaque boutique voit seulement ses propres données grâce au filtre `boutiqueId`:

**Boutique A (boutiqueId = 7)**:
```sql
SELECT * FROM financial_movements WHERE boutique_id = 7;
-- Voit seulement ses dépenses
```

**Boutique B (boutiqueId = 8)**:
```sql
SELECT * FROM financial_movements WHERE boutique_id = 8;
-- Voit seulement ses dépenses
```

## Test de Vérification

### Étape 1: Redémarrer le Backend

```bash
# Arrêter le backend (Ctrl+C)
# Redémarrer:
npm start
```

### Étape 2: Créer une Dépense

- Ouvrir l'app
- Créer un mouvement financier
- Noter le montant et l'heure

### Étape 3: Vérifier la Queue

```bash
node debug-sync-queue.js
```

**Attendu**:
```
financial_movements (INSERT): 1 synced
cash_movements (INSERT): 1 synced
cash_sessions (UPDATE): 1 synced
cash_registers (UPDATE): 1 synced
```

### Étape 4: Vérifier Neon

```bash
node check-neon-data.js
```

Devrait montrer les données synchronisées.

### Étape 5: Vérifier les Mouvements Financiers dans Neon

Créons un script pour vérifier:

```bash
node check-financial-movements-neon.js
```

## Script de Vérification

Créez `backend/check-financial-movements-neon.js`:

```javascript
require('dotenv').config();
const { Pool } = require('pg');

async function check() {
  const pool = new Pool({
    connectionString: process.env.CLOUD_DB_URL,
    ssl: { rejectUnauthorized: false }
  });

  try {
    // Check financial_movements
    const fm = await pool.query(
      'SELECT COUNT(*) as count FROM financial_movements'
    );
    console.log(`📊 Financial Movements in Neon: ${fm.rows[0].count}`);

    // Check cash_movements
    const cm = await pool.query(
      'SELECT COUNT(*) as count FROM cash_movements'
    );
    console.log(`📊 Cash Movements in Neon: ${cm.rows[0].count}`);

    // Recent financial movements
    const recent = await pool.query(
      'SELECT id, reference, montant, boutique_id FROM financial_movements ORDER BY id DESC LIMIT 5'
    );
    console.log('\n💰 Recent Financial Movements:');
    for (const row of recent.rows) {
      console.log(`   ${row.reference}: ${row.montant} FCFA (Boutique ${row.boutique_id})`);
    }

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await pool.end();
  }
}

check();
```

## Avantages de la Synchronisation

### ✅ Avantages

1. **Historique Partagé**: Tous les utilisateurs voient les mêmes mouvements financiers
2. **Rapports Consolidés**: Rapports en temps réel depuis Neon
3. **Traçabilité Complète**: Chaque opération est tracée et synchronisée
4. **Isolation par Boutique**: Chaque boutique voit seulement ses données

### ⚠️ Points d'Attention

1. **Plus de Données**: Plus de trafic réseau (mais acceptable)
2. **Confidentialité**: Assurée par le filtre `boutiqueId`
3. **Performance**: Cycle de sync de 30 secondes reste acceptable

## Vérification Multi-Utilisateur

### Test 1: Même Boutique

1. **User A** (Boutique 7): Crée une dépense de 1000 FCFA
2. **User B** (Boutique 7): Devrait voir la dépense après 30 secondes
3. ✅ Les deux utilisateurs voient la même dépense

### Test 2: Boutiques Différentes

1. **User A** (Boutique 7): Crée une dépense de 1000 FCFA
2. **User C** (Boutique 8): Ne devrait PAS voir la dépense
3. ✅ Isolation par boutique fonctionne

## Logs Attendus

Après avoir créé une dépense:

```
✅ Mouvement financier créé: MF-20260425-XXXX - 1000€ - boutiqueId: 7
💰 Session de caisse mise à jour:
   Solde attendu avant: 180000 FCFA
   Dépense: -1000 FCFA
   Solde attendu après: 179000 FCFA
✅ Caisse mise à jour: -1000 FCFA
📤 Push 4 opération(s) vers Neon...
   ✅ financial_movements synced
   ✅ cash_movements synced
   ✅ cash_sessions synced
   ✅ cash_registers synced
```

## Résolution de Problèmes

### Problème: financial_movements pas synchronisé

**Solution**:
1. Vérifier que le backend a été redémarré
2. Vérifier les logs pour les erreurs
3. Exécuter `node debug-sync-queue.js`

### Problème: Données d'autres boutiques visibles

**Solution**:
1. Vérifier que l'app filtre par `boutiqueId`
2. Vérifier que `boutiqueId` est bien défini
3. Vérifier les requêtes SQL dans l'app

## Conclusion

✅ **Synchronisation Activée**

Les mouvements financiers et de caisse sont maintenant synchronisés vers Neon, avec isolation par boutique grâce au champ `boutiqueId`.

---

**Status**: ✅ Activé et prêt à tester

**Date**: 2026-04-25

**Prochaine étape**: Redémarrer le backend et tester
