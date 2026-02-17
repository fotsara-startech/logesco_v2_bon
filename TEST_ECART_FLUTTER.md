# Test de l'Écart de Caisse - Flutter

## 🎯 Objectif
Identifier pourquoi l'écart s'affiche comme "+0 F" dans l'interface Flutter alors que le backend calcule correctement l'écart.

## ✅ Confirmation Backend
Le backend fonctionne parfaitement:
```
📊 RÉSUMÉ CLÔTURE caisse Caisse Acceuil:
   ✓ Solde ouverture: 0 FCFA
   ✓ Solde attendu: 12000 FCFA
   ✓ Solde déclaré: 5000 FCFA
   ✗ Écart: -7000 FCFA

✅ SESSION ENREGISTRÉE DANS LA BASE:
   ID: 17
   soldeFermeture: 5000
   soldeAttendu: 12000
   ecart: -7000
```

## 🔍 Logs Ajoutés

### 1. Dans le Contrôleur (`cash_session_controller.dart`)
```dart
Future<bool> disconnectFromCashRegister(double soldeFermeture) async {
  print('═══════════════════════════════════════════════════════════');
  print('🔍 FLUTTER - DÉBUT CLÔTURE DE CAISSE');
  print('═══════════════════════════════════════════════════════════');
  print('📤 Envoi au backend: soldeFermeture = $soldeFermeture FCFA');
  
  final session = await CashSessionService.disconnectFromCashRegister(soldeFermeture);
  
  print('📥 Réponse reçue du backend:');
  print('   Session ID: ${session.id}');
  print('   soldeOuverture: ${session.soldeOuverture}');
  print('   soldeAttendu: ${session.soldeAttendu}');
  print('   soldeFermeture: ${session.soldeFermeture}');
  print('   ecart: ${session.ecart}');
  print('   Type ecart: ${session.ecart.runtimeType}');
  // ...
}
```

### 2. Dans le Service (`cash_session_service.dart`)
```dart
static Future<CashSession> disconnectFromCashRegister(double soldeFermeture) async {
  print('🌐 SERVICE - Envoi requête disconnect:');
  print('   URL: ${ApiConfig.currentBaseUrl}$_endpoint/disconnect');
  print('   Body: ${json.encode(body)}');
  
  final response = await http.post(...);
  
  print('🌐 SERVICE - Réponse reçue:');
  print('   Status: ${response.statusCode}');
  print('   Body: ${response.body}');
  
  final session = CashSession.fromJson(data['data']);
  
  print('🌐 SERVICE - Session créée:');
  print('   ecart: ${session.ecart}');
  // ...
}
```

### 3. Dans le Modèle (`cash_session_model.dart`)
```dart
factory CashSession.fromJson(Map<String, dynamic> json) {
  print('📦 MODEL - Parsing CashSession:');
  print('   json[\'ecart\']: ${json['ecart']}');
  print('   Type: ${json['ecart'].runtimeType}');
  
  final ecartValue = json['ecart'] != null ? (json['ecart']).toDouble() : null;
  print('   ecart parsé: $ecartValue');
  // ...
}
```

## 📋 Procédure de Test

### Étape 1: Redémarrer l'Application Flutter
```bash
# Arrêter l'application
# Puis relancer avec:
flutter run
```

### Étape 2: Ouvrir une Nouvelle Session
1. Aller dans "Gestion de Caisse"
2. Cliquer sur "Se connecter à une caisse"
3. Sélectionner "Caisse Acceuil"
4. Entrer un solde d'ouverture (ex: 50000 FCFA)
5. Confirmer

### Étape 3: Faire des Ventes (Optionnel)
1. Aller dans "Ventes"
2. Créer quelques ventes pour modifier le solde attendu
3. Vérifier que le solde attendu augmente

### Étape 4: Clôturer avec un Écart
1. Retourner dans "Gestion de Caisse"
2. Cliquer sur "Clôturer la session"
3. Entrer un montant DIFFÉRENT du solde attendu
   - Exemple: Si solde attendu = 60000, entrer 55000 (manque 5000)
4. Confirmer la clôture

### Étape 5: Observer les Logs
Regarder la console Flutter pour voir:
```
═══════════════════════════════════════════════════════════
🔍 FLUTTER - DÉBUT CLÔTURE DE CAISSE
═══════════════════════════════════════════════════════════
📤 Envoi au backend: soldeFermeture = 55000.0 FCFA

🌐 SERVICE - Envoi requête disconnect:
   URL: http://localhost:8080/api/v1/cash-sessions/disconnect
   Body: {"soldeFermeture":55000.0}

🌐 SERVICE - Réponse reçue:
   Status: 200
   Body: {"success":true,"data":{...,"ecart":-5000,...}}

📦 MODEL - Parsing CashSession:
   json['ecart']: -5000
   Type: int (ou double)
   ecart parsé: -5000.0

📥 Réponse reçue du backend:
   Session ID: 18
   soldeOuverture: 50000.0
   soldeAttendu: 60000.0
   soldeFermeture: 55000.0
   ecart: -5000.0
   Type ecart: double
═══════════════════════════════════════════════════════════
```

### Étape 6: Vérifier l'Affichage
1. Le dialog de résumé doit afficher l'écart correct
2. L'historique doit montrer l'écart correct

## 🔍 Points à Vérifier

### Si l'écart est NULL dans les logs Flutter:
- Le backend n'envoie pas l'écart
- Problème de sérialisation JSON côté backend

### Si l'écart est correct dans les logs mais pas dans l'UI:
- Problème d'affichage dans les widgets
- Vérifier `cash_session_history_view.dart`
- Vérifier le dialog de résumé dans le contrôleur

### Si l'écart est 0 dans les logs Flutter:
- Problème de parsing dans `CashSession.fromJson`
- Le backend envoie peut-être 0 au lieu de la valeur calculée

## 🎯 Widgets à Vérifier

### 1. Dialog de Résumé (dans le contrôleur)
```dart
void _showSessionSummary(CashSession session) {
  final ecart = session.ecart ?? 0.0;  // ← Vérifier ici
  final isPositive = ecart >= 0;
  // ...
}
```

### 2. Historique des Sessions
Fichier: `logesco_v2/lib/features/cash_registers/views/cash_session_history_view.dart`

Chercher où l'écart est affiché et vérifier le code.

### 3. Détails de Session
Fichier: `logesco_v2/lib/features/cash_registers/views/cash_session_detail_view.dart`

Vérifier comment l'écart est affiché.

## 📊 Résultats Attendus

Après le test, vous devriez voir:

1. **Dans les logs Flutter**: L'écart correct (-5000 dans l'exemple)
2. **Dans le dialog de résumé**: "Écart: -5000 FCFA" en orange/rouge
3. **Dans l'historique**: L'écart affiché correctement pour chaque session

## 🐛 Si le Problème Persiste

### Scénario 1: L'écart est NULL dans Flutter
→ Le backend ne renvoie pas l'écart dans la réponse
→ Vérifier la route `/disconnect` côté backend

### Scénario 2: L'écart est 0 dans Flutter
→ Problème de parsing JSON
→ Vérifier `CashSession.fromJson`

### Scénario 3: L'écart est correct dans les logs mais pas dans l'UI
→ Problème d'affichage
→ Vérifier les widgets d'historique et de détails

## 📝 Fichiers Modifiés

- `logesco_v2/lib/features/cash_registers/controllers/cash_session_controller.dart` - Logs ajoutés
- `logesco_v2/lib/features/cash_registers/services/cash_session_service.dart` - Logs ajoutés
- `logesco_v2/lib/features/cash_registers/models/cash_session_model.dart` - Logs ajoutés

## ✅ Prochaines Étapes

1. **Redémarrer l'app Flutter** avec les nouveaux logs
2. **Faire un test complet** de clôture
3. **Copier les logs** de la console Flutter
4. **Partager les logs** pour analyse

Les logs nous diront exactement où le problème se situe dans le flux de données.
