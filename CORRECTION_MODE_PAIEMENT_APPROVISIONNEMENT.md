# Correction du Mode de Paiement des Approvisionnements

## Problème identifié

Lors de la réception d'une commande d'approvisionnement avec le mode "Comptant", le système ne créait pas correctement les deux transactions nécessaires dans le compte fournisseur.

### Comportement incorrect observé:
- Paiement comptant: Seule la transaction d'achat (dette) apparaissait
- Résultat: Le système indiquait que le magasin devait de l'argent au fournisseur alors que le paiement était comptant

### Comportement attendu:
Paiement COMPTANT:
1. Transaction d'achat à crédit: -4000 FCFA (dette temporaire)
2. Transaction de paiement immédiat: +4000 FCFA (règlement)
3. Solde final: 0 FCFA

Paiement À CRÉDIT:
1. Transaction d'achat à crédit: -4000 FCFA
2. Solde final: -4000 FCFA (dette à payer plus tard)

## Cause du problème

Le backend utilisait toujours le modePaiement de la commande initiale, même si l'utilisateur changeait le mode de paiement lors de la réception.

## Solution implémentée

Fichier modifié: backend/src/routes/procurement.js

Changements:
1. Extraction du mode de paiement de la requête de réception
2. Utilisation du mode de paiement fourni lors de la réception (prioritaire)
3. Mise à jour du mode de paiement dans la commande si modifié
4. Création des deux transactions pour le paiement comptant

## Tests recommandés

1. Créer une commande d'approvisionnement
2. Réceptionner avec mode "Comptant"
3. Vérifier le compte fournisseur: 2 transactions doivent apparaître (achat + paiement)
4. Vérifier le solde final: doit être 0 FCFA
5. Réceptionner une autre commande avec mode "À crédit"
6. Vérifier le compte fournisseur: 1 transaction (achat seulement)
7. Vérifier le solde: doit être égal au montant de l'achat
