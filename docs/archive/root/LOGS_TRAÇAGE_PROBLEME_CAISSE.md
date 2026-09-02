# Logs de Traçage - Problème Mise à Jour Solde Caisse

## Logs ajoutés

Des logs détaillés ont été ajoutés à trois niveaux pour tracer le problème de mise à jour du solde de caisse après paiement de dette client.

## 1. Backend - Route de paiement

**Fichier:** `backend/src/routes/customers.js`

### Logs ajoutés

```
🔍 [Payment] Recherche de la caisse active...
✅ [Payment] Caisse active trouvée: [Nom] (ID: [ID])
💰 [Payment] Mise à jour de la caisse active: [Nom]
  - Solde actuel caisse: [Montant] FCFA
  - Montant à ajouter: [Montant] FCFA
  - Nouveau solde caisse: [Montant] FCFA
✅ [Payment] Caisse mise à jour avec succès
  - Nouveau solde confirmé: [Montant] FCFA
✅ [Payment] Mouvement de caisse créé (ID: [ID])
✅ [Payment] Solde de la caisse mis à jour avec succès
```

### Cas d'erreur

```
⚠️ [Payment] Aucune caisse active trouvée
⚠️ [Payment] Critères de recherche:
  - isActive: true
  - dateOuverture: not null
  - dateFermeture: null
⚠️ [Payment] Le paiement est enregistré mais le solde de caisse n'est pas mis à jour
```

## 2. Frontend - Service de rafraîchissement

**Fichier:** `logesco_v2/lib/core/services/cash_register_refresh_service.dart`

### Logs ajoutés

```
🔄 [CashRegisterRefreshService] ========== DEBUT RAFRAICHISSEMENT ==========
🔄 [CashRegisterRefreshService] Tentative de rafraîchissement des caisses
✅ [CashRegisterRefreshService] Contrôleur trouvé, rafraîchissement...
📊 [CashRegisterRefreshService] Nombre de caisses avant: [N]
📊 [CashRegisterRefreshService] Nombre de caisses après: [N]
💰 [CashRegisterRefreshService] Caisse: [Nom] - Solde: [Montant] FCFA - Active: [true/false]
✅ [CashRegisterRefreshService] Caisses rafraîchies via contrôleur existant
🔄 [CashRegisterRefreshService] ========== FIN RAFRAICHISSEMENT ==========
```

### Cas contrôleur non trouvé

```
⚠️ [CashRegisterRefreshService] Contrôleur non trouvé, création temporaire...
📊 [CashRegisterRefreshService] Contrôleur temporaire créé
📊 [CashRegisterRefreshService] Nombre de caisses chargées: [N]
💰 [CashRegisterRefreshService] Caisse: [Nom] - Solde: [Montant] FCFA - Active: [true/false]
✅ [CashRegisterRefreshService] Caisses rafraîchies via contrôleur temporaire
```

### Cas d'erreur

```
❌ [CashRegisterRefreshService] ========== ERREUR RAFRAICHISSEMENT ==========
❌ [CashRegisterRefreshService] Erreur lors du rafraîchissement: [Message]
❌ [CashRegisterRefreshService] Stack trace: [Stack]
❌ [CashRegisterRefreshService] ========================================
```

## 3. Frontend - Contrôleur de caisse

**Fichier:** `logesco_v2/lib/features/cash_registers/controllers/cash_register_controller.dart`

### Logs ajoutés (actualisation automatique)

```
🔄 [CashRegisterController] ========== DEBUT ACTUALISATION AUTO ==========
🔄 [CashRegisterController] Actualisation automatique des soldes...
📊 [CashRegisterController] [N] caisse(s) récupérée(s) de l'API
💰 [CashRegisterController] Mise à jour caisse: [Nom]
   Ancien solde: [Montant] FCFA → Nouveau solde: [Montant] FCFA
➕ [CashRegisterController] Nouvelle caisse ajoutée: [Nom]
📊 [CashRegisterController] Résumé actualisation:
   - Caisses mises à jour: [N]
   - Caisses ajoutées: [N]
   - Caisses supprimées: [N]
   - Total caisses: [N]
🔄 [CashRegisterController] ========== FIN ACTUALISATION AUTO ==========
```

### Cas d'erreur

```
❌ [CashRegisterController] ========== ERREUR ACTUALISATION ==========
❌ [CashRegisterController] Erreur lors de l'actualisation automatique des caisses: [Message]
❌ [CashRegisterController] Stack trace: [Stack]
❌ [CashRegisterController] ========================================
```

## Flux complet des logs

### Scénario normal (succès)

1. **Paiement effectué**
```
[Backend] 🔍 Recherche de la caisse active...
[Backend] ✅ Caisse active trouvée: Caisse Principale (ID: 1)
[Backend] 💰 Mise à jour de la caisse active: Caisse Principale
[Backend]   - Solde actuel caisse: 50000 FCFA
[Backend]   - Montant à ajouter: 500 FCFA
[Backend]   - Nouveau solde caisse: 50500 FCFA
[Backend] ✅ Caisse mise à jour avec succès
[Backend]   - Nouveau solde confirmé: 50500 FCFA
[Backend] ✅ Mouvement de caisse créé (ID: 123)
[Backend] ✅ Solde de la caisse mis à jour avec succès
```

2. **Rafraîchissement frontend**
```
[Frontend] 🔄 ========== DEBUT RAFRAICHISSEMENT ==========
[Frontend] 🔄 Tentative de rafraîchissement des caisses
[Frontend] ✅ Contrôleur trouvé, rafraîchissement...
[Frontend] 📊 Nombre de caisses avant: 3
[Frontend] 📊 Nombre de caisses après: 3
[Frontend] 💰 Caisse: Caisse Principale - Solde: 50500 FCFA - Active: true
[Frontend] ✅ Caisses rafraîchies via contrôleur existant
[Frontend] 🔄 ========== FIN RAFRAICHISSEMENT ==========
```

3. **Actualisation automatique (10s)**
```
[Controller] 🔄 ========== DEBUT ACTUALISATION AUTO ==========
[Controller] 🔄 Actualisation automatique des soldes...
[Controller] 📊 3 caisse(s) récupérée(s) de l'API
[Controller] 💰 Mise à jour caisse: Caisse Principale
[Controller]    Ancien solde: 50000 FCFA → Nouveau solde: 50500 FCFA
[Controller] 📊 Résumé actualisation:
[Controller]    - Caisses mises à jour: 1
[Controller]    - Caisses ajoutées: 0
[Controller]    - Caisses supprimées: 0
[Controller]    - Total caisses: 3
[Controller] 🔄 ========== FIN ACTUALISATION AUTO ==========
```

## Diagnostic des problèmes

### Problème 1: Aucune caisse active

**Symptôme:**
```
[Backend] ⚠️ Aucune caisse active trouvée
```

**Cause:** Aucune caisse n'est ouverte

**Solution:** Ouvrir une caisse avant d'effectuer le paiement

### Problème 2: Contrôleur non enregistré

**Symptôme:**
```
[Frontend] ⚠️ Contrôleur non trouvé, création temporaire...
```

**Cause:** Page des caisses jamais visitée

**Solution:** Le service crée automatiquement un contrôleur temporaire

### Problème 3: Solde non mis à jour dans l'interface

**Symptôme:**
```
[Controller] 📊 Résumé actualisation:
   - Caisses mises à jour: 0
```

**Cause:** Le solde n'a pas changé dans la base de données

**Solution:** Vérifier les logs backend pour voir si la mise à jour a réussi

### Problème 4: Erreur de rafraîchissement

**Symptôme:**
```
[Frontend] ❌ Erreur lors du rafraîchissement: [Message]
```

**Cause:** Problème de connexion ou erreur API

**Solution:** Vérifier la connexion au backend et les logs d'erreur

## Comment utiliser les logs

### 1. Effectuer un paiement de dette

1. Ouvrir la console/terminal
2. Effectuer un paiement de dette client
3. Observer les logs en temps réel

### 2. Analyser les logs

**Backend (terminal du serveur):**
- Chercher `[Payment]` pour voir la mise à jour de la caisse
- Vérifier que le solde est bien mis à jour
- Vérifier qu'un mouvement de caisse est créé

**Frontend (console Flutter):**
- Chercher `[CashRegisterRefreshService]` pour voir le rafraîchissement
- Chercher `[CashRegisterController]` pour voir l'actualisation auto
- Vérifier que les soldes sont mis à jour

### 3. Identifier le problème

**Si le backend ne met pas à jour:**
- Vérifier qu'une caisse est ouverte
- Vérifier les critères de recherche de la caisse active

**Si le frontend ne rafraîchit pas:**
- Vérifier que le service est appelé
- Vérifier que le contrôleur est trouvé ou créé
- Vérifier qu'il n'y a pas d'erreur

**Si l'actualisation auto ne fonctionne pas:**
- Vérifier que le timer est démarré
- Vérifier qu'il n'y a pas d'erreur dans les logs
- Attendre 10 secondes pour voir l'actualisation

## Fichiers modifiés

```
backend/src/routes/customers.js
├── Logs détaillés de mise à jour caisse
└── Logs d'erreur si caisse non trouvée

logesco_v2/lib/core/services/cash_register_refresh_service.dart
├── Logs de début/fin de rafraîchissement
├── Logs de nombre de caisses
├── Logs de soldes avant/après
└── Logs d'erreur avec stack trace

logesco_v2/lib/features/cash_registers/controllers/cash_register_controller.dart
├── Logs d'actualisation automatique
├── Logs de mise à jour des soldes
├── Logs de résumé (updated/added/removed)
└── Logs d'erreur avec stack trace
```

## Redémarrage requis

**Backend:** OUI - Redémarrer pour que les nouveaux logs soient actifs
**Frontend:** OUI - Hot reload ou redémarrer l'app

```bash
# Redémarrer le backend
restart-backend-quick.bat

# Redémarrer l'app Flutter
# Hot reload (R) ou Hot restart (Shift+R)
```

---

**Date:** 28 février 2026  
**Statut:** LOGS AJOUTÉS - PRÊT POUR DIAGNOSTIC
