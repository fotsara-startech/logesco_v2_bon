# 🔧 CORRECTION - CompanyProfile Parameters

## ❌ Problème identifié
```
The named parameter 'registrationNumber' isn't defined.
The named parameter 'website' isn't defined.
```

## 🔍 Cause
Les paramètres utilisés dans `_getDefaultCompanyInfo()` ne correspondaient pas à la définition réelle de la classe `CompanyProfile`.

## ✅ Correction appliquée

### Paramètres incorrects (AVANT) :
```dart
CompanyProfile(
  id: 1,
  name: 'LOGESCO ENTERPRISE',
  address: 'Adresse non configurée',
  phone: 'Téléphone non configuré',
  email: 'email@logesco.com',
  website: 'www.logesco.com',           // ❌ N'existe pas
  logo: null,                           // ❌ N'existe pas
  taxNumber: 'N° TVA non configuré',    // ❌ N'existe pas
  registrationNumber: 'N° Registre',    // ❌ N'existe pas
  currency: 'FCFA',                     // ❌ N'existe pas
  dateFormat: 'dd/MM/yyyy',             // ❌ N'existe pas
  timeZone: 'Africa/Kinshasa',          // ❌ N'existe pas
);
```

### Paramètres corrects (APRÈS) :
```dart
CompanyProfile(
  id: 1,
  name: 'LOGESCO ENTERPRISE',
  address: 'Adresse non configurée',
  location: 'Kinshasa, RDC',           // ✅ Existe
  phone: 'Téléphone non configuré',
  email: 'email@logesco.com',
  nuiRccm: 'NUI RCCM non configuré',   // ✅ Existe
  createdAt: DateTime.now(),           // ✅ Existe
  updatedAt: DateTime.now(),           // ✅ Existe
);
```

## 📋 Paramètres disponibles dans CompanyProfile

D'après la définition de la classe :

### Paramètres requis :
- ✅ `name` (String) - Nom de l'entreprise
- ✅ `address` (String) - Adresse

### Paramètres optionnels :
- ✅ `id` (int?) - Identifiant
- ✅ `location` (String?) - Localisation
- ✅ `phone` (String?) - Téléphone
- ✅ `email` (String?) - Email
- ✅ `nuiRccm` (String?) - Numéro d'identification RCCM
- ✅ `createdAt` (DateTime?) - Date de création
- ✅ `updatedAt` (DateTime?) - Date de modification

## 🎯 Résultat
L'application devrait maintenant compiler sans erreur et utiliser les bonnes informations par défaut de l'entreprise dans le bilan comptable.

## 📱 Test à effectuer
1. Vérifier que l'application compile sans erreur
2. Générer un bilan comptable
3. Vérifier que les informations par défaut s'affichent :
   - Nom : "LOGESCO ENTERPRISE"
   - Adresse : "Adresse non configurée"
   - Localisation : "Kinshasa, RDC"
   - NUI RCCM : "NUI RCCM non configuré"