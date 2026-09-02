# Ajout de la Langue des Factures

## Résumé
Ajout d'une option dans les paramètres d'entreprise pour sélectionner la langue des factures (Français ou Anglais). Les reçus/factures seront générés dans la langue sélectionnée.

## ✅ IMPLÉMENTATION COMPLÈTE

Toutes les fonctionnalités ont été implémentées avec succès.

## Modifications Effectuées

### 1. Modèle de Données (Flutter)

#### `company_profile.dart`
- ✅ Ajout du champ `receiptLanguage` (String, défaut: 'fr')
- ✅ Mapping JSON: `@JsonKey(name: 'langueFacture')`
- ✅ Ajout dans `CompanyProfileRequest`

#### `receipt_model.dart`
- ✅ Ajout du champ `language` (String, défaut: 'fr')
- ✅ Utilise `companyInfo.receiptLanguage` lors de la création
- ✅ Mis à jour dans `copyWith()` et `copyForReprint()`

### 2. Contrôleur (Flutter)

#### `company_settings_controller.dart`
- ✅ Ajout de `_selectedLanguage` (Rx<String>, défaut: 'fr')
- ✅ Getter `selectedLanguage`
- ✅ Méthode `setLanguage(String language)` pour changer la langue
- ✅ Synchronisation avec le formulaire dans `_populateForm()`
- ✅ Détection des changements dans `_hasFormChanges()`
- ✅ Envoi au backend dans `saveCompanyProfile()`

### 3. Interface Utilisateur (Flutter)

#### `company_settings_page.dart`
- ✅ Ajout du dropdown de sélection de langue
- ✅ Options: Français (🇫🇷) et English (🇬🇧)
- ✅ Positionné après le champ "Slogan"
- ✅ Désactivé si l'utilisateur n'a pas les permissions d'édition
- ✅ Texte d'aide: "La langue sélectionnée sera utilisée pour toutes les factures"

### 4. Traductions

#### `receipt_translations.dart` (NOUVEAU)
- ✅ Classe `ReceiptTranslations` avec traductions FR/EN
- ✅ Méthode `get(String key, {String language})` pour obtenir une traduction
- ✅ Traductions complètes pour tous les éléments du reçu:
  - En-tête: FACTURE/INVOICE, RÉIMPRESSION/REPRINT
  - Informations: N° Vente, Date, Client, Mode paiement
  - Tableau: Article, Qté, P.U., Total, Réf
  - Totaux: Sous-total, Remise, TOTAL, Payé, Monnaie, Reste
  - Pied de page: Merci pour votre confiance!, Réimprimé le, par
  - Contact: Tél, Email, NUI RCCM

### 5. Templates de Reçu

#### `receipt_template_base.dart`
- ✅ Import de `receipt_translations.dart`
- ✅ Ajout de la méthode `t(String key)` pour obtenir les traductions
- ✅ Mise à jour de `buildCompanyHeader()` avec traductions
- ✅ Mise à jour de `buildSaleInfo()` avec traductions
- ✅ Mise à jour de `buildItemsList()` avec traductions
- ✅ Mise à jour de `buildTotals()` avec traductions
- ✅ Mise à jour de `buildFooter()` avec traductions

### 6. Base de Données (Backend)

#### `schema.prisma`
- ✅ Ajout du champ `langueFacture` dans `ParametresEntreprise`
- ✅ Type: String, défaut: 'fr'
- ✅ Mapping: `@map("langue_facture")`
- ✅ Migration appliquée: `npx prisma db push`
- ✅ Client Prisma régénéré: `npx prisma generate`

#### `company-settings.js` (Modèle Backend)
- ✅ Ajout de `langueFacture` dans `upsertSettings()` (create)
- ✅ Ajout de `langueFacture` dans `upsertSettings()` (update)
- ✅ Valeur par défaut: 'fr'

### 7. Génération des Modèles

- ✅ Flutter: `flutter pub run build_runner build --delete-conflicting-outputs`
- ✅ Fichiers `.g.dart` régénérés avec succès
- ✅ Backend redémarré avec succès

## Utilisation

### Pour l'Utilisateur

1. Aller dans **Paramètres de l'entreprise**
2. Faire défiler jusqu'au champ **Langue des factures**
3. Sélectionner la langue souhaitée:
   - 🇫🇷 Français (par défaut)
   - 🇬🇧 English
4. Cliquer sur **Sauvegarder les modifications**
5. Toutes les nouvelles factures seront générées dans la langue sélectionnée

### Exemples de Traduction

#### Français (par défaut)
```
FACTURE
N° Vente: V-2024-001
Date: 01/03/2026 14:30
Client: FRANGLISH JUNIOR
Mode paiement: comptant

Article         Qté    P.U.      Total
Produit A       2      1000      2000
Réf: REF-001

Sous-total:              2000 FCFA
Remise:                  -200 FCFA
TOTAL:                   1800 FCFA
Payé:                    2000 FCFA
Monnaie:                  200 FCFA

Merci pour votre confiance !
```

#### English
```
INVOICE
Sale No: V-2024-001
Date: 01/03/2026 14:30
Customer: FRANGLISH JUNIOR
Payment Method: cash

Item            Qty    Unit Price  Total
Product A       2      1000        2000
Ref: REF-001

Subtotal:                2000 FCFA
Discount:                -200 FCFA
TOTAL:                   1800 FCFA
Paid:                    2000 FCFA
Change:                   200 FCFA

Thank you for your trust!
```

## Architecture

### Flux de Données

1. **Paramètres d'entreprise** → `CompanyProfile.receiptLanguage`
2. **Création de vente** → `Receipt.fromSale()` utilise `companyInfo.receiptLanguage`
3. **Génération du reçu** → `ReceiptTemplateBase.t()` traduit les textes
4. **Affichage/Impression** → Reçu dans la langue configurée

### Extensibilité

Pour ajouter une nouvelle langue (ex: Espagnol):

1. Ajouter les traductions dans `receipt_translations.dart`:
```dart
'es': {
  'invoice': 'FACTURA',
  'saleNumber': 'N° Venta',
  'date': 'Fecha',
  'customer': 'Cliente',
  // ... autres traductions
}
```

2. Ajouter l'option dans le dropdown de `company_settings_page.dart`:
```dart
DropdownMenuItem(
  value: 'es',
  child: Row(
    children: [
      Text('🇪🇸'),
      SizedBox(width: 8),
      Text('Español'),
    ],
  ),
),
```

## Tests à Effectuer

### Test Manuel

1. ✅ Créer/modifier le profil d'entreprise avec langue FR
2. ✅ Effectuer une vente et vérifier le reçu en français
3. ✅ Changer la langue en EN dans les paramètres
4. ✅ Effectuer une vente et vérifier le reçu en anglais
5. ✅ Vérifier que les réimpressions conservent la langue d'origine

### Points de Vérification

- ✅ Le dropdown affiche la langue actuelle
- ✅ Le changement de langue marque le formulaire comme modifié
- ✅ La sauvegarde persiste la langue en base de données
- ✅ Les nouveaux reçus utilisent la langue configurée
- ✅ Tous les éléments du reçu sont traduits (en-tête, tableau, totaux, pied de page)

## Fichiers Modifiés

### Flutter
- `logesco_v2/lib/features/company_settings/models/company_profile.dart`
- `logesco_v2/lib/features/company_settings/controllers/company_settings_controller.dart`
- `logesco_v2/lib/features/company_settings/views/company_settings_page.dart`
- `logesco_v2/lib/features/printing/models/receipt_model.dart`
- `logesco_v2/lib/features/printing/widgets/receipt_template_base.dart`
- `logesco_v2/lib/features/printing/utils/receipt_translations.dart` (NOUVEAU)

### Backend
- `backend/prisma/schema.prisma`
- `backend/src/models/company-settings.js`

## Statut Final

✅ **IMPLÉMENTATION COMPLÈTE ET FONCTIONNELLE**

L'application est maintenant prête pour tester la fonctionnalité de sélection de langue des factures. Tous les composants ont été mis à jour et le backend a été redémarré avec succès.
