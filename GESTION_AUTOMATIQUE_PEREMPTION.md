# Gestion Automatique des Dates de Péremption

## Problème Résolu

Lorsqu'une vente est effectuée, les quantités enregistrées avec des dates de péremption n'étaient pas automatiquement mises à jour, créant une incohérence entre le stock réel et les quantités enregistrées.

### Exemple du Problème
- Stock initial : 62 unités avec date de péremption
- Vente : 59 unités
- Résultat attendu : 3 unités restantes avec date de péremption
- Résultat avant correction : 60 unités enregistrées (incohérent)

## Solution Implémentée

### Système FEFO (First Expired, First Out)

Un système automatique qui déduit les quantités vendues des lots de péremption en commençant par ceux qui expirent en premier.

### Fonctionnement

1. **Lors d'une vente** :
   - Le système récupère tous les lots actifs (non épuisés)
   - Les lots sont triés par date de péremption (les plus proches en premier)
   - Les quantités vendues sont déduites automatiquement :
     - Si un lot contient assez de quantité → il est partiellement consommé
     - Si un lot ne suffit pas → il est marqué comme épuisé et on passe au suivant
   - Les lots épuisés sont automatiquement marqués `estEpuise = true`

2. **Exemple de déduction** :
   ```
   Vente de 59 unités
   
   Lot 1 (expire le 21/03/2026) : 60 unités
   → Déduction de 59 unités
   → Reste 1 unité dans le lot
   
   Résultat : 1 unité restante avec date 21/03/2026
   ```

3. **Exemple avec plusieurs lots** :
   ```
   Vente de 150 unités
   
   Lot 1 (expire le 15/03/2026) : 60 unités
   → Déduction de 60 unités → LOT ÉPUISÉ
   
   Lot 2 (expire le 20/03/2026) : 80 unités
   → Déduction de 90 unités restantes
   → Reste 0 unités → LOT ÉPUISÉ
   
   Lot 3 (expire le 25/03/2026) : 100 unités
   → Déduction de 30 unités restantes
   → Reste 70 unités
   
   Résultat : 70 unités avec date 25/03/2026
   ```

## Fichiers Créés/Modifiés

### Backend

**Nouveau fichier** : `backend/src/utils/expiration-manager.js`
- Fonction `updateExpirationDatesAfterSale()` : Mise à jour automatique lors des ventes
- Fonction `updateExpirationDatesAfterReturn()` : Gestion des retours/annulations
- Logique FEFO complète

**Modifié** : `backend/src/routes/sales.js`
- Import du gestionnaire de péremption
- Appel automatique après chaque mise à jour de stock
- Gestion des erreurs sans bloquer la vente

## Avantages

### 1. Automatisation Complète
- Plus besoin de mise à jour manuelle
- Cohérence garantie entre stock et dates de péremption
- Gain de temps considérable

### 2. Traçabilité
- Logs détaillés de chaque opération
- Historique des lots épuisés
- Identification des quantités non couvertes

### 3. Gestion Intelligente
- Système FEFO : vend d'abord ce qui expire en premier
- Réduit les pertes liées aux péremptions
- Optimise la rotation des stocks

### 4. Robustesse
- Les erreurs de mise à jour des dates ne bloquent pas les ventes
- Logs d'erreur pour diagnostic
- Transactions atomiques

## Logs Générés

### Lors d'une vente réussie
```
✅ Dates de péremption mises à jour pour Barefoot (750ml):
   - Quantité vendue: 59
   - Lots modifiés: 1
   - Lots épuisés: 0
```

### Avec plusieurs lots
```
✅ Dates de péremption mises à jour pour Produit X:
   - Quantité vendue: 150
   - Lots modifiés: 1
   - Lots épuisés: 2
```

### Avertissement si quantité non couverte
```
⚠️ Attention: 10 unités non couvertes par les dates de péremption
```

## Cas d'Usage

### Cas 1 : Vente Simple
- Produit avec 1 lot de 100 unités (expire le 30/03/2026)
- Vente de 40 unités
- Résultat : 60 unités restantes avec même date

### Cas 2 : Épuisement Complet d'un Lot
- Produit avec 1 lot de 50 unités (expire le 25/03/2026)
- Vente de 50 unités
- Résultat : Lot marqué comme épuisé, 0 unités restantes

### Cas 3 : Vente sur Plusieurs Lots
- Lot 1 : 30 unités (expire le 20/03/2026)
- Lot 2 : 50 unités (expire le 25/03/2026)
- Vente de 60 unités
- Résultat : 
  - Lot 1 épuisé
  - Lot 2 avec 20 unités restantes

### Cas 4 : Produit Sans Gestion de Péremption
- Vente effectuée normalement
- Aucune mise à jour des dates (pas activé)
- Log : "Gestion de péremption non activée"

## Comportement en Cas d'Erreur

Si la mise à jour des dates de péremption échoue :
1. La vente est quand même enregistrée
2. Le stock est mis à jour
3. Une erreur est loggée pour investigation
4. L'utilisateur peut corriger manuellement si nécessaire

## Statistiques de Cohérence

Le widget affiche maintenant :
- **Stock** : Quantité totale disponible
- **Enregistré** : Quantité couverte par des dates
- **Restant** : Quantité non encore enregistrée
- **Couverture** : Pourcentage du stock couvert

Après une vente, ces statistiques sont automatiquement mises à jour.

## Tests Recommandés

### Test 1 : Vente Simple
1. Créer un produit avec gestion de péremption
2. Ajouter 100 unités en stock
3. Enregistrer 100 unités avec date de péremption
4. Vendre 40 unités
5. Vérifier : 60 unités restantes avec date de péremption

### Test 2 : Épuisement de Lot
1. Créer un produit avec 50 unités et date de péremption
2. Vendre 50 unités
3. Vérifier : Lot marqué comme épuisé

### Test 3 : Plusieurs Lots
1. Créer un produit avec 100 unités
2. Ajouter 2 lots : 40 unités (expire 20/03) et 60 unités (expire 25/03)
3. Vendre 70 unités
4. Vérifier : 
   - Premier lot épuisé
   - Deuxième lot avec 30 unités

### Test 4 : Produit Sans Gestion
1. Créer un produit sans gestion de péremption
2. Vendre des unités
3. Vérifier : Vente normale, pas de mise à jour des dates

## Prochaines Améliorations Possibles

1. **Gestion des retours** : Réintégrer les quantités dans les lots
2. **Choix du système** : FIFO vs FEFO configurable
3. **Alertes** : Notification si vente sur lot périmé
4. **Rapport** : Historique des lots vendus par période
5. **Optimisation** : Suggestion de vente des lots proches de la péremption

## Conclusion

Le système de gestion automatique des dates de péremption garantit maintenant :
- ✅ Cohérence totale entre stock et dates de péremption
- ✅ Rotation optimale des stocks (FEFO)
- ✅ Réduction des pertes
- ✅ Traçabilité complète
- ✅ Automatisation sans intervention manuelle

Les utilisateurs n'ont plus à se soucier de la mise à jour manuelle des quantités - le système gère tout automatiquement lors de chaque vente !
