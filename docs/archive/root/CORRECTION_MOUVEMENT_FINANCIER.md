# Correction - Mouvement financier non créé

## Problème identifié

Le mouvement financier n'était pas créé lors du paiement fournisseur même quand la checkbox était cochée.

## Cause

Le modèle Prisma s'appelle `FinancialMovement` (en anglais) mais le code utilisait `mouvementFinancier` (en français).

## Correction appliquée

### Fichier: `backend/src/routes/accounts.js`

**Avant:**
```javascript
mouvementFinancier = await prisma.mouvementFinancier.create({
  // ...
});
```

**Après:**
```javascript
mouvementFinancier = await prisma.financialMovement.create({
  // ...
});
```

## Vérification du schéma Prisma

Le modèle correct dans `backend/prisma/schema.prisma` est:

```prisma
model FinancialMovement {
  id               Int                      @id @default(autoincrement())
  reference        String                   @unique
  type             String                   // 'entree' ou 'sortie'
  categorie        String                   // 'paiement_fournisseur', etc.
  montant          Decimal                  @db.Decimal(15, 2)
  description      String?
  caisseId         Int
  utilisateurId    Int
  sessionCaisseId  Int?
  referenceType    String?
  referenceId      Int?
  dateCreation     DateTime                 @default(now())
  
  // Relations
  caisse           Caisse                   @relation(...)
  utilisateur      Utilisateur              @relation(...)
  sessionCaisse    SessionCaisse?           @relation(...)
}
```

## Actions requises

1. ✅ Correction du code dans `accounts.js`
2. ✅ Correction du script de vérification `check-financial-movements.js`
3. ⚠️  **REDÉMARRER LE BACKEND** (obligatoire)
4. Tester à nouveau le paiement avec mouvement financier

## Test après correction

### Étapes:
1. Redémarrer le backend
2. Ouvrir une session de caisse avec un solde suffisant
3. Aller dans le compte d'un fournisseur
4. Sélectionner une commande à payer
5. Cocher "Créer un mouvement financier"
6. Confirmer le paiement

### Vérifications:
```bash
# Vérifier les mouvements financiers créés
cd backend
node check-financial-movements.js
```

Le script devrait afficher:
- Le mouvement financier créé
- Le type: "sortie"
- La catégorie: "paiement_fournisseur"
- Le montant déduit
- La session de caisse avec le nouveau solde

### Vérification dans la base de données:

```sql
-- Voir les derniers mouvements financiers
SELECT * FROM FinancialMovement 
WHERE categorie = 'paiement_fournisseur'
ORDER BY dateCreation DESC 
LIMIT 5;

-- Voir le solde de la session de caisse
SELECT id, soldeActuel, dateOuverture 
FROM SessionCaisse 
WHERE statut = 'ouverte'
ORDER BY dateOuverture DESC;
```

## Logs attendus dans le backend

Quand vous payez avec mouvement financier, vous devriez voir:

```
💰 Création transaction fournisseur: {
  fournisseurId: 16,
  montant: 50000,
  typeTransaction: 'paiement',
  referenceType: 'approvisionnement',
  referenceId: 39,
  createFinancialMovement: true
}
✅ Session de caisse active trouvée: {
  sessionId: 1,
  caisseId: 1,
  soldeActuel: 100000
}
💸 Création du mouvement financier...
✅ Mouvement financier créé: {
  mouvementId: 5,
  nouveauSoldeCaisse: 50000
}
```

## En cas de problème

### Erreur: "Aucune session de caisse active"
- Ouvrir une session de caisse avant de payer
- Vérifier que la session est bien ouverte (statut = 'ouverte')

### Erreur: "Solde de caisse insuffisant"
- Vérifier le solde de la session de caisse
- Ajouter du solde à la caisse si nécessaire

### Le mouvement n'apparaît pas
- Vérifier que le backend a bien été redémarré
- Vérifier les logs du backend
- Exécuter `node check-financial-movements.js` pour voir les mouvements

## Commandes utiles

```bash
# Redémarrer le backend
restart-backend-debug.bat

# Vérifier les mouvements financiers
cd backend
node check-financial-movements.js

# Vérifier les paiements d'un fournisseur
node check-supplier-payments.js 16
```
