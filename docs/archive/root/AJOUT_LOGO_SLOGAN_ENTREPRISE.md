# Ajout des champs Logo et Slogan aux Paramètres d'Entreprise

## Résumé des modifications

Ajout de deux nouveaux champs optionnels aux paramètres d'entreprise:
- **Logo**: Permet d'ajouter un logo qui sera affiché sur les factures A4/A5
- **Slogan**: Permet d'ajouter un slogan qui sera affiché en pied de page sur tous les formats de facture

## Modifications apportées

### 1. Base de données (Prisma Schema)
**Fichier**: `backend/prisma/schema.prisma`

Ajout de deux champs optionnels au modèle `ParametresEntreprise`:
```prisma
model ParametresEntreprise {
  // ... champs existants
  logo             String?  // Chemin vers le fichier logo (optionnel)
  slogan           String?  // Slogan de l'entreprise (optionnel)
  // ...
}
```

### 2. Modèle Flutter
**Fichier**: `logesco_v2/lib/features/company_settings/models/company_profile.dart`

Ajout des champs au modèle `CompanyProfile`:
```dart
class CompanyProfile {
  // ... champs existants
  final String? logo;    // Chemin vers le fichier logo (optionnel)
  final String? slogan;  // Slogan de l'entreprise (optionnel)
  // ...
}
```

### 3. Service Flutter
**Fichier**: `logesco_v2/lib/features/company_settings/services/company_settings_service.dart`

Mise à jour de toutes les créations de `CompanyProfile` pour inclure les nouveaux champs:
- `getCompanyProfile()`
- `_getCompanyProfileFromPublicEndpoint()`
- `createCompanyProfile()`
- `updateCompanyProfile()`
- `_getCachedProfile()`

### 4. Contrôleur Flutter
**Fichier**: `logesco_v2/lib/features/company_settings/controllers/company_settings_controller.dart`

Ajout de:
- `sloganController`: TextEditingController pour le slogan
- `_logoPath`: Observable pour le chemin du logo
- `selectLogo()`: Méthode pour sélectionner un fichier logo
- `removeLogo()`: Méthode pour supprimer le logo

### 5. Vue Flutter
**Fichier**: `logesco_v2/lib/features/company_settings/views/company_settings_page.dart`

Ajout de:
- Champ de texte pour le slogan (optionnel, 2 lignes)
- Section pour le logo avec bouton de sélection/suppression
- Indication que le logo sera affiché sur les factures A4/A5

### 6. Backend - Modèle
**Fichier**: `backend/src/models/company-settings.js`

Mise à jour de `upsertSettings()` pour gérer les nouveaux champs:
```javascript
{
  // ... champs existants
  logo: data.logo || null,
  slogan: data.slogan || null
}
```

### 7. Backend - Validation
**Fichier**: `backend/src/validation/schemas.js`

Ajout de la validation pour les nouveaux champs:
```javascript
logo: Joi.string().max(500).allow('', null),    // Chemin vers le fichier logo
slogan: Joi.string().max(200).allow('', null)   // Slogan de l'entreprise
```

### 8. Backend - Routes
**Fichier**: `backend/src/routes/company-settings.js`

Mise à jour de l'endpoint public pour inclure les nouveaux champs dans la réponse.

## Migration de la base de données

### Fichier de migration SQL
**Fichier**: `backend/prisma/migrations/add_logo_slogan_to_company_settings.sql`

```sql
ALTER TABLE parametres_entreprise ADD COLUMN logo TEXT;
ALTER TABLE parametres_entreprise ADD COLUMN slogan TEXT;
```

### Script d'application
**Fichier**: `apply-company-settings-migration.bat`

Pour appliquer la migration:
```bash
apply-company-settings-migration.bat
```

## Étapes pour utiliser les nouvelles fonctionnalités

### 1. Appliquer la migration
```bash
apply-company-settings-migration.bat
```

### 2. Régénérer le modèle Flutter
```bash
cd logesco_v2
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Redémarrer le backend
```bash
cd backend
npm start
```

### 4. Utiliser dans l'application

#### Ajouter un slogan:
1. Aller dans "Paramètres de l'entreprise"
2. Remplir le champ "Slogan (optionnel)"
3. Sauvegarder

Le slogan apparaîtra en pied de page sur tous les formats de facture.

#### Ajouter un logo:
1. Aller dans "Paramètres de l'entreprise"
2. Cliquer sur "Sélectionner un logo"
3. Choisir une image
4. Sauvegarder

Le logo apparaîtra sur les factures A4/A5.

## Utilisation dans les templates de facture

### Pour le logo (A4/A5):
```dart
if (companyProfile?.logo != null) {
  // Afficher le logo
  Image.file(File(companyProfile!.logo!))
}
```

### Pour le slogan (tous formats):
```dart
if (companyProfile?.slogan != null) {
  Text(
    companyProfile!.slogan!,
    style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic),
  )
}
```

## Notes importantes

1. **Les deux champs sont optionnels**: L'application fonctionne normalement sans logo ni slogan
2. **Le logo est un chemin de fichier**: Pour l'instant, la sélection de fichier n'est pas implémentée (TODO)
3. **Limite de caractères pour le slogan**: Maximum 200 caractères
4. **Compatibilité**: Les anciennes données restent intactes, les nouveaux champs sont NULL par défaut

## TODO

- [ ] Implémenter la sélection de fichier image pour le logo
- [ ] Ajouter la gestion de l'upload du logo vers le serveur
- [ ] Intégrer le logo dans les templates de facture A4/A5
- [ ] Intégrer le slogan dans les pieds de page de tous les formats de facture
- [ ] Ajouter une prévisualisation du logo dans le formulaire
- [ ] Gérer la suppression du fichier logo du serveur

## Fichiers modifiés

### Backend
- `backend/prisma/schema.prisma`
- `backend/src/models/company-settings.js`
- `backend/src/validation/schemas.js`
- `backend/src/routes/company-settings.js`

### Frontend (Flutter)
- `logesco_v2/lib/features/company_settings/models/company_profile.dart`
- `logesco_v2/lib/features/company_settings/services/company_settings_service.dart`
- `logesco_v2/lib/features/company_settings/controllers/company_settings_controller.dart`
- `logesco_v2/lib/features/company_settings/views/company_settings_page.dart`

### Migration
- `backend/prisma/migrations/add_logo_slogan_to_company_settings.sql`
- `apply-company-settings-migration.bat`

### Documentation
- `AJOUT_LOGO_SLOGAN_ENTREPRISE.md` (ce fichier)
