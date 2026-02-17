# Guide de Test - Refonte Flux de Vente

## Préparation

### 1. S'assurer que l'app est compilée
```bash
cd logesco_v2
flutter pub get
flutter run -d windows
```

### 2. Accéder à l'authentification
- Login avec vos credentials
- Naviguer vers le module **Ventes** → **Nouvelle vente**

## Scénarios de Test

### ✅ Test 1: Configuration des Paramètres (Initial)
**Objectif**: Vérifier que les préférences d'imprimante sont accessibles et persistent

**Étapes**:
1. Sur la page "Nouvelle vente", cliquer sur le bouton ⚙️ (settings) en haut à droite
2. Voir la page "Paramètres des ventes"
3. Vérifier les 3 options d'imprimante:
   - Thermique 80mm (par défaut, sélectionné)
   - A5 (148 x 210 mm)
   - A4 (210 x 297 mm)
4. Sélectionner **A4** → Voir notification "Paramètre sauvegardé"
5. Naviguer ailleurs puis revenir
6. **Vérifier**: A4 est toujours sélectionné ✅

**Résultat attendu**: Format persiste entre sessions

---

### ✅ Test 2: Vente Simple (Comptant, Sans Client)
**Objectif**: Minimal viable vente path

**Étapes**:
1. Revenir à "Nouvelle vente"
2. **Sélectionner produits**: 
   - Ajouter 2-3 produits au panier
   - Vérifier que le panier affiche correctement
3. **Pas de client**: Laisser client vide
4. **Montant payé**: 
   - Voir le montant par défaut = total
   - Vérifier qu'il n'y a pas de "Reste" ou "Monnaie"
5. **Confirmer**: Cliquer "Confirmer la vente"
6. **Impression**: 
   - Attendre génération reçu
   - Voir notification "Reçu XXXX imprimé"
   - **Pas d'aperçu** (important!) ✅
7. **Panier**: Vérifier que le panier est réinitialisé (vide)

**Résultat attendu**: Workflow fluide, pas de modal, pas d'aperçu, panier réinitialisé

---

### ✅ Test 3: Vente Crédit (Paiement Partiel)
**Objectif**: Vérifier gestion client et calcul monnaie/reste

**Étapes**:
1. Ajouter produits (exemple: Total = 50,000 FCFA)
2. **Sélectionner client**:
   - Dérouler le dropdown "Client (optionnel)"
   - Sélectionner un client existant
3. **Montant payé**:
   - Entrer 30,000 FCFA (moins que le total)
   - **Vérifier**: Voir "Reste: 20,000 FCFA" en orange
4. **Confirmer vente**:
   - Cliquer "Confirmer la vente"
   - Vérifier que vente se crée (status = crédit)
5. **Impression**:
   - Reçu généré et imprimé directement
   - Pas d'aperçu ni dialog ✅

**Résultat attendu**: Crédit accepté avec client, calcul correct, impression directe

---

### ✅ Test 4: Paiement Partiel Sans Client (Doit Échouer)
**Objectif**: Vérifier validation - pas de crédit sans client

**Étapes**:
1. Ajouter produits (Total = 50,000 FCFA)
2. **Pas de client**: Laisser vide
3. **Montant payé**: Entrer 30,000 FCFA
4. **Confirmer vente**:
   - Cliquer "Confirmer la vente"
   - **Attendre**: Voir notification d'erreur "Client requis" ✅
5. Vente ne se crée **pas**

**Résultat attendu**: Validation empêche crédit sans client

---

### ✅ Test 5: Paiement Excédentaire (Monnaie)
**Objectif**: Vérifier calcul et affichage de la monnaie

**Étapes**:
1. Ajouter produits (Total = 35,000 FCFA)
2. **Montant payé**: Entrer 50,000 FCFA
3. **Vérifier**: 
   - Voir "Monnaie: 15,000 FCFA" en vert ✅
   - Sans client (comptant)
4. **Confirmer** → Impression directe

**Résultat attendu**: Monnaie bien calculée et affichée

---

### ✅ Test 6: Format d'Impression Persiste
**Objectif**: Vérifier que format préférence est appliqué

**Étapes**:
1. Aller à **Paramètres des ventes**
2. Sélectionner **Thermique 80mm**
3. Revenir à **Nouvelle vente**
4. Créer une vente et imprimer
5. **Vérifier** dans les logs/impression:
   - Format utilisé = Thermique ✅
6. Changer le format à **A5** en paramètres
7. Créer autre vente
8. **Vérifier**: A5 est appliqué

**Résultat attendu**: Format suit les préférences globales

---

### ✅ Test 7: Édition Quantités/Prix en Panier
**Objectif**: Vérifier que modifications panier sont réactives

**Étapes**:
1. Ajouter produit avec quantité = 2
2. **Modifier quantité** dans le panier:
   - Changer à 5
   - Vérifier que total se met à jour ✅
3. **Modifier prix**:
   - Ajuster prix unitaire
   - Vérifier que total change immédiatement ✅
4. **Supprimer produit**:
   - Voir qu'il disparaît
   - Total se recalcule ✅

**Résultat attendu**: Panier reactif et validé

---

## Checklist de Validation Finale

- [ ] Page paramètres accessible (bouton ⚙️)
- [ ] 3 formats d'imprimante visibles
- [ ] Format sélectionné persiste
- [ ] Vente simple (comptant) fonctionne
- [ ] Pas d'aperçu après impression
- [ ] Panier réinitialisé après vente
- [ ] Crédit requiert un client
- [ ] Monnaie calculée correctement
- [ ] Reste calculé correctement
- [ ] Client selection dropdown fonctionne
- [ ] Montant payé accepte les nombres
- [ ] Workflow < 7 interactions

## Logs de Debugging

Pendant le test, ouvrir la console pour voir les logs:
```
🔄 CRÉATION DE LA VENTE...
✅ VENTE CRÉÉE AVEC SUCCÈS
🖨️ IMPRESSION DIRECTE - Format: Thermique (80 mm)
✅ Reçu généré - ID: ...
```

**Absence de**:
- ❌ `Get.to(ReceiptPreviewPage)` - on n'y va plus!
- ❌ Dialog modals - tout sur une page
- ❌ Demande de format par transaction

## Rapport de Test

Après les tests, créer un fichier `TEST_RESULTS.txt` avec:
```
Date: [date]
Version: [version]
OS: [Windows/Mac/Linux]
Résultats: [PASS/FAIL]
Problèmes identifiés:
- [problème 1]
- [problème 2]
Observations:
- [observation]
```

## Support

Pour tout problème pendant les tests:
1. Vérifier les imports dans `create_sale_page.dart`
2. Vérifier que `sales_preferences_page.dart` est bien créée
3. Vérifier routes dans `app_routes.dart` et `app_pages.dart`
4. Rebuild l'app: `flutter clean && flutter pub get && flutter run`
