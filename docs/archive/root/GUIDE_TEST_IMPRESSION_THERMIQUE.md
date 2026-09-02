# 🧪 Guide de Test - Impression Thermique

## ✅ Modifications effectuées

Tous les fichiers ont été mis à jour pour afficher **"TAX INVOICE"** au lieu de "REÇU DE VENTE" :

### Fichiers Flutter modifiés :
1. ✅ `logesco_v2/lib/features/printing/widgets/receipt_template_thermal.dart`
2. ✅ `logesco_v2/lib/features/printing/widgets/receipt_template_base.dart`
3. ✅ `logesco_v2/lib/features/printing/views/receipt_preview_page.dart`
4. ✅ `logesco_v2/lib/features/printing/services/receipt_generation_service.dart`

### Fichiers Backend modifiés :
5. ✅ `backend/src/routes/printing.js`
6. ✅ `release/LOGESCO-Client/backend/src/routes/printing.js`

## 📋 Procédure de test

### Étape 1 : Redémarrer le backend
```bash
# Arrêter le backend actuel
# Puis redémarrer
cd backend
npm start
```

### Étape 2 : Redémarrer l'application Flutter
```bash
cd logesco_v2
flutter run
```

### Étape 3 : Tester l'aperçu
1. Créer ou sélectionner une vente
2. Cliquer sur "Imprimer le reçu"
3. Sélectionner le format "Thermique (80mm)"
4. **Vérifier que l'aperçu affiche "TAX INVOICE"**

### Étape 4 : Tester l'impression réelle
1. Connecter votre imprimante thermique
2. Depuis l'aperçu, cliquer sur "Imprimer"
3. **Vérifier que le ticket imprimé affiche "TAX INVOICE"**

### Étape 5 : Comparer aperçu vs impression
Vérifier que les éléments suivants sont identiques :

| Élément | Aperçu | Impression |
|---------|--------|------------|
| Titre | TAX INVOICE | TAX INVOICE |
| Séparateurs | 32 "=" | 32 "=" |
| Format infos | N° Vente:XXX | N° Vente:XXX |
| Format totaux | TOTAL: XXX FCFA | TOTAL: XXX FCFA |
| Troncature produits | 22 caractères | 22 caractères |
| Troncature clients | 15 caractères | 15 caractères |

## 🔍 Points de vérification

### ✅ Aperçu Flutter doit afficher :
```
================================
TAX INVOICE
================================
N° Vente:V-2025-001
Date:05/12/2025
Heure:16:30
Client:John Doe
Paiement:Espèces
================================
ARTICLES:
1. Produit exemple
   2 x 1000 FCFA = 2000 FCFA
--------------------------------
Sous-total: 2000 FCFA
TOTAL: 2000 FCFA
Paye: 2000 FCFA
================================
Merci pour votre confiance !
Thanks for choosing Matio Aquarium,
see you soon!
```

### ✅ Impression thermique doit afficher :
**Exactement le même contenu que l'aperçu**

## ❌ Si les différences persistent

### Problème possible 1 : Cache Flutter
```bash
cd logesco_v2
flutter clean
flutter pub get
flutter run
```

### Problème possible 2 : Backend non redémarré
```bash
# Arrêter complètement le backend
# Puis redémarrer
cd backend
npm start
```

### Problème possible 3 : Plugin d'impression
Si vous utilisez un plugin d'impression spécifique (comme `esc_pos_printer`, `blue_thermal_printer`, etc.), vérifiez que :
- Le plugin utilise bien les données de `receipt_generation_service.dart`
- Il n'y a pas de template hardcodé dans le plugin

### Problème possible 4 : Plusieurs sources de génération
Vérifiez s'il existe d'autres fichiers qui génèrent des tickets :
```bash
# Rechercher dans tout le projet
grep -r "REÇU DE VENTE" .
grep -r "RECU DE VENTE" .
```

## 🔧 Debugging

### Activer les logs d'impression
Dans `receipt_generation_service.dart`, ajoutez des logs :
```dart
String _generateThermalPrintData(Receipt receipt, ...) {
  final buffer = StringBuffer();
  
  print('🖨️ Génération ticket thermique...');
  buffer.writeln('\x1B\x40');
  buffer.writeln('\x1B\x61\x01');
  buffer.writeln('\x1B\x21\x10');
  buffer.writeln('TAX INVOICE');
  print('📄 Titre ajouté: TAX INVOICE');
  
  // ... reste du code
  
  final result = buffer.toString();
  print('📋 Contenu généré (${result.length} caractères)');
  print('📝 Aperçu: ${result.substring(0, 100)}...');
  
  return result;
}
```

### Vérifier le contenu envoyé à l'imprimante
Si vous utilisez un plugin d'impression, ajoutez un log avant l'envoi :
```dart
// Avant d'envoyer à l'imprimante
print('🖨️ Envoi à l\'imprimante:');
print(thermalData);
```

## 📱 Test avec différents formats

Testez aussi les autres formats pour vérifier la cohérence :

### Format A4
- Aperçu : Doit afficher "TAX INVOICE"
- PDF généré : Doit afficher "TAX INVOICE"

### Format A5
- Aperçu : Doit afficher "TAX INVOICE"
- PDF généré : Doit afficher "TAX INVOICE"

## 🎯 Résultat attendu

Après ces modifications, **l'aperçu et l'impression doivent être identiques à 100%**.

Si ce n'est pas le cas, il existe probablement :
1. Un autre fichier qui génère les tickets
2. Un cache qui n'a pas été vidé
3. Un plugin d'impression qui a son propre template

---
**Date :** 5 décembre 2025
**Version :** Logesco V2
**Statut :** ✅ Tous les fichiers modifiés
