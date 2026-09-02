# Guide de Migration - Système de Licence Offline

## 📋 Aperçu

Ce document guide le déploiement de la nouvelle version du système de licence avec support offline robuste.

**Version:** 2.1.0+
**Type:** Mise à jour mineure (backward compatible)
**Risque:** Faible (0 breaking changes)
**Temps déploiement:** 5-10 minutes

---

## ✅ Checklist Pre-Déploiement

### Code Review
- [ ] Vérifier `secure_time_service.dart` - Timeouts NTP courts
- [ ] Vérifier `subscription_manager.dart` - Mode dégradé activé
- [ ] Vérifier `subscription_middleware.dart` - Logique souple
- [ ] Tester localement en mode offline (WiFi désactivé)
- [ ] Vérifier compilation sans erreurs

### Configuration
- [ ] Revoir les paramètres dans `PARAMETRES_LICENCE_OFFLINE.md`
- [ ] Confirmer profil choisi (Performance/Sécurité/Essai/Entreprise)
- [ ] Vérifier `AppConfig.enableLicenseControl = true` (production)
- [ ] Sauvegarder version précédente (rollback)

### Documentation
- [ ] Équipe Support: Lire `RESOLUTION_BLOCAGE_OFFLINE.md`
- [ ] Équipe QA: Lire cas test recommandés
- [ ] Équipe Prod: Préparer monitoring

---

## 🚀 Étapes de Déploiement

### 1. Préparation (15 min)
```bash
# Brancher depuis main
git checkout -b feature/license-offline-support

# Copier les fichiers modifiés:
# - secure_time_service.dart
# - subscription_manager.dart
# - subscription_middleware.dart
# - subscription_controller.dart (nouvelle méthode canContinueOffline)

# Rebuild app
flutter clean
flutter pub get
flutter build apk --release  # ou ios pour iOS
```

### 2. Tests Locaux (30 min)

#### Test 1: Mode Offline Normal
```
1. Installer app
2. Désactiver WiFi + données mobiles
3. Lancer app
4. ✅ Doit fonctionner avec warning "mode offline"
5. Réactiver réseau
6. ✅ Doit valider automatiquement après 5-10s
```

#### Test 2: NTP Timeout (Réseau Lent)
```
1. Throttle réseau à 1 Mbps (DevTools)
2. Forcer validation (menu Support)
3. ✅ UI ne doit jamais geler (max 2s)
4. ✅ Doit completer avec succès ou fallback
```

#### Test 3: Première Activation
```
1. Fresh install (données effacées)
2. Lancer app
3. ✅ Doit afficher essai 7j ou écran d'activation
4. Entrer clé de licence valide
5. ✅ Doit valider et accorder accès
```

#### Test 4: Licen Expirée + Grâce
```
1. Forcer date système: date_expiration + 1 jour
2. Relancer app
3. ✅ Doit afficher avertissement MAIS accès autorisé
4. Forcer date: date_expiration + 5 jours (hors grâce)
5. ✅ Doit bloquer avec écran d'activation
```

#### Test 5: Manipulation Horloge
```
1. Forcer date système: -1 jour
2. Relancer app
3. ✅ Doit détecter et bloquer avec message
4. Restaurer date correcte
5. ✅ Doit fonctionner à nouveau
```

### 3. Déploiement Beta (2-3 jours)

```bash
# Publier sur beta channel
# - Google Play: Beta testing
# - TestFlight: Testing
# - APK direct: Beta testers

# Configuration:
# AppConfig.enableLicenseControl = true
# Dans PARAMETRES_LICENCE_OFFLINE.md: Profil "Performance"
```

**Monitoring beta:**
- 📊 Nombre d'utilisateurs offline
- ⏱️ Durée moyenne getSecureTime()
- ⚠️ Erreurs NTP (par serveur)
- 📉 Taux de blocage

**Critères succès:**
- ✅ 0 crashes liés à licence
- ✅ < 5% d'erreurs NTP
- ✅ Durée NTP < 3 secondes

### 4. Déploiement Production (1-2 heures)

```bash
# Rollout par étapes (Google Play Phases)
# Phase 1: 5% des utilisateurs
# Phase 2: 25% (après 6h, si OK)
# Phase 3: 100% (après 12h, si OK)
```

**Configuration:**
```dart
// app_config.dart
static const bool enableLicenseControl = true;  // Production

// CHOISIR UN PROFIL (cf. PARAMETRES_LICENCE_OFFLINE.md):
// - Performance (instable) 
// - Sécurité (fiable)
// - Essai Généreux (freemium)
// - Entreprise (offline équipe)
```

---

## 🔄 Processus Rollback

**Si problèmes détectés:**

### Rollback Immédiat (Critique)
```bash
# Si: Crashes fréquents, ou blocages généralisés

# Option 1: Revert tout
git revert <commit>
git push
# Redéployer précédente version

# Option 2: Désactiver license control
# Dans app_config.dart:
static const bool enableLicenseControl = false;
# Redéployer (accès gratuit temporaire)
```

### Rollback Progressif (Urgent)
```bash
# Si: Problèmes limités à certains cas

# Option 1: Réduire rollout % (Google Play)
# Revenir à 5% → diagnostiquer → corriger

# Option 2: Ajuster paramètres (pas de redéploiement)
# Augmenter _ntpTimeout
# Réduire _validationIntervalMinutes
# Augmenter _maxNtpFailuresBeforeOffline
```

---

## 📞 Gestion des Incidents

### Incident: "App se bloque toujours"

**Investigation:**
```
1. Vérifier version app (doit être 2.1.0+)
2. Vérifier AppConfig.enableLicenseControl = true
3. Demander logs: Menu Support > Diagnostics
4. Chercher "Retour en arrière détecté" dans logs
   - Si OUI: Problème horloge système
   - Si NON: Problème NTP
```

**Solutions:**
```
Si manipulation horloge:
├─ Utilisateur: Restaurer date/heure système
└─ Tech: Forcer `SecureTimeService.recordFirstActivation(now)`

Si problème NTP:
├─ Réduire _ntpTimeout à 1 seconde
├─ Réduire _maxNtpRetries à 1
└─ Augmenter _maxNtpFailuresBeforeOffline à 2
```

### Incident: "Utilisateurs offline ne peuvent plus accéder"

**Vérifier:**
```
1. Licence valide? (vérifier expiration)
2. Première activation jamais faite?
   - Si OUI: Besoin internet pour 1ère validation
   - Si NON: Doit marcher en offline

3. Mode offline détecté?
   - Logs: "isOfflineMode: true"
   - Si OUI: Problème de logique
```

**Fix:**
```dart
// Dans shouldBlockApplication():
// Vérifier condition:
if (await _secureTimeService.getFirstActivation() != null && 
    _secureTimeService.isOfflineMode) {
  return false;  // Laisser accéder
}
```

### Incident: "Validation NTP échoue 100% du temps"

**Debug:**
```
1. Tester serveurs NTP manuellement:
   nslookup time.google.com
   nslookup pool.ntp.org
   
2. Si tous refusent: Problème réseau infrastructure
   
3. Si serveurs 3rd party problématiques:
   // Dans secure_time_service.dart
   static const List<String> _ntpServers = [
     'time.google.com',
     'time.windows.com',  // Remplacer pool.ntp.org
     'time.cloudflare.com',
   ];
```

---

## 🧪 Tests Post-Déploiement

### Daily (Premiers 3 jours)
```
□ Vérifier crash logs (Firebase, Sentry)
□ Vérifier error rates
□ Vérifier utilisateurs offline
□ Support: Aucune plainte de blocage?
```

### Weekly (Première semaine)
```
□ Analytics: Taux d'utilisation app
□ Performance: Temps app startup
□ License validation: % de succès
□ Grace period: Utilisateurs bloqués?
```

### Monthly (Premier mois)
```
□ Satisfaction: Feedback utilisateurs
□ Stabilité: Tendance des crashes
□ Offline: % utilisateurs offline vs online
□ Support: Tickets licences diminués?
```

---

## 📊 KPIs à Suivre

| KPI | Target | Alerte |
|-----|--------|--------|
| Crash Rate | < 0.1% | > 0.5% |
| License Validation Success | > 95% | < 90% |
| NTP Response Time | < 2s | > 5s |
| Offline Activation Rate | < 5% | > 15% |
| User Satisfaction | > 4.5/5 | < 4.0/5 |

---

## 🎓 Documentation pour l'Équipe

### Pour Support Client
Lire: `RESOLUTION_BLOCAGE_OFFLINE.md`
- Expliquer le mode offline
- Quand et pourquoi ça survient
- Comment diagnostiquer

### Pour QA
Lire: `RESOLUTION_BLOCAGE_OFFLINE.md` (Cas de Test)
- Tous les 5 cas test obligatoires
- Paramétrage réseau pour simulation

### Pour DevOps
Lire: `PARAMETRES_LICENCE_OFFLINE.md`
- Profils recommandés
- Comment ajuster paramètres
- Monitoring à mettre en place

### Pour Produit
Lire: `RESOLUTION_BLOCAGE_OFFLINE.md` (Résumé)
- Problème résolu
- Impact performance
- Sécurité maintenue

---

## ✨ Success Criteria

Déploiement réussi si:

✅ **Aucun crash** lié à licence  
✅ **Offline marche** pour licences valides  
✅ **Pas de gel UI** (max 2s pour NTP)  
✅ **Validation auto** quand réseau revient  
✅ **Support reçoit 50% moins** de tickets blocage  
✅ **Utilisateurs satisfaits** (> 4.5/5 ratings)  

---

## 🔐 Checklist Final Pre-Production

### Code
- [ ] Tous les fichiers compilent sans erreur
- [ ] Tests unitaires passent (si existants)
- [ ] Aucun warning critique

### Configuration
- [ ] `AppConfig.enableLicenseControl = true`
- [ ] Paramètres choisis = Profil sélectionné
- [ ] Aucune clé privée en dur

### Sécurité
- [ ] Manipulation horloge = Blocage
- [ ] Licences tampérées = Blocage
- [ ] Tokens API = Gérés normalement

### Documentation
- [ ] Support a `RESOLUTION_BLOCAGE_OFFLINE.md`
- [ ] QA a `GUIDE_TEST_STOCK_SNAPSHOTS.md` (+ test licences)
- [ ] Produit notifié de la release

### Monitoring
- [ ] Dashboards setupés
- [ ] Alertes configurées
- [ ] On-call prêt

---

**Dès approbation, procéder au déploiement! 🚀**
