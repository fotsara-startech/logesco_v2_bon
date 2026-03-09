# Correction: Mouvement Financier lors du Paiement Fournisseur

## Problème Identifié

Lorsqu'un utilisateur effectue un paiement à un fournisseur avec l'option "Créer un mouvement financier" cochée:
- ✅ Le backend crée bien le mouvement financier (visible dans les logs)
- ❌ Le mouvement n'apparaît pas dans l'interface des mouvements financiers

## Cause du Problème

Dans le fichier `backend/src/routes/accounts.js`, ligne 747, lors de la création du mouvement financier:

```javascript
// ❌ CODE INCORRECT
mouvementFinancier = await prisma.financialMovement.create({
  data: {
    type: 'sortie',
    categorie: 'paiement_fournisseur',  // ❌ String au lieu d'un ID
    montant: parseFloat(montant),
    // ...
  }
});
```

Le problème: 
- Le champ `categorie` était renseigné avec une **chaîne de caractères** `'paiement_fournisseur'`
- Le schéma Prisma attend `categorieId` qui est un **entier (Int)**
- Cela causait une erreur silencieuse lors de la création du mouvement

## Solution Appliquée

### 1. Récupération ou Création de la Catégorie

Avant de créer le mouvement financier, on récupère ou crée la catégorie:

```javascript
// Récupérer ou créer la catégorie "paiement_fournisseur"
let categorie = await prisma.movementCategory.findFirst({
  where: { nom: 'paiement_fournisseur' }
});

if (!categorie) {
  console.log('📦 Création de la catégorie paiement_fournisseur...');
  categorie = await prisma.movementCategory.create({
    data: {
      nom: 'paiement_fournisseur',
      displayName: 'Paiement Fournisseur',
      color: '#EF4444',
      icon: 'payment',
      isDefault: true,
      isActive: true
    }
  });
}
```

### 2. Utilisation de l'ID de la Catégorie

```javascript
// ✅ CODE CORRECT
mouvementFinancier = await prisma.financialMovement.create({
  data: {
    montant: parseFloat(montant),
    categorieId: categorie.id,  // ✅ ID numérique
    description: description || `Paiement fournisseur ${fournisseur.nom}${referenceId ? ` - Commande #${referenceId}` : ''}`,
    utilisateurId: req.user.id,
    notes: `Session caisse: ${sessionCaisse.id}, Caisse: ${sessionCaisse.caisseId}${referenceId ? `, Commande: ${referenceId}` : ''}`
  }
});
```

## Fichiers Modifiés

- `backend/src/routes/accounts.js` (lignes 740-775)

## Test de la Correction

Un script de test a été créé: `test-supplier-payment-fix.js`

### Exécution du Test

```bash
node test-supplier-payment-fix.js
```

### Ce que le Test Vérifie

1. ✅ Connexion en tant qu'admin
2. ✅ Récupération d'un fournisseur
3. ✅ Récupération d'une commande impayée
4. ✅ Paiement avec création de mouvement financier
5. ✅ Vérification que le mouvement existe dans l'API
6. ✅ Vérification que le mouvement apparaît dans la liste

## Résultat Attendu

Après la correction:
- ✅ Le mouvement financier est créé correctement
- ✅ Il apparaît dans l'interface des mouvements financiers
- ✅ Il est lié à la bonne catégorie "Paiement Fournisseur"
- ✅ Il contient toutes les informations nécessaires (montant, description, notes)

## Redémarrage Requis

⚠️ **Important**: Le backend doit être redémarré pour que la correction prenne effet.

```bash
# Arrêter le backend actuel
# Puis redémarrer avec:
START_BACKEND.bat
```

## Vérification Manuelle

1. Ouvrir l'application Flutter
2. Aller dans "Fournisseurs"
3. Sélectionner un fournisseur avec une commande impayée
4. Cliquer sur "Payer le fournisseur"
5. Cocher "Créer un mouvement financier"
6. Effectuer le paiement
7. Aller dans "Mouvements Financiers"
8. ✅ Le paiement doit apparaître dans la liste

## Notes Techniques

### Schéma Prisma

```prisma
model FinancialMovement {
  id               Int                      @id @default(autoincrement())
  reference        String                   @unique
  montant          Float
  categorieId      Int                      @map("categorie_id")  // ← Doit être un Int
  description      String
  date             DateTime                 @default(now())
  utilisateurId    Int                      @map("utilisateur_id")
  notes            String?
  
  // Relations
  categorie        MovementCategory         @relation(fields: [categorieId], references: [id])
  utilisateur      Utilisateur             @relation(fields: [utilisateurId], references: [id])
  
  @@map("financial_movements")
}

model MovementCategory {
  id               Int                 @id @default(autoincrement())
  nom              String              @unique
  displayName      String              @map("display_name")
  color            String              @default("#6B7280")
  icon             String              @default("receipt")
  isDefault        Boolean             @default(false) @map("is_default")
  isActive         Boolean             @default(true) @map("is_active")
  
  // Relations
  mouvements       FinancialMovement[]
  
  @@map("movement_categories")
}
```

## Impact

Cette correction affecte uniquement:
- Les paiements fournisseurs avec création de mouvement financier
- Aucun impact sur les autres fonctionnalités
- Aucune migration de base de données nécessaire

## Date de Correction

26 février 2026
