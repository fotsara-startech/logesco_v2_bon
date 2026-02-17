# Guide de Test Flutter - LOGESCO v2

## 🚀 Démarrage Rapide

### Prérequis
- Flutter SDK 3.0+
- Dart SDK 3.0+
- Émulateur Android/iOS ou appareil physique (pour tests d'intégration)

### Installation des Dépendances
```bash
cd logesco_v2
flutter pub get
```

## 🧪 Types de Tests

### 1. Tests Unitaires
```bash
flutter test
```
**Teste :**
- Modèles de données
- Logique métier
- Services API (configuration)
- Validation des formulaires

### 2. Tests d'Intégration
```bash
flutter test integration_test/
```
**Teste :**
- Navigation complète
- Interaction avec le backend
- Flux utilisateur end-to-end
- Performance de l'interface

### 3. Tests Manuels
```bash
flutter run
```
**Permet de :**
- Tester l'expérience utilisateur
- Vérifier l'interface sur différents écrans
- Valider les animations et transitions

## 📱 Configuration des Appareils

### Émulateur Android
```bash
# Lister les émulateurs disponibles
flutter emulators

# Lancer un émulateur
flutter emulators --launch <emulator_id>

# Vérifier les appareils connectés
flutter devices
```

### Appareil Physique
1. Activer le mode développeur
2. Activer le débogage USB
3. Connecter l'appareil
4. Vérifier avec `flutter devices`

## 🔧 Scripts Disponibles

### Script Automatique
```bash
# Windows
test_runner.bat

# Ou manuellement
flutter pub get
flutter test
flutter test integration_test/
flutter run
```

### Tests Spécifiques
```bash
# Tests unitaires seulement
flutter test test/

# Tests d'intégration seulement
flutter test integration_test/

# Test spécifique
flutter test test/widget_test.dart
flutter test integration_test/app_test.dart
```

## 📊 Structure des Tests

```
logesco_v2/
├── test/                          # Tests unitaires
│   ├── widget_test.dart          # Tests des widgets
│   ├── models/                   # Tests des modèles
│   ├── services/                 # Tests des services
│   └── utils/                    # Tests des utilitaires
├── integration_test/             # Tests d'intégration
│   ├── app_test.dart            # Tests principaux
│   ├── test_config.dart         # Configuration
│   └── flows/                   # Tests de flux métier
└── test_runner.bat              # Script de lancement
```

## 🎯 Tests Implémentés

### Tests Unitaires Actuels
- ✅ Création de l'application
- ✅ Configuration de base
- ✅ Validation des données utilisateur
- ✅ Validation des données produit
- ✅ Configuration des services API

### Tests d'Intégration Actuels
- ✅ Démarrage de l'application
- ✅ Navigation de base
- ✅ Test de connectivité réseau
- 🔄 Tests détaillés (en cours d'implémentation)

## 📈 Tests de Performance

### Métriques Surveillées
- **Temps de démarrage** : < 3 secondes
- **Temps de navigation** : < 1 seconde
- **Réponse API** : < 2 secondes
- **Rendu des listes** : < 500ms

### Commandes de Performance
```bash
# Profiling de performance
flutter run --profile

# Analyse de la taille de l'app
flutter build apk --analyze-size

# Tests de performance
flutter test --reporter=json > test_results.json
```

## 🔍 Débogage

### Logs Détaillés
```bash
# Logs verbeux
flutter test --verbose

# Logs avec stack traces
flutter test --reporter=expanded
```

### Débogage des Tests d'Intégration
```bash
# Mode debug avec breakpoints
flutter test integration_test/ --debug

# Screenshots automatiques en cas d'échec
flutter test integration_test/ --screenshot-on-failure
```

## 📋 Données de Test

### Utilisateur de Test
- **Email** : `integration.test@logesco.local`
- **Mot de passe** : `TestPassword123!`
- **Rôle** : Admin

### Données Réalistes
- **Produits** : iPhone, Dell XPS, etc.
- **Clients** : Particuliers et entreprises
- **Prix** : Valeurs réelles du marché

## ⚠️ Bonnes Pratiques

### Tests Unitaires
- Tester une seule fonctionnalité par test
- Utiliser des mocks pour les dépendances externes
- Noms de tests descriptifs
- Assertions claires et précises

### Tests d'Intégration
- Tester les flux utilisateur complets
- Vérifier les états de l'interface
- Gérer les timeouts appropriés
- Nettoyer les données après les tests

### Performance
- Éviter les tests trop longs
- Paralléliser quand possible
- Utiliser des données de test optimisées
- Surveiller la mémoire et le CPU

## 🚨 Dépannage

### Erreurs Communes

#### "No connected devices"
```bash
flutter devices
flutter emulators --launch <emulator>
```

#### "Pub get failed"
```bash
flutter clean
flutter pub get
```

#### "Integration test timeout"
- Vérifier que le backend est démarré
- Augmenter les timeouts dans `test_config.dart`
- Vérifier la connectivité réseau

#### "Widget not found"
- Ajouter des `await tester.pumpAndSettle()`
- Vérifier les sélecteurs de widgets
- Utiliser `find.byKey()` pour des éléments spécifiques

### Logs Utiles
```bash
# Logs Flutter
flutter logs

# Logs de l'appareil
adb logcat (Android)
idevicesyslog (iOS)
```

## 📞 Support

En cas de problème :
1. Vérifier `flutter doctor`
2. Consulter les logs détaillés
3. Tester sur un autre appareil/émulateur
4. Vérifier la connectivité au backend

---

**Tests réussis = Application robuste ! 🧪✨**