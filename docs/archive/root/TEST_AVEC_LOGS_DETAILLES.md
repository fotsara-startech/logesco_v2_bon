# Test avec Logs Détaillés - Paiement Dette Client

## Préparation

### 1. Redémarrer le backend

```bash
restart-backend-quick.bat
```

### 2. Redémarrer l'application Flutter

- Hot restart (Shift+R dans le terminal Flutter)
- Ou redémarrer complètement l'app

## Test

### Étape 1: Préparer les données

1. **Noter le solde actuel de la caisse**
   - Aller dans "Caisses"
   - Noter le solde de la caisse active
   - Exemple: 50000 FCFA

2. **Vérifier qu'une caisse est ouverte**
   - Si aucune caisse n'est ouverte, en ouvrir une
   - Vérifier que le statut est "Ouverte"

3. **Sélectionner un client avec dette**
   - Aller dans "Clients"
   - Sélectionner un client avec dette
   - Noter le montant de la dette
   - Exemple: 10000 FCFA

### Étape 2: Effectuer le paiement

1. **Ouvrir le compte du client**
   - Cliquer sur "Voir le compte"

2. **Cliquer sur "Payer la dette"**

3. **Sélectionner une vente**
   - Cliquer sur "Sélectionner une vente"
   - Choisir une vente impayée

4. **Entrer le montant**
   - Exemple: 500 FCFA

5. **Confirmer le paiement**
   - Cliquer sur "Confirmer le paiement"

### Étape 3: Observer les logs

#### A. Logs Backend (Terminal du serveur)

Chercher ces logs dans l'ordre:

```
🔍 [Payment] Recherche de la caisse active...
```
→ Le backend cherche la caisse active

```
✅ [Payment] Caisse active trouvée: [Nom] (ID: [ID])
```
→ La caisse a été trouvée

```
💰 [Payment] Mise à jour de la caisse active: [Nom]
  - Solde actuel caisse: [Montant] FCFA
  - Montant à ajouter: [Montant] FCFA
  - Nouveau solde caisse: [Montant] FCFA
```
→ Le backend calcule le nouveau solde

```
✅ [Payment] Caisse mise à jour avec succès
  - Nouveau solde confirmé: [Montant] FCFA
```
→ La mise à jour en base de données a réussi

```
✅ [Payment] Mouvement de caisse créé (ID: [ID])
```
→ Un mouvement de caisse a été créé pour traçabilité

#### B. Logs Frontend (Console Flutter)

Chercher ces logs dans l'ordre:

```
🔄 [CashRegisterRefreshService] ========== DEBUT RAFRAICHISSEMENT ==========
```
→ Le service de rafraîchissement démarre

```
✅ [CashRegisterRefreshService] Contrôleur trouvé, rafraîchissement...
```
ou
```
⚠️ [CashRegisterRefreshService] Contrôleur non trouvé, création temporaire...
```
→ Le contrôleur est trouvé ou créé

```
📊 [CashRegisterRefreshService] Nombre de caisses avant: [N]
📊 [CashRegisterRefreshService] Nombre de caisses après: [N]
```
→ Nombre de caisses avant et après rafraîchissement

```
💰 [CashRegisterRefreshService] Caisse: [Nom] - Solde: [Montant] FCFA - Active: [true/false]
```
→ Détails de chaque caisse avec son nouveau solde

```
🔄 [CashRegisterRefreshService] ========== FIN RAFRAICHISSEMENT ==========
```
→ Le rafraîchissement est terminé

#### C. Logs Actualisation Auto (après 10 secondes)

```
🔄 [CashRegisterController] ========== DEBUT ACTUALISATION AUTO ==========
```
→ Le timer automatique démarre

```
💰 [CashRegisterController] Mise à jour caisse: [Nom]
   Ancien solde: [Montant] FCFA → Nouveau solde: [Montant] FCFA
```
→ Le solde a changé et est mis à jour

```
📊 [CashRegisterController] Résumé actualisation:
   - Caisses mises à jour: 1
   - Caisses ajoutées: 0
   - Caisses supprimées: 0
   - Total caisses: 3
```
→ Résumé de l'actualisation

### Étape 4: Vérifier le résultat

1. **Aller dans "Caisses"**
2. **Vérifier le solde de la caisse active**
3. **Le solde devrait avoir augmenté du montant payé**

**Exemple:**
- Solde avant: 50000 FCFA
- Paiement: 500 FCFA
- Solde après: 50500 FCFA ✓

## Diagnostic des problèmes

### Problème 1: Backend ne trouve pas la caisse

**Logs:**
```
⚠️ [Payment] Aucune caisse active trouvée
```

**Solution:**
1. Vérifier qu'une caisse est ouverte
2. Aller dans "Caisses" → Ouvrir une caisse
3. Réessayer le paiement

### Problème 2: Frontend ne rafraîchit pas

**Logs:**
```
❌ [CashRegisterRefreshService] Erreur lors du rafraîchissement: [Message]
```

**Solution:**
1. Vérifier la connexion au backend
2. Vérifier que le backend est démarré
3. Redémarrer l'application Flutter

### Problème 3: Solde pas mis à jour dans l'interface

**Logs:**
```
📊 [CashRegisterController] Résumé actualisation:
   - Caisses mises à jour: 0
```

**Cause:** Le solde n'a pas changé dans la base de données

**Solution:**
1. Vérifier les logs backend
2. Vérifier que la mise à jour a réussi côté backend
3. Si le backend a réussi mais pas le frontend, attendre 10 secondes (timer auto)

### Problème 4: Contrôleur non trouvé

**Logs:**
```
⚠️ [CashRegisterRefreshService] Contrôleur non trouvé, création temporaire...
```

**Ce n'est PAS un problème:**
- Le service crée automatiquement un contrôleur temporaire
- Le rafraîchissement devrait quand même fonctionner
- Vérifier que les logs suivants montrent le succès

## Checklist de vérification

Après le paiement, vérifier que TOUS ces logs apparaissent:

### Backend
- [ ] `🔍 [Payment] Recherche de la caisse active...`
- [ ] `✅ [Payment] Caisse active trouvée`
- [ ] `💰 [Payment] Mise à jour de la caisse active`
- [ ] `✅ [Payment] Caisse mise à jour avec succès`
- [ ] `✅ [Payment] Mouvement de caisse créé`

### Frontend
- [ ] `🔄 [CashRegisterRefreshService] ========== DEBUT RAFRAICHISSEMENT ==========`
- [ ] `✅ [CashRegisterRefreshService] Contrôleur trouvé` ou `⚠️ Contrôleur non trouvé, création temporaire`
- [ ] `💰 [CashRegisterRefreshService] Caisse: [Nom] - Solde: [Nouveau montant]`
- [ ] `🔄 [CashRegisterRefreshService] ========== FIN RAFRAICHISSEMENT ==========`

### Actualisation Auto (après 10s)
- [ ] `🔄 [CashRegisterController] ========== DEBUT ACTUALISATION AUTO ==========`
- [ ] `💰 [CashRegisterController] Mise à jour caisse: [Nom]`
- [ ] `📊 [CashRegisterController] Résumé actualisation`

## Rapport de bug

Si le problème persiste, copier ces informations:

### Informations système
- OS: Windows
- Backend démarré: Oui/Non
- Application Flutter démarrée: Oui/Non

### Données de test
- Solde caisse avant: _______ FCFA
- Montant paiement: _______ FCFA
- Solde caisse après: _______ FCFA
- Solde attendu: _______ FCFA

### Logs Backend
```
[Copier les logs du terminal backend ici]
```

### Logs Frontend
```
[Copier les logs de la console Flutter ici]
```

### Comportement observé
[Décrire ce qui se passe]

### Comportement attendu
[Décrire ce qui devrait se passer]

---

**Date:** 28 février 2026  
**Statut:** PRÊT POUR TEST AVEC LOGS DÉTAILLÉS
