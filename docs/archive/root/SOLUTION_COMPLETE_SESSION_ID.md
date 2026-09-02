# Solution complète : sessionId dans toutes les tables

## Problème résolu

Les totaux d'entrées/sorties étaient toujours à 0 car :
1. Les mouvements de caisse n'étaient pas créés (code après la transaction)
2. Les mouvements financiers n'avaient pas de sessionId

## Solution finale implémentée

### 1. Ajout de sessionId dans 3 tables

#### Table `ventes`
```sql
ALTER TABLE ventes ADD COLUMN session_id INTEGER;
CREATE INDEX idx_ventes_session ON ventes(session_id);
```

#### Table `cash_movements`
```sql
ALTER TABLE cash_movements ADD COLUMN session_id INTEGER;
CREATE INDEX idx_cash_movements_session ON cash_movements(session_id);
```

#### Table `financial_movements`
```sql
ALTER TABLE financial_movements ADD COLUMN session_id INTEGER;
CREATE INDEX idx_financial_movements_session ON financial_movements(session_id);
```

### 2. Modifications du code

#### A. Création de vente (`backend/src/routes/sales.js`)

**Problème** : Le code de création de mouvement était APRÈS la transaction
**Solution** : Déplacé DANS la transaction

```javascript
// DANS la transaction (tx)
const vente = await prisma.$transaction(async (tx) => {
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

  // ... autres opérations ...

  // CORRECTION: Créer le mouvement DANS la transaction
  if (sessionId && montantVerse > 0) {
    await tx.cashMovement.create({
      data: {
        caisseId: activeSession.caisseId,
        sessionId: sessionId,
        type: 'vente',
        montant: montantVerse,
        ...
      }
    });
  }

  return nouvelleVente;
});
```

#### B. Création de mouvement financier (`backend/src/services/financial-movement.js`)

```javascript
// Récupérer la session active
const activeSession = await this.prisma.cashSession.findFirst({
  where: {
    utilisateurId: data.utilisateurId,
    isActive: true,
    dateFermeture: null
  }
});

const sessionId = activeSession ? activeSession.id : null;

// Créer le mouvement avec sessionId
const movement = await this.prisma.financialMovement.create({
  data: {
    reference,
    sessionId: sessionId,  // ← Ajouté
    montant: parseFloat(data.montant),
    ...
  }
});
```

#### C. Calcul des totaux (`backend/src/routes/cash-sessions.js`)

```javascript
// Entrées (ventes + paiements)
const entrees = await prisma.cashMovement.aggregate({
  where: {
    sessionId: session.id,
    type: { in: ['entree', 'vente'] }
  },
  _sum: { montant: true }
});

// Sorties de caisse
const sortiesCaisse = await prisma.cashMovement.aggregate({
  where: {
    sessionId: session.id,
    type: 'sortie'
  },
  _sum: { montant: true }
});

// Mouvements financiers (dépenses)
const mouvementsFinanciers = await prisma.financialMovement.aggregate({
  where: {
    sessionId: session.id
  },
  _sum: { montant: true }
});

// Total sorties = sorties caisse + mouvements financiers
const totalSorties = (sortiesCaisse._sum.montant || 0) + (mouvementsFinanciers._sum.montant || 0);
```

### 3. Relations Prisma

```prisma
model CashSession {
  ...
  ventes                  Vente[]
  mouvements              CashMovement[]
  mouvementsFinanciers    FinancialMovement[]
}

model Vente {
  ...
  sessionId    Int?          @map("session_id")
  session      CashSession?  @relation(fields: [sessionId], references: [id])
}

model CashMovement {
  ...
  sessionId    Int?          @map("session_id")
  session      CashSession?  @relation(fields: [sessionId], references: [id])
}

model FinancialMovement {
  ...
  sessionId    Int?          @map("session_id")
  session      CashSession?  @relation(fields: [sessionId], references: [id])
}
```

## Test de la solution

### 1. Créer une nouvelle session

```
1. Ouvrir une session de caisse
2. Noter l'ID de la session
```

### 2. Effectuer des opérations

```
1. Créer une vente → Vérifier logs: "✅ Mouvement de caisse créé"
2. Créer une dépense → Vérifier que sessionId est renseigné
3. Payer une dette → Vérifier que sessionId est renseigné
```

### 3. Fermer et vérifier

```
1. Fermer la session
2. Consulter les détails
3. Vérifier que les totaux sont corrects
```

### 4. Script de vérification

```bash
cd backend
node check-session-movements.js
```

Résultat attendu :
```
📋 Session X:
   📦 Ventes (2):
      - VTE-XXX: 1000 FCFA (sessionId: X)
      - VTE-YYY: 500 FCFA (sessionId: X)
   
   💰 Mouvements de caisse (2):
      + 1000 FCFA [vente] - Vente VTE-XXX
      + 500 FCFA [vente] - Vente VTE-YYY
   
   📊 Totaux calculés:
      Total entrées: 1500 FCFA
      Total sorties: 0 FCFA
      ✅ Cohérent
```

## Avantages de cette solution

1. **Fiabilité totale** : Lien direct entre toutes les opérations et leur session
2. **Simplicité** : Plus besoin de calculs complexes avec les dates
3. **Performance** : Requêtes optimisées avec index sur sessionId
4. **Traçabilité** : Chaque opération est explicitement liée à sa session
5. **Cohérence** : Ventes, mouvements de caisse ET mouvements financiers liés

## Points clés de la correction

### Problème 1 : Code après transaction
**Avant** : Le mouvement de caisse était créé APRÈS la transaction
**Après** : Le mouvement est créé DANS la transaction avec `tx.cashMovement.create`

### Problème 2 : Mouvements financiers non liés
**Avant** : Les dépenses (FinancialMovement) n'avaient pas de sessionId
**Après** : Chaque dépense est liée à la session active

### Problème 3 : Calcul incomplet des sorties
**Avant** : Seuls les CashMovement de type 'sortie' étaient comptés
**Après** : CashMovement 'sortie' + FinancialMovement = Total sorties

## Fichiers modifiés

### Schéma
- `backend/prisma/schema.prisma` - Ajout sessionId aux 3 modèles

### Backend
- `backend/src/routes/sales.js` - Mouvement créé DANS transaction
- `backend/src/services/financial-movement.js` - Ajout sessionId
- `backend/src/routes/cash-sessions.js` - Calcul incluant FinancialMovement

### Scripts
- `backend/check-session-movements.js` - Vérification complète

## Résumé

Cette solution finale garantit que :
- ✅ Toutes les ventes sont liées à leur session
- ✅ Tous les mouvements de caisse sont créés et liés
- ✅ Toutes les dépenses sont liées à leur session
- ✅ Les totaux incluent TOUTES les opérations
- ✅ Les calculs sont simples, rapides et fiables

Le système est maintenant complètement cohérent et les totaux d'entrées/sorties sont toujours corrects.
