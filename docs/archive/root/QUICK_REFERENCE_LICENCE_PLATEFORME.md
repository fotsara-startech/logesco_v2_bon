# Quick Reference - Licence par Plateforme

## 🎯 TL;DR

```
WEB      → Licence OFF (gratuit)
DESKTOP  → Licence ON (essai 7j + payant)
MOBILE   → Licence ON (essai 7j + payant)
```

---

## 🔍 Comment ça Marche?

### Code
```dart
// AppConfig détecte automatiquement:
AppConfig.isWeb      // true si version web
AppConfig.isDesktop  // true si version desktop
AppConfig.isMobile   // true si version mobile

// Et définit la licence:
AppConfig.enableLicenseControl
  → false si web
  → true si desktop/mobile (sauf override)
```

### Résultat
```
WEB:     enableLicenseControl = false → ✅ Accès gratuit
DESKTOP: enableLicenseControl = true  → ✅ Essai 7j → Payant
MOBILE:  enableLicenseControl = true  → ✅ Essai 7j → Payant
```

---

## 📲 Par Plateforme

### WEB
| Aspect | Valeur |
|--------|--------|
| URL | https://app.logesco.com |
| License | ❌ Non |
| Trial | N/A |
| Cost | Gratuit |
| Access | Complet |

### DESKTOP
| Aspect | Valeur |
|--------|--------|
| Installer | Windows/Mac/Linux |
| License | ✅ Oui |
| Trial | 7 jours |
| Cost | €29/mois |
| Access | Complet après paiement |

### MOBILE
| Aspect | Valeur |
|--------|--------|
| Store | Google Play, App Store |
| License | ✅ Oui |
| Trial | 7 jours |
| Cost | €9/mois |
| Access | Complet après paiement |

---

## 💬 Réponses Support Rapides

**Q: Pourquoi web n'a pas de licence?**
A: Version freemium pour découverte. Upgrade vers desktop/mobile si vous besoin.

**Q: Mon web ne marche pas (pas de licence)?**
A: C'est normal! Web est gratuit. Téléchargez desktop si besoin d'une licence.

**Q: Puis-je utiliser une seule licence sur web et desktop?**
A: Non, web n'a pas de licence. Prenez 1 licence desktop = accès desktop + web gratuit.

**Q: La licence desktop marche sur web aussi?**
A: Non, web est toujours gratuit. Votre licence desktop = accès desktop seulement.

---

## 🔧 Build Commands

**Web**
```bash
flutter build web --release
# enableLicenseControl = false ← Automatique
```

**Desktop**
```bash
flutter build windows --release --dart-define=ENABLE_LICENSE_CONTROL=true
flutter build macos --release --dart-define=ENABLE_LICENSE_CONTROL=true
flutter build linux --release --dart-define=ENABLE_LICENSE_CONTROL=true
```

**Mobile**
```bash
flutter build apk --release --dart-define=ENABLE_LICENSE_CONTROL=true
flutter build ios --release --dart-define=ENABLE_LICENSE_CONTROL=true
```

---

## ✅ Checklist Déploiement

- [ ] `AppConfig.enableLicenseControl` fonctionne
- [ ] Web = false (license OFF)
- [ ] Desktop = true (license ON)
- [ ] Mobile = true (license ON)
- [ ] Pas de compilation errors
- [ ] Support notifié des différences
- [ ] FAQ mise à jour

---

## 📊 Pricing

```
WEB:            Gratuit
DESKTOP:        €29/mois
MOBILE:         €9/mois
DESKTOP+MOBILE: €35/mois (bundle)
```

---

## 🚀 Déploiement

**Quand:** Immédiatement  
**Risque:** Zéro (web gratuit, desktop/mobile optional)  
**Impact:** Positif (monetisation)  

---

## 🔗 Documents Complets

- `STRATEGIE_LICENCE_PAR_PLATEFORME.md` - Vue complète
- `RESOLUTION_BLOCAGE_OFFLINE.md` - Mode offline
- `PARAMETRES_LICENCE_OFFLINE.md` - Configuration
- `GUIDE_MIGRATION_LICENCE_OFFLINE.md` - Déploiement
