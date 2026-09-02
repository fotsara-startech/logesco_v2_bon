# Ajustement: Annulation de Ventes avec Déduction de Session de Caisse

## Résumé des Modifications

Lorsqu'une vente est annulée, le système effectue maintenant les opérations suivantes:

### 1. ✅ Déduction du Montant de la Session de Caisse
- Le montant payé de la vente annulée est déduit de la session de caisse appropriée
- Un mouvement de caisse négatif est créé pour tracer l'annulation
- Le solde attendu de la session est mis à jour

### 2. ✅ Exclusion de la Comptabilité
- Les mouvements financiers liés à la vente annulée sont supprimés
- La vente n'apparaît plus dans les rapports comptables
- Les transactions de compte client liées à la vente sont annulées

### 3. ✅ Gestion du Compte Client
- Le solde du compte client est ajusté (montant de la vente est recrédité)
- Une transaction d'annulation est créée pour traçabilité
- Les anciennes transactions de paiement pour cette vente sont supprimées

### 4. ✅ Restauration du Stock
- Le stock des produits physiques est restauré
- Les services ne sont pas affectés (pas de gestion de stock)
- Un mouvement de stock de type "retour" est créé

## Fichiers Modifiés

### backend/src/routes/sales.js
- Route DELETE `/sales/:id` (annulation de vente)
- Ajout de la logique de déduction de session de caisse
- Ajout de la suppression des mouvements financiers
- Amélioration de la gestion du compte client

## Détails Techniques

### Mouvement de Caisse d'Annulation
```javascript
{
  type: 'annulation_vente',
  montant: -vente.montantPaye,  // Montant négatif
  description: `Annulation vente ${vente.numeroVente}`,
  metadata: {
    categorie: 'annulation_vente',
    referenceType: 'vente_annulee',
    referenceId: venteId,
    venteReference: numeroVente,
    montantOriginal: montantPaye
  }
}
```

### Suppression des Mouvements Financiers
- Recherche des mouvements financiers liés à la vente
- Suppression des pièces jointes associées
- Suppression du mouvement financier lui-même

### Ajustement du Compte Client
- Solde = Solde + Montant de la vente (recréditer)
- Création d'une transaction d'annulation pour traçabilité
- Suppression des transactions de paiement liées à cette vente

## Filtrage Existant des Ventes Annulées

Les requêtes suivantes excluent déjà les ventes annulées:

1. **Dashboard** (`backend/src/routes/dashboard.js`)
   - Comptage des ventes: `statut: { not: 'annulee' }`
   - Somme des ventes: `statut: { not: 'annulee' }`

2. **Analytics** (`backend/src/routes/sales.js`)
   - Chiffre d'affaires par produit: `statut: { not: 'annulee' }`

3. **Comptes Clients** (`backend/src/routes/accounts.js`)
   - Ventes impayées: `statut: { not: 'annulee' }`

4. **Recherche de Ventes** (`backend/src/routes/sales.js`)
   - Filtre par défaut: `statut: { not: 'annulee' }`

## Logs de Débogage

Lors de l'annulation d'une vente, les logs suivants sont affichés:

```
🔄 Annulation de la vente VENTE-001
   - Montant: 50000 FCFA
   - Montant payé: 50000 FCFA
   - Session ID: 5

💰 Déduction de 50000 FCFA de la session 5
✅ Solde attendu mis à jour: 150000 FCFA

🗑️ Suppression de 1 mouvement(s) financier(s)

👤 Ajustement du compte client 3
   Ancien solde: -10000 FCFA
   Nouveau solde: 40000 FCFA

✅ Vente annulée avec succès - montant déduit de la session de caisse et exclu de la comptabilité
```

## Tests Recommandés

1. **Annuler une vente avec paiement comptant**
   - Vérifier que le montant est déduit de la session
   - Vérifier que le solde attendu est mis à jour
   - Vérifier que la vente n'apparaît plus dans les rapports

2. **Annuler une vente à crédit**
   - Vérifier que le compte client est ajusté
   - Vérifier que les transactions sont annulées
   - Vérifier que le solde du client est correct

3. **Annuler une vente avec produits physiques**
   - Vérifier que le stock est restauré
   - Vérifier que le mouvement de stock est créé

4. **Vérifier les rapports comptables**
   - Les ventes annulées ne doivent pas apparaître
   - Le chiffre d'affaires doit être correct
   - Les mouvements financiers doivent être cohérents

## Compatibilité

- ✅ Compatible avec les sessions de caisse existantes
- ✅ Compatible avec les comptes clients
- ✅ Compatible avec les mouvements financiers
- ✅ Compatible avec la gestion du stock
- ✅ Compatible avec les rapports et analytics
