# Guide de Test - Système Comptes Clients Amélioré

## 🎯 Objectif

Tester l'implémentation complète du système de comptes clients amélioré avec liaison vente-transaction.

---

## 📋 Prérequis

1. Backend démarré et fonctionnel
2. Application Flutter compilée et lancée
3. Au moins un client avec des ventes à crédit dans la base de données
4. Compte utilisateur avec permissions sur les comptes clients

---

## 🧪 Tests Backend (API)

### Test 1: Exécuter le script de test automatique

```bash
node test-comptes-clients-ameliores.js
```

**Résultats attendus:**
- ✅ Authentification réussie
- ✅ Récupération des ventes impayées
- ✅ Création de transaction liée à une vente
- ✅ Historique des transactions avec références de ventes
- ✅ Validation des ventes invalides
- ✅ Solde du compte mis à jour

---

## 📱 Tests Frontend (Flutter)

### Test 2: Affichage de l'historique des transactions

**Étapes:**
1. Ouvrir l'application Flutter
2. Naviguer vers "Comptes" > "Clients"
3. Sélectionner un client avec des transactions
4. Observer l'historique des transactions

**Vérifications:**
- [ ] Les transactions liées à des ventes affichent le numéro de vente
- [ ] Les icônes sont différentes selon le type:
  - 🧾 Bleu pour "Paiement Facture"
  - 💳 Vert pour "Paiement Dette"
  - 🛒 Orange pour "Vente à Crédit"
- [ ] Le libellé est formaté correctement:
  - "Paiement Facture #VTE-XXX"
  - "Paiement Dette (Vente #VTE-XXX)"
- [ ] Les anciennes transactions s'affichent toujours correctement

**Capture d'écran recommandée:** Historique avec différents types de transactions

---

### Test 3: Sélection d'une vente impayée

**Étapes:**
1. Ouvrir le compte d'un client avec des ventes impayées
2. Cliquer sur "Nouvelle transaction"
3. Sélectionner type "Paiement"
4. Cocher "Payer une vente spécifique"
5. Cliquer sur "Sélectionner une vente"

**Vérifications:**
- [ ] Le dialog s'ouvre correctement
- [ ] Les ventes impayées sont affichées
- [ ] Pour chaque vente, on voit:
  - [ ] Référence de la vente
  - [ ] Date de vente
  - [ ] Nombre d'articles
  - [ ] Montant total
  - [ ] Montant déjà payé
  - [ ] Montant restant (en rouge et gras)
- [ ] Les ventes sont sélectionnables (radio buttons)

**Capture d'écran recommandée:** Dialog de sélection de ventes

---

### Test 4: Paiement d'une vente spécifique (Complet)

**Étapes:**
1. Dans le dialog de sélection, choisir une vente
2. Observer le pré-remplissage du montant
3. Vérifier que le montant = montant restant
4. Vérifier que la description est pré-remplie
5. Cliquer sur "Payer"
6. Confirmer la transaction

**Vérifications:**
- [ ] Le montant est pré-rempli avec le reste à payer
- [ ] La description contient "Paiement Dette (Vente #XXX)"
- [ ] La transaction est créée avec succès
- [ ] Message de succès affiché
- [ ] L'historique est actualisé
- [ ] La nouvelle transaction apparaît avec:
  - [ ] Libellé: "Paiement Dette (Vente #XXX)"
  - [ ] Icône verte 💳
  - [ ] Montant correct
- [ ] Le solde du compte est mis à jour
- [ ] La vente n'apparaît plus dans les ventes impayées (si payée complètement)

**Capture d'écran recommandée:** Transaction créée dans l'historique

---

### Test 5: Paiement d'une vente spécifique (Partiel)

**Étapes:**
1. Sélectionner une vente impayée
2. Modifier le montant pour payer partiellement (ex: 3000 sur 10000)
3. Confirmer la transaction

**Vérifications:**
- [ ] La transaction est créée avec le montant partiel
- [ ] Le solde du compte diminue du montant payé
- [ ] La vente reste dans les ventes impayées
- [ ] Le montant restant de la vente est mis à jour
- [ ] En rouvrant le sélecteur, la vente affiche le nouveau reste

**Capture d'écran recommandée:** Vente avec paiement partiel

---

### Test 6: Validation du montant

**Étapes:**
1. Sélectionner une vente avec reste de 5000 FCFA
2. Essayer de payer 6000 FCFA (plus que le reste)
3. Cliquer sur "Payer"

**Vérifications:**
- [ ] Message d'erreur affiché
- [ ] Message indique "Le montant dépasse le reste à payer"
- [ ] La transaction n'est pas créée
- [ ] Le dialog reste ouvert

**Capture d'écran recommandée:** Message d'erreur

---

### Test 7: Validation de la sélection

**Étapes:**
1. Créer une nouvelle transaction
2. Cocher "Payer une vente spécifique"
3. Ne pas sélectionner de vente
4. Essayer de créer la transaction

**Vérifications:**
- [ ] Message d'erreur affiché
- [ ] Message indique "Veuillez sélectionner une vente à payer"
- [ ] La transaction n'est pas créée

---

### Test 8: Transaction normale (sans vente)

**Étapes:**
1. Créer une nouvelle transaction
2. Ne pas cocher "Payer une vente spécifique"
3. Saisir un montant et une description
4. Créer la transaction

**Vérifications:**
- [ ] La transaction est créée normalement
- [ ] Pas de référence de vente
- [ ] Libellé standard: "Paiement", "Crédit", etc.
- [ ] Icône par défaut selon le type

---

### Test 9: Client sans ventes impayées

**Étapes:**
1. Ouvrir le compte d'un client sans ventes impayées
2. Créer une nouvelle transaction
3. Cocher "Payer une vente spécifique"
4. Cliquer sur "Sélectionner une vente"

**Vérifications:**
- [ ] Le dialog s'ouvre
- [ ] Message affiché: "Aucune vente impayée pour ce client"
- [ ] Pas de ventes dans la liste
- [ ] Bouton "Payer" désactivé

---

### Test 10: Compatibilité avec anciennes transactions

**Étapes:**
1. Ouvrir un compte avec des transactions créées avant la mise à jour
2. Observer l'historique

**Vérifications:**
- [ ] Les anciennes transactions s'affichent correctement
- [ ] Pas d'erreur de parsing
- [ ] Libellés standards pour les anciennes transactions
- [ ] Icônes par défaut selon le type

---

## 🔍 Tests de Régression

### Test 11: Création de vente à crédit

**Étapes:**
1. Créer une nouvelle vente
2. Sélectionner un client
3. Ajouter des produits
4. Finaliser avec paiement partiel (ex: 5000 sur 15000)

**Vérifications:**
- [ ] La vente est créée
- [ ] Le compte client est débité
- [ ] Une transaction est créée automatiquement
- [ ] La transaction a le type "paiement_vente" (si implémenté côté vente)
- [ ] La vente apparaît dans les ventes impayées du client

---

### Test 12: Limite de crédit

**Étapes:**
1. Ouvrir un compte client
2. Vérifier la limite de crédit
3. Créer des transactions pour dépasser la limite

**Vérifications:**
- [ ] Le système affiche un avertissement si dépassement
- [ ] Le crédit disponible est calculé correctement
- [ ] L'indicateur "En dépassement" est correct

---

## 📊 Résultats Attendus

### Checklist Globale

- [ ] Toutes les nouvelles fonctionnalités fonctionnent
- [ ] Aucune régression sur les fonctionnalités existantes
- [ ] Les validations sont correctes
- [ ] Les messages d'erreur sont clairs
- [ ] L'interface est intuitive
- [ ] Les performances sont acceptables
- [ ] Pas de crash ou d'erreur console

---

## 🐛 Problèmes Connus / À Surveiller

### Problèmes Potentiels

1. **Performance avec beaucoup de ventes impayées**
   - Surveiller le temps de chargement du dialog
   - Vérifier la pagination si nécessaire

2. **Synchronisation des données**
   - Vérifier que l'historique se rafraîchit après création
   - Vérifier que les ventes impayées se mettent à jour

3. **Validation des montants**
   - Tester avec des montants décimaux
   - Tester avec des montants très grands
   - Tester avec des montants négatifs (doit être rejeté)

4. **Gestion des erreurs réseau**
   - Tester avec connexion lente
   - Tester avec perte de connexion
   - Vérifier les messages d'erreur

---

## 📝 Rapport de Test

### Template de Rapport

```
Date: __________
Testeur: __________
Version: __________

Tests Backend:
- Test 1: [ ] Réussi [ ] Échoué - Notes: __________

Tests Frontend:
- Test 2: [ ] Réussi [ ] Échoué - Notes: __________
- Test 3: [ ] Réussi [ ] Échoué - Notes: __________
- Test 4: [ ] Réussi [ ] Échoué - Notes: __________
- Test 5: [ ] Réussi [ ] Échoué - Notes: __________
- Test 6: [ ] Réussi [ ] Échoué - Notes: __________
- Test 7: [ ] Réussi [ ] Échoué - Notes: __________
- Test 8: [ ] Réussi [ ] Échoué - Notes: __________
- Test 9: [ ] Réussi [ ] Échoué - Notes: __________
- Test 10: [ ] Réussi [ ] Échoué - Notes: __________

Tests de Régression:
- Test 11: [ ] Réussi [ ] Échoué - Notes: __________
- Test 12: [ ] Réussi [ ] Échoué - Notes: __________

Problèmes Identifiés:
1. __________
2. __________

Recommandations:
1. __________
2. __________

Conclusion: [ ] Prêt pour production [ ] Corrections nécessaires
```

---

## 🚀 Déploiement

### Avant le Déploiement

1. [ ] Tous les tests passent
2. [ ] Aucun problème bloquant
3. [ ] Documentation à jour
4. [ ] Formation des utilisateurs prévue

### Après le Déploiement

1. [ ] Monitorer les logs pour détecter les erreurs
2. [ ] Recueillir les retours utilisateurs
3. [ ] Ajuster si nécessaire

---

## 📞 Support

En cas de problème, vérifier:
1. Les logs backend (console Node.js)
2. Les logs Flutter (console de debug)
3. Les requêtes réseau (Network tab)
4. La structure de la base de données

**Fichiers de référence:**
- `CORRECTIONS_COMPTES_CLIENTS_COMPLETE.md` - Documentation complète
- `AMELIORATION_COMPTES_CLIENTS.md` - Analyse initiale
- `IMPLEMENTATION_COMPTES_CLIENTS_ETAPES.md` - Plan d'implémentation
