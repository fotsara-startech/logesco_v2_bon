# Solution finale - Mouvement de caisse

## Problème résolu

Le mouvement financier n'était pas créé lors du paiement fournisseur car:
1. Le code utilisait le mauvais modèle (`FinancialMovement` au lieu de `CashMovement`)
2. Le code utilisait des champs qui n'existent pas (`sessionCaisse.soldeActuel`, `statut: 'ouverte'`)

## Corrections appliquées

### 1. Utilisation du bon modèle: `CashMovement`

**Modèle correct dans le schéma:**
```prisma
model CashMovement {
  id               Int            @id @default(autoincrement())
  caisseId         Int            @map("caisse_id")
  type             String         // 'ouverture', 'fermeture', 'entree', 'sortie', 'vente'
  montant          Float
  description      String?
  utilisateurId    Int?           @map("utilisateur_id")
  dateCreation     DateTime       @default(now()) @map("date_creation")
  metadata         String?        // JSON pour données supplémentaires
  
  caisse           CashRegister   @relation(...)
  utilisateur      Utilisateur?   @relation(...)
}
```

### 2. Correction de la récupération de session

**Avant:**
```javascript
sessionCaisse = await prisma.sessionCaisse.findFirst({
  where: {
    utilisateurId: req.user.id,
    statut: 'ouverte'  // ❌ Ce champ n'existe pas
  }
});
```

**Après:**
```javascript
sessionCaisse = await prisma.cashSession.findFirst({
  where: {
    utilisateurId: req.user.id,
    isActive: true  // ✅ Champ correct
  }
});
```

### 3. Création du mouvement de caisse

**Code final:**
```javascript
mouvementFinancier = await prisma.cashMovement.create({
  data: {
    caisseId: sessionCaisse.caisseId,
    type: 'sortie',
    montant: parseFloat(montant),
    description: description || `Paiement fournisseur ${fournisseur.nom}...`,
    utilisateurId: req.user.id,
    metadata: JSON.stringify({
      typeTransaction: 'paiement_fournisseur',
      fournisseurId,
      transactionCompteId: transaction.id,
      referenceType: referenceType || null,
      referenceId: referenceId || null,
      sessionCaisseId: sessionCaisse.id
    })
  }
});
```

### 4. Suppression de la vérification du solde

Le champ `soldeActuel` n'existe pas dans `CashSession`. Le solde doit être calculé à partir de:
- `soldeOuverture` + somme des mouvements de type 'entree' - somme des mouvements de type 'sortie'

Pour l'instant, la vérification du solde a été supprimée.

## Test après correction

### 1. Redémarrer le backend
```bash
restart-backend-debug.bat
```

### 2. Ouvrir une session de caisse
- Aller dans le module Caisse
- Ouvrir une session avec un solde d'ouverture

### 3. Effectuer un paiement fournisseur
1. Aller dans le compte d'un fournisseur
2. Cliquer sur "Payer le fournisseur"
3. Sélectionner une commande
4. Cocher "Créer un mouvement financier"
5. Confirmer le paiement

### 4. Vérifier le mouvement créé

**SQL:**
```sql
-- Voir les mouvements de caisse récents
SELECT * FROM cash_movements 
WHERE type = 'sortie'
ORDER BY dateCreation DESC 
LIMIT 5;

-- Voir les métadonnées
SELECT 
  id,
  type,
  montant,
  description,
  metadata
FROM cash_movements 
WHERE type = 'sortie'
ORDER BY dateCreation DESC 
LIMIT 1;
```

**Résultat attendu:**
```json
{
  "id": 123,
  "caisseId": 1,
  "type": "sortie",
  "montant": 39552,
  "description": "Paiement fournisseur SOCATOO SARL - Commande #CMD20260226001",
  "utilisateurId": 1,
  "dateCreation": "2026-02-27...",
  "metadata": "{\"typeTransaction\":\"paiement_fournisseur\",\"fournisseurId\":16,\"transactionCompteId\":100,\"referenceType\":\"approvisionnement\",\"referenceId\":39,\"sessionCaisseId\":1}"
}
```

## Logs attendus

Quand vous payez avec mouvement financier:

```
💰 Création transaction fournisseur: {
  fournisseurId: 16,
  montant: 39552,
  typeTransaction: 'paiement',
  referenceType: 'approvisionnement',
  referenceId: 39,
  createFinancialMovement: true
}
✅ Session de caisse active trouvée: {
  sessionId: 1,
  caisseId: 1,
  soldeOuverture: 100000
}
💸 Création du mouvement de caisse...
✅ Mouvement de caisse créé: {
  mouvementId: 123,
  type: 'sortie',
  montant: 39552
}
```

## Limitations actuelles

1. **Pas de vérification du solde**: Le système ne vérifie pas si le solde de la caisse est suffisant
2. **Pas de mise à jour du solde**: Le solde de la session n'est pas mis à jour automatiquement
3. **Calcul manuel du solde**: Pour connaître le solde actuel, il faut calculer: `soldeOuverture + SUM(entrees) - SUM(sorties)`

## Améliorations futures possibles

1. Ajouter un champ `soldeActuel` calculé dans `CashSession`
2. Créer une fonction pour calculer le solde actuel d'une session
3. Ajouter la vérification du solde avant de créer le mouvement
4. Créer un trigger ou une fonction pour mettre à jour automatiquement le solde

## Fichiers modifiés

- `backend/src/routes/accounts.js`:
  - Changement de `prisma.financialMovement` → `prisma.cashMovement`
  - Changement de `prisma.sessionCaisse` → `prisma.cashSession`
  - Changement de `statut: 'ouverte'` → `isActive: true`
  - Suppression de la vérification du solde
  - Suppression de la mise à jour du solde

## Commandes utiles

```bash
# Redémarrer le backend
restart-backend-debug.bat

# Voir les mouvements de caisse
SELECT * FROM cash_movements ORDER BY dateCreation DESC LIMIT 10;

# Voir les sessions actives
SELECT * FROM cash_sessions WHERE isActive = true;

# Calculer le solde actuel d'une session
SELECT 
  cs.id,
  cs.soldeOuverture,
  COALESCE(SUM(CASE WHEN cm.type = 'entree' THEN cm.montant ELSE 0 END), 0) as total_entrees,
  COALESCE(SUM(CASE WHEN cm.type = 'sortie' THEN cm.montant ELSE 0 END), 0) as total_sorties,
  cs.soldeOuverture + 
    COALESCE(SUM(CASE WHEN cm.type = 'entree' THEN cm.montant ELSE 0 END), 0) -
    COALESCE(SUM(CASE WHEN cm.type = 'sortie' THEN cm.montant ELSE 0 END), 0) as solde_actuel
FROM cash_sessions cs
LEFT JOIN cash_movements cm ON cm.caisseId = cs.caisseId 
  AND cm.dateCreation >= cs.dateOuverture
  AND (cs.dateFermeture IS NULL OR cm.dateCreation <= cs.dateFermeture)
WHERE cs.id = 1
GROUP BY cs.id;
```
