# Stratégie de Licence par Plateforme

## 📋 Vue d'Ensemble

Logesco V2 utilise une stratégie de licence différenciée selon la plateforme pour maximiser l'adoption et le revenu:

| Plateforme | Licence | Objectif |
|-----------|---------|----------|
| **Web** | ❌ Désactivée (Freemium) | Acquisition utilisateurs |
| **Desktop** | ✅ Activée (Premium) | Monetisation entreprises |
| **Mobile** | ✅ Activée (Premium) | Monetisation utilisateurs mobiles |

---

## 🌐 Plateforme: WEB (Freemium)

**Configuration:**
```
enableLicenseControl = false  (forcément, même si --dart-define=ENABLE_LICENSE_CONTROL=true)
```

**Accès:**
- ✅ Accès complet gratuit
- ✅ Aucune période d'essai requise
- ✅ Aucune demande d'activation

**Cas d'usage:**
- Découverte du produit
- POC/démo
- Petites structures
- Evaluation gratuite

**Avantages:**
- 📈 Taux de conversion plus élevé
- 💰 Conversion vers desktop/mobile payant
- 🎯 Lead generation et analytics

**Limitations** (à imposer au niveau produit):
```
// Possibles limitations métier (non au niveau licence):
- Export PDF limité
- Reports avancés désactivés
- Intégrations tierces bloquées
- Historique limité à 30 jours
```

---

## 🖥️ Plateforme: DESKTOP (Premium)

**Configuration:**
```
enableLicenseControl = true  (par défaut)
```

**Accès:**
- ✅ Période d'essai 7 jours
- ✅ Licence payante requise après
- ✅ Toutes les fonctionnalités

**Cible:**
- Entreprises (PME, ETI)
- Utilisateurs pros
- Besoins hauts volume

**Avantages:**
- 💰 Principale source de revenu
- 🔒 Utilisateurs engagés
- 📊 Données fiables (contrôle horloge)

**Versions:**
```
Windows (`.exe`)  → Nuage d'utilisateurs pros
macOS (`.dmg`)    → Développeurs, creatives
Linux (`.AppImage`) → Tech-savvy, startups
```

---

## 📱 Plateforme: MOBILE (Premium)

**Configuration:**
```
enableLicenseControl = true  (par défaut)
```

**Accès:**
- ✅ Période d'essai 7 jours
- ✅ Licence payante requise après
- ✅ Accès offline robuste

**Cible:**
- Agents commerciaux
- Managers terrain
- Utilisateurs nomades

**Spécialité:**
- 📍 Mode offline avancé
- 🔄 Sync auto en background
- 🔋 Optimisé batterie

---

## 🔧 Implémentation Technique

### Détection Plateforme

**Fichier:** `logesco_v2/lib/core/config/app_config.dart`

```dart
import 'dart:io';
import 'package:flutter/foundation.dart';

class AppConfig {
  // Détection automatique
  static bool get isWeb => kIsWeb;
  static bool get isDesktop => !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
  static bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  
  // Licence INTELLIGENTE: Web=OFF, Desktop/Mobile=ON (configurable)
  static bool get enableLicenseControl {
    if (isWeb) {
      return false;  // ← Toujours false sur web
    }
    // Sur desktop/mobile: peut être override
    return bool.fromEnvironment('ENABLE_LICENSE_CONTROL', defaultValue: true);
  }
}
```

### Utilisation dans le Code

```dart
// ✅ Utiliser partout:
if (AppConfig.enableLicenseControl) {
  // Vérification licence
} else {
  // Accès gratuit
}

// ✅ Aussi disponible:
AppConfig.isWeb      // true = version web
AppConfig.isDesktop  // true = version desktop
AppConfig.isMobile   // true = version mobile
```

### Build Commands

#### Web (Licence OFF)
```bash
flutter build web --release
# enableLicenseControl = false automatiquement
```

#### Desktop - Windows (Licence ON)
```bash
flutter build windows --release \
  --dart-define=ENABLE_LICENSE_CONTROL=true
# enableLicenseControl = true
```

#### Desktop - macOS (Licence ON)
```bash
flutter build macos --release \
  --dart-define=ENABLE_LICENSE_CONTROL=true
# enableLicenseControl = true
```

#### Mobile - Android (Licence ON)
```bash
flutter build apk --release \
  --dart-define=ENABLE_LICENSE_CONTROL=true
# enableLicenseControl = true
```

---

## 🎯 Stratégie Commerciale

### Tunnel de Conversion

```
1. Utilisateur découvre web (gratuit)
   ↓ [Aime le produit?]
   
2. Télécharge desktop (essai 7j)
   ↓ [Prêt à acheter?]
   
3. Activation licence payante
   ↓ [Utilisateur sur le terrain?]
   
4. Mobile avec compte partagé
```

### Pricing Par Plateforme

**Suggestion:**
```
Web:     Gratuit (acquisition)
         └─ Inclut: Toutes fonctionnalités

Desktop: €29/mois (PME, comptables, gérants)
         └─ Inclut: Support, exports, intégrations

Mobile:  €9/mois (utilisateurs mobiles)
         └─ Inclut: Sync, offline, notifications
         
Bundle:  €35/mois (desktop + 3 mobile)
         └─ Inclut: Équipe complète
```

---

## 🔄 Cas d'Usage Par Plateforme

### Scénario 1: Petit Commerce
```
Jour 1: Découvre web (gratuit)
Jour 2-5: Teste sur web avec données
Jour 6: Aime → Télécharge desktop
Jour 7: Essai → Passe payant (€29)
Mois 2: Vendeur terrain → Ajoute mobile (€9)
```
**Résultat:** Client €38/mois (desktop + mobile)

### Scénario 2: Comptable
```
Jour 1: Web (gratuit) → Essai rapide
Jour 2: Desktop → Essai 7j avec vrais données
Jour 8: Payant (€29) → Utilisation quotidienne
```
**Résultat:** Client €29/mois (desktop)

### Scénario 3: Équipe Multi-sites
```
Jour 1: Web (gratuit) → POC central
Jour 7: Desktop (€29) → Gestionnaire principal
Semaine 2: Bundle (€35) → Ajoute 3 vendeurs
```
**Résultat:** Client €35/mois (4 utilisateurs)

---

## ✅ Checklist Déploiement

### Code
- [ ] `AppConfig.enableLicenseControl` retourne false sur web
- [ ] `AppConfig.isWeb / isDesktop / isMobile` fonctionnent
- [ ] Aucun hardcode de licence par plateforme ailleurs
- [ ] Tous les tests passent (web sans licence, desktop avec)

### Build
- [ ] `flutter build web --release` (pas de --dart-define)
- [ ] `flutter build windows --release` (avec --dart-define pour licence)
- [ ] `flutter build apk --release` (avec --dart-define pour licence)

### Deployment
- [ ] Web hébergée (pas de clé de licence requise)
- [ ] Desktop installable (avec essai 7j)
- [ ] Mobile sur stores (avec essai 7j)

### Documentation
- [ ] Support sait: Web=gratuit, Desktop=essai+payant
- [ ] FAQ explique les différences par plateforme
- [ ] Clients reçoivent email migration web→desktop

---

## 🚀 Phases de Rollout

### Phase 1: Desktop (Première)
```
Semaine 1-2: Web + Desktop
- Web: Gratuit (acquisition)
- Desktop: Essai 7j → Payant
- Mobile: Pas encore
```

### Phase 2: Mobile (Après)
```
Semaine 3-4: Ajouter mobile
- Web: Gratuit (inchangé)
- Desktop: Payant (inchangé)
- Mobile: Nouveau, essai 7j → Payant
```

### Phase 3: Bundles (Bonus)
```
Semaine 5+: Offrir bundles
- Desktop + Mobile: Réduction
- Équipes: License partagée
```

---

## 📊 Métriques à Suivre

| Métrique | Web | Desktop | Mobile |
|----------|-----|---------|--------|
| DAU | Gratuit | Essai+Payant | Essai+Payant |
| Conversion | Web→Desktop | Essai→Payant | Essai→Payant |
| Churn | N/A | % mensuel | % mensuel |
| LTV | N/A | €/utilisateur | €/utilisateur |
| CAC | Cost/install | Gratuit (web) | Gratuit (web) |

---

## 🔒 Sécurité et Conformité

### Web (Freemium)
- ✅ Aucune licence requise
- ✅ Données utilisateur chiffrées
- ✅ Pas de manipulation horloge possible
- ✅ Authentification API normale

### Desktop/Mobile (Premium)
- ✅ Licence requise et validée
- ✅ Manipulation horloge détectée
- ✅ Revocation server-side possible
- ✅ Audit trail de toutes les opérations

---

## 🎓 Documentation pour l'Équipe

### Support Client
```
Client web: "Pourquoi pas de licence?"
Réponse: Version freemium pour découverte

Client web: "Puis-je basculer vers desktop?"
Réponse: Bien sûr! Téléchargez desktop, 7j d'essai

Client desktop: "Puis-je utiliser sur web aussi?"
Réponse: Web n'a pas de licence, accès gratuit
```

### Product
```
Web:     Acquisition funnel
Desktop: Revenu principal
Mobile:  Revenue secondaire + cas d'usage mobile

Stratégie: Web gratuit → Desktop payant → Mobile bonus
```

### Dev
```
Vérifier: AppConfig.enableLicenseControl
- true = License validation active
- false = Freemium (aucune validation)

Pattern: if (AppConfig.enableLicenseControl) { ... }
```

---

## 📝 Exemple d'Utilisation

```dart
// Dans n'importe quel widget/controller:

// ✅ Vérifier si licence requise
if (AppConfig.enableLicenseControl) {
  // Desktop/Mobile → Vérifier licence
  final status = await subscriptionManager.getCurrentStatus();
  if (!status.isActive) {
    navigateToActivation();
    return;
  }
}

// ✅ Déterminer quelle plateforme
if (AppConfig.isWeb) {
  // Web: Afficher UI gratuite
  showWebUI();
} else if (AppConfig.isDesktop) {
  // Desktop: Afficher UI pro
  showDesktopUI();
} else if (AppConfig.isMobile) {
  // Mobile: Afficher UI mobile-optimized
  showMobileUI();
}
```

---

## ✨ Résumé

| Aspect | Web | Desktop | Mobile |
|--------|-----|---------|--------|
| **Licence** | ❌ Non | ✅ Oui | ✅ Oui |
| **Essai** | N/A | 7j | 7j |
| **Coût** | $0 | $29/mois | $9/mois |
| **Objectif** | Acquisition | Revenu | Revenu + Mobilité |
| **Cas d'usage** | Découverte | Pro quotidien | Sur le terrain |

---

**Déploiement:** Immédiat  
**Impact utilisateurs:** Zéro (web reste gratuit)  
**Impact revenu:** Positif (Desktop/Mobile payant)  
**Complexité:** Faible (détection automatique)
