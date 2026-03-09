# Test de la Langue des Factures

## Statut
✅ Base de données: langue = "en" (vérifié)
✅ Backend: retourne bien langueFacture
✅ Flutter: mapping ajouté dans le service
⚠️ Problème: Cache du profil d'entreprise

## Corrections Appliquées

### 1. Backend
- ✅ Schéma de validation Joi mis à jour
- ✅ Endpoint `/public` retourne `langueFacture`
- ✅ Base de données contient "en"

### 2. Flutter
- ✅ Service: mapping `receiptLanguage` ajouté (5 endroits)
- ✅ Contrôleur: mise à jour du profil partagé après sauvegarde
- ✅ Contrôleur: mise à jour du profil partagé après chargement
- ✅ Logs ajoutés pour déboguer

## Instructions de Test

### Étape 1: Redémarrer l'Application Flutter
```bash
# Arrêter l'application Flutter
# Puis relancer avec:
flutter run
```

### Étape 2: Vider le Cache (Option 1 - Recommandé)
Dans l'application Flutter, ajoutez temporairement ce code dans `main.dart`:
```dart
import 'package:shared_preferences/shared_preferences.dart';

// Dans main() avant runApp():
final prefs = await SharedPreferences.getInstance();
await prefs.clear();
print('✅ Cache vidé');
```

### Étape 3: Vider le Cache (Option 2 - Manuel)
1. Allez dans Paramètres d'entreprise
2. Cliquez sur "Actualiser" (icône refresh)
3. Cela force le rechargement depuis l'API

### Étape 4: Effectuer une Vente
1. Créez une nouvelle vente
2. Vérifiez les logs dans la console Flutter:
   - Cherchez: `🌐 LANGUE DU REÇU:`
   - Devrait afficher: `receiptLanguage FINAL: en`
3. Vérifiez le reçu affiché

### Étape 5: Vérifier les Traductions
Le reçu devrait afficher:
- ✅ "INVOICE" au lieu de "FACTURE"
- ✅ "Sale No" au lieu de "N° Vente"
- ✅ "Date" (reste "Date")
- ✅ "Customer" au lieu de "Client"
- ✅ "Payment Method" au lieu de "Mode paiement"
- ✅ "Item" au lieu de "Article"
- ✅ "Qty" au lieu de "Qté"
- ✅ "Unit Price" au lieu de "P.U."
- ✅ "Total" (reste "Total")
- ✅ "Subtotal" au lieu de "Sous-total"
- ✅ "Discount" au lieu de "Remise"
- ✅ "TOTAL" (reste "TOTAL")
- ✅ "Paid" au lieu de "Payé"
- ✅ "Change" au lieu de "Monnaie"
- ✅ "Balance" au lieu de "Reste"
- ✅ "Thank you for your trust!" au lieu de "Merci pour votre confiance !"

## Logs à Vérifier

### Dans la Console Flutter
Cherchez ces logs lors de la création d'une vente:

```
🔥 DÉFINITION DU PROFIL PARTAGÉ POUR IMPRESSION
📋 === PROFIL D'ENTREPRISE POUR IMPRESSION ===
📋 Nom: FOTSARA SARL
📋 Langue facture: en  <-- DOIT ÊTRE "en"
📋 ============================================

🌐 LANGUE DU REÇU:
  language param: null
  companyInfo.receiptLanguage: en  <-- DOIT ÊTRE "en"
  receiptLanguage FINAL: en  <-- DOIT ÊTRE "en"
```

## Si le Problème Persiste

### Solution 1: Forcer le Rechargement
Ajoutez ce code dans `company_settings_controller.dart` après la sauvegarde:
```dart
// Forcer le rechargement du profil
await loadCompanyProfile(forceRefresh: true);
```

### Solution 2: Vider le Cache Programmatiquement
Dans `company_settings_service.dart`, après la mise à jour:
```dart
// Vider le cache pour forcer le rechargement
await _clearCache();
```

### Solution 3: Redémarrer Complètement
1. Arrêter l'application Flutter
2. Arrêter le backend
3. Redémarrer le backend
4. Redémarrer l'application Flutter

## Vérification de la Base de Données

Pour vérifier que la langue est bien sauvegardée:
```bash
cd backend
node check-language.js
```

Devrait afficher:
```
✅ Paramètres entreprise trouvés:
  Nom: FOTSARA SARL
  Langue facture: en
```

## Fichiers Modifiés

### Backend
- `backend/src/validation/schemas.js` - Ajout validation langueFacture
- `backend/src/routes/company-settings.js` - Ajout langueFacture dans /public
- `backend/check-language.js` - Script de vérification (nouveau)

### Flutter
- `logesco_v2/lib/features/company_settings/services/company_settings_service.dart` - Mapping receiptLanguage (5 endroits)
- `logesco_v2/lib/features/company_settings/controllers/company_settings_controller.dart` - Mise à jour profil partagé
- `logesco_v2/lib/features/printing/services/printing_service.dart` - Log langue
- `logesco_v2/lib/features/printing/models/receipt_model.dart` - Log langue

## Prochaine Étape

Si après avoir vidé le cache et redémarré l'application, les factures sont toujours en français, vérifiez les logs pour identifier où la langue est perdue.
