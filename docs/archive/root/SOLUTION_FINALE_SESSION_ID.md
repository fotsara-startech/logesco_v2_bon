# Solution finale : Ajout de sessionId aux ventes et mouvements

## Problème

Les totaux d'entrées/sorties étaient calculés en utilisant les dates, ce qui causait des incohérences :
- Problèmes de fuseaux horaires
- Ventes/mouvements non associés à la bonne session
- Totaux toujours à 0 pour les nouvelles sessions

## Solution implémentée

Ajout d'un champ `sessionId` directement dans les tables `ventes` et `cash_movements` pour lier explicitement chaque opération à sa session.

### 1. Modifications du schéma Prisma

**Fichier** : `backend/prisma/schema.prisma`

#### Table Vente
```prisma
model Vente {
  ...
  sessionId      Int?             @map("session_id")
  ...
  session        CashSession?     @relation(fields: [sessionId], references: [id])
  
  @@index([sessionId], map: "idx_ventes_session")
}
```

#### Table CashMovement
```prisma
model CashMovement {
  ...
  sessionId        Int?           @map("session_id")
  ...
  session          CashSession?   @relation(fields: [sessionId], references: [id])
  
  @@index([sessionId], map: "idx_cash_movements_session")
}
```

#### Table CashSession
```prisma
model CashSession {
  ...
  ventes           Vente[]
  mouvements       CashMovement[]
}
```

### 2. Migration de la base de données

```bash
cd backend
npx prisma db push
npx prisma generate
```

Colonnes ajoutées :
- `ventes.session_id`
- `cash_movements.session_id`

### 3. Modifications du code backend

#### Création de vente (`backend/src/routes/sales.js`)

```javascript
// Récupérer la session active
const activeSession = await tx.cashSession.findFirst({
  where: {
    utilisateurId: req.user?.id || 1,
    isActive: true,
    dateFermeture: null
  }
});

const sessionId = activeSession ? activeSession.id : null;

// Créer la vente avec sessionId
const nouvelleVente = await tx.vente.create({
  data: {
    ...
    sessionId: sessionId,
    ...
  }
});

// Créer le mouvement de caisse avec sessionId
await prisma.cashMovement.create({
  data: {
    caisseId: activeSession.caisseId,
    sessionId: activeSession.id,  // ← Ajouté
    type: 'vente',
    ...
  }
});
```

#### Paiement de dette (`backend/src/routes/customers.js`)

```javascript
// Créer le mouvement avec sessionId
await tx.cashMovement.create({
  data: {
    caisseId: caisseActive.id,
    sessionId: sessionActive ? sessionActive.id : null,  // ← Ajouté
    type: 'entree',
    ...
  }
});
```

#### Calcul des totaux (`backend/src/routes/cash-sessions.js`)

```javascript
// AVANT : Calcul basé sur les dates (problématique)
const entrees = await prisma.cashMovement.aggregate({
  where: {
    caisseId: session.caisseId,
    dateCreation: {
      gte: session.dateOuverture,
      lte: session.dateFermeture
    },
    type: { in: ['entree', 'vente'] }
  },
  _sum: { montant: true }
});

// APRÈS : Calcul basé sur sessionId (fiable)
const entrees = await prisma.cashMovement.aggregate({
  where: {
    sessionId: session.id,  // ← Simple et fiable
    type: { in: ['entree', 'vente'] }
  },
  _sum: { montant: true }
});
```

## Avantages de cette solution

1. **Fiabilité** : Lien direct entre opération et session
2. **Simplicité** : Plus besoin de calculs complexes avec les dates
3. **Performance** : Requêtes plus rapides avec index sur sessionId
4. **Précision** : Pas de problèmes de fuseaux horaires
5. **Traçabilité** : Chaque opération est explicitement liée à sa session

## Test de la solution

### 1. Redémarrer le backend

```bash
cd backend
npm start
```

### 2. Créer une nouvelle session

1. Ouvrir une session de caisse
2. Noter l'ID de la session

### 3. Effectuer des opérations

1. Créer une vente → Vérifier que `sessionId` est renseigné
2. Payer une dette → Vérifier que `sessionId` est renseigné
3. Créer une dépense → Vérifier que `sessionId` est renseigné

### 4. Fermer la session et vérifier les totaux

1. Fermer la session
2. Consulter les détails
3. Vérifier que les totaux sont corrects

### 5. Script de test

```bash
cd backend
node test-session-totals.js
```

Résultat attendu :
```
Session X:
   💰 Total entrées: XXXX FCFA
   💸 Total dépenses: XXXX FCFA
   ✅ Cohérent
```

## Vérification dans la base de données

```sql
-- Vérifier qu'une vente a bien un sessionId
SELECT id, numero_vente, session_id, montant_paye 
FROM ventes 
ORDER BY date_vente DESC 
LIMIT 5;

-- Vérifier qu'un mouvement a bien un sessionId
SELECT id, type, montant, session_id, description 
FROM cash_movements 
ORDER BY date_creation DESC 
LIMIT 5;

-- Vérifier les totaux d'une session
SELECT 
  s.id,
  COUNT(DISTINCT v.id) as nb_ventes,
  COUNT(DISTINCT m.id) as nb_mouvements,
  SUM(CASE WHEN m.type IN ('vente', 'entree') THEN m.montant ELSE 0 END) as total_entrees,
  SUM(CASE WHEN m.type = 'sortie' THEN m.montant ELSE 0 END) as total_sorties
FROM cash_sessions s
LEFT JOIN ventes v ON v.session_id = s.id
LEFT JOIN cash_movements m ON m.session_id = s.id
WHERE s.id = X
GROUP BY s.id;
```

## Migration des données existantes (optionnel)

Pour associer les ventes/mouvements existants à leurs sessions :

```javascript
// Script à créer si nécessaire
// Associer les ventes aux sessions basé sur les dates
UPDATE ventes v
SET session_id = (
  SELECT s.id 
  FROM cash_sessions s 
  WHERE v.date_vente >= s.date_ouverture 
  AND (s.date_fermeture IS NULL OR v.date_vente <= s.date_fermeture)
  AND v.vendeur_id = s.utilisateur_id
  LIMIT 1
)
WHERE session_id IS NULL;
```

## Fichiers modifiés

### Schéma
- `backend/prisma/schema.prisma`

### Backend
- `backend/src/routes/sales.js` - Ajout sessionId à vente et mouvement
- `backend/src/routes/customers.js` - Ajout sessionId au paiement dette
- `backend/src/routes/cash-sessions.js` - Calcul basé sur sessionId

### Migration
- `backend/prisma/migrations/add_session_id_to_ventes_and_movements.sql`

## Résumé

Cette solution résout définitivement le problème des totaux en créant un lien explicite entre chaque opération et sa session. Plus besoin de calculs complexes basés sur les dates, tout est maintenant simple, fiable et performant.

Les nouvelles ventes et mouvements sont automatiquement liés à la session active, garantissant des totaux toujours corrects.
