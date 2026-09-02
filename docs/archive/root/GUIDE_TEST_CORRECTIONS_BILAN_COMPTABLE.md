# Guide de Test - Corrections Bilan Comptable d'Activités

## 🎯 Objectif
Valider les corrections apportées au module bilan comptable d'activités pour résoudre :
1. **Calcul de marge incorrect** (maintenant basé sur prix d'achat réels)
2. **Filtrage des dettes incorrect** (maintenant strict par période)

## ✅ Corrections Appliquées

### 1. Calcul de la Marge (Méthode Accounting)
- **Avant** : Estimation `prixAchat = prixVente * 0.7`
- **Après** : Récupération du prix d'achat réel via API `/products/{id}`
- **Fallback intelligent** : API → Modèle → Estimation

### 2. Filtrage des Dettes (Strict par Période)
- **Avant** : Affichait toutes les dettes existantes
- **Après** : Affiche SEULEMENT les nouvelles dettes créées dans la période
- **Comportement attendu** : Si aucune vente à crédit dans la période → 0 FCFA de dette

## 🧪 Scénarios de Test

### Test 1: Période Actuelle (12/12/2025)
```
Période : 12/12/2025 - 12/12/2025
Résultat attendu :
- Si aucune vente aujourd'hui → Revenus: 0 FCFA, Dettes: 0 FCFA
- Si ventes cash uniquement → Revenus: > 0 FCFA, Dettes: 0 FCFA
- Si ventes à crédit → Revenus: > 0 FCFA, Dettes: > 0 FCFA
```

### Test 2: Période avec Activité Connue
```
Période : [Date avec ventes connues]
Vérifications :
- Marge calculée avec prix d'achat réels
- Dettes = montant des ventes à crédit de la période uniquement
- Cohérence avec le module accounting
```

### Test 3: Période Sans Activité
```
Période : [Date sans ventes]
Résultat attendu :
- Revenus: 0 FCFA
- Dettes: 0 FCFA
- Marge: 0%
- Aucune erreur affichée
```

## 📊 Points de Validation

### Calcul de la Marge
- [ ] Prix d'achat récupérés via API
- [ ] Fallback sur le modèle si API échoue
- [ ] Estimation uniquement en dernier recours
- [ ] Logs détaillés du processus

### Filtrage des Dettes
- [ ] Seules les nouvelles dettes de la période sont affichées
- [ ] Aucune dette si aucune vente à crédit dans la période
- [ ] Logs de debugging clairs
- [ ] Gestion d'erreur robuste

### Cohérence Générale
- [ ] Résultats cohérents avec le module accounting
- [ ] Performance acceptable (pas de lenteur)
- [ ] Interface utilisateur mise à jour correctement
- [ ] Aucune erreur de compilation

## 🔍 Logs à Surveiller

### Calcul de Marge
```
📊 Analyse du coût des marchandises (méthode accounting):
  - Articles traités: X
  - Articles avec coût réel API: Y
  - Articles avec estimation: Z
  - Coût total calculé: XXXX FCFA
```

### Filtrage des Dettes
```
📊 [DEBUG] RÉSULTAT FILTRAGE STRICT:
  - Nouvelles dettes créées dans la période: XXXX FCFA
  - Nouveaux clients débiteurs: X
  - Ventes à crédit génératrices: Y
```

## 🚀 Instructions de Test

1. **Démarrer l'application**
   ```bash
   cd logesco_v2
   flutter run
   ```

2. **Accéder au module Bilan Comptable**
   - Navigation : Rapports → Bilan Comptable d'Activités

3. **Tester avec la date actuelle (12/12/2025)**
   - Sélectionner la période : 12/12/2025 - 12/12/2025
   - Générer le rapport
   - Vérifier les résultats selon le scénario attendu

4. **Tester avec différentes périodes**
   - Période avec activité connue
   - Période sans activité
   - Période avec ventes mixtes (cash + crédit)

5. **Comparer avec le module Accounting**
   - Vérifier la cohérence des calculs de marge
   - S'assurer que les méthodes donnent des résultats similaires

## ⚠️ Points d'Attention

- **Performance** : Le calcul peut être plus lent car il récupère les prix d'achat via API
- **Réseau** : S'assurer que l'API est accessible pour récupérer les prix d'achat
- **Données** : Vérifier que les produits ont des prix d'achat configurés
- **Logs** : Surveiller les logs pour identifier d'éventuels problèmes

## 📋 Résultats Attendus

### Succès ✅
- Marge calculée avec précision (prix d'achat réels)
- Dettes filtrées strictement par période
- Aucune dette affichée si aucune vente à crédit dans la période
- Cohérence avec le module accounting

### Échec ❌
- Marge toujours estimée (prix d'achat non récupérés)
- Dettes anciennes encore affichées
- Erreurs de compilation ou d'exécution
- Incohérence avec le module accounting

## 🎯 Validation Finale

Le test est réussi si :
1. **Pour la date d'aujourd'hui (12/12/2025)** : Si aucune vente à crédit → 0 FCFA de dette
2. **Calcul de marge** : Utilise les prix d'achat réels quand disponibles
3. **Cohérence** : Résultats similaires au module accounting
4. **Performance** : Temps de réponse acceptable (< 10 secondes)

---

**Note** : Ces corrections alignent le module bilan comptable d'activités sur la méthode du module accounting pour garantir la cohérence et la précision des calculs financiers.