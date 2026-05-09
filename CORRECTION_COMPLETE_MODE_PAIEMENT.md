# Correction Complète du Mode de Paiement Comptant

## Problème

Lors de la réception d'une commande avec mode "Comptant", seule la transaction d'achat apparaissait dans le compte fournisseur, créant une dette incorrecte.

## Cause racine

Le schéma de validation Joi bloquait le paramètre `modePaiement` lors de la réception, empêchant le backend de recevoir cette information.

## Fichiers modifiés

### 1. backend/src/validation/schemas.js

**Ligne 257-264**: Ajout du champ `modePaiement` au schéma de réception

```javascript
reception: Joi.object({
  details: Joi.array().items(
    Joi.object({
      detailId: baseSchemas.id.required(),
      quantiteRecue: Joi.number().integer().min(0).required()
    })
  ).min(1).required(),
  modePaiement: baseSchemas.modePaiement.optional() // AJOUTÉ
}),
```

### 2. backend/src/routes/procurement.js

**Ligne 545-850**: Modification de la logique de réception

Changements clés:
- Extraction du `modePaiement` du body de la requête
- Utilisation du mode fourni lors de la réception (prioritaire)
- Mise à jour du mode dans la commande si modifié
- Création des 2 transactions pour le paiement comptant

## Test de validation

Utilisez le script `test-procurement-comptant.js` pour valider:

```bash
# Démarrer le backend
cd backend
npm start

# Dans un autre terminal
node test-procurement-comptant.js
```

## Résultat attendu

### Paiement COMPTANT:
```
Transactions:
1. Achat - Réception commande CMD... (comptant)    -4000 FCFA  → Solde: 4000 FCFA
2. Paiement - Paiement comptant commande CMD...    +4000 FCFA  → Solde: 0 FCFA

Solde final: 0 FCFA ✅
```

### Paiement À CRÉDIT:
```
Transactions:
1. Achat - Réception commande CMD... à crédit      -4000 FCFA  → Solde: 4000 FCFA

Solde final: 4000 FCFA (dette) ✅
```

## Redémarrage requis

Après modification, redémarrez le backend:
```bash
# Arrêter le backend (Ctrl+C)
# Redémarrer
npm start
```

## Vérification manuelle

1. Créer un nouveau fournisseur
2. Créer une commande d'approvisionnement
3. Réceptionner avec mode "Comptant"
4. Vérifier le compte fournisseur:
   - Doit avoir 2 transactions
   - Solde final = 0 FCFA
