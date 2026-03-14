# 🎯 Solution complète: Upload et affichage du logo dans les relevés de compte

## 🔍 Problème identifié

Le logo n'apparaissait pas dans les relevés de compte parce que:

1. **Le fichier n'était jamais uploadé au backend**
   - Le frontend envoyait juste le chemin du fichier local
   - Le backend recevait le chemin mais pas le fichier physique
   - Résultat: `GET /uploads/logo.png` → 404 Not Found

2. **Chemin complet Windows stocké en base de données**
   - Au lieu de juste le nom du fichier

## ✅ Solutions appliquées

### 1. Backend - Endpoint POST multipart (`backend/src/routes/company-settings.js`)

Ajout d'un nouvel endpoint POST qui:
- Accepte un upload multipart avec le fichier logo
- Sauvegarde le fichier dans `backend/uploads/`
- Stocke juste le nom du fichier en base de données
- Nettoie automatiquement les chemins complets

```javascript
router.post('/',
  requireAdmin,
  logoUpload.single('logo'),  // Multer middleware
  async (req, res) => {
    // Récupère le nom du fichier uploadé
    const logoFileName = req.file ? req.file.filename : req.body.logo;
    // Sauvegarde en base de données
    const data = { ...req.body, logo: logoFileName };
    // ...
  }
);
```

### 2. Backend - Nettoyage automatique des chemins (`backend/src/models/company-settings.js`)

La méthode `upsertSettings()` extrait juste le nom du fichier:

```javascript
let logoPath = data.logo || null;
if (logoPath && logoPath.trim().length > 0) {
  const fileName = logoPath.split(/[\\\/]/).pop();
  logoPath = fileName || logoPath;
}
```

### 3. Frontend - Upload multipart (`logesco_v2/lib/features/company_settings/controllers/company_settings_controller.dart`)

Modification de `saveCompanyProfile()` pour:
- Détecter si un nouveau logo a été sélectionné (chemin local)
- Uploader le fichier en multipart via `postMultipart()`
- Envoyer les autres données du formulaire en même temps

```dart
// Vérifier si un nouveau logo a été sélectionné
final hasNewLogo = logoPath != null && 
    logoPath.isNotEmpty && 
    (logoPath.startsWith('/') || logoPath.contains('\\') || logoPath.contains(':'));

if (hasNewLogo) {
  // Upload le fichier en multipart
  await _uploadLogoAndSaveProfile(logoPath!);
} else {
  // Sauvegarde normale sans fichier
  await _saveProfileWithoutLogo();
}
```

### 4. Frontend - Nettoyage des chemins dans les PDF

Les services PDF nettoient aussi les chemins au cas où:

```dart
// Nettoyer le chemin: extraire juste le nom du fichier
if (logoPath.contains('\\') || logoPath.contains('/')) {
  final parts = logoPath.replaceAll('\\', '/').split('/');
  logoPath = parts.last;
}
```

## 📋 Flux complet

1. **Utilisateur sélectionne un logo** → `selectLogo()` stocke le chemin local
2. **Utilisateur clique "Sauvegarder"** → `saveCompanyProfile()` détecte le nouveau logo
3. **Frontend upload le fichier** → `_uploadLogoAndSaveProfile()` envoie en multipart
4. **Backend reçoit le fichier** → Endpoint POST sauvegarde dans `backend/uploads/`
5. **Backend stocke le nom** → Base de données: `logo_1234567890.png`
6. **Relevé de compte récupère le logo** → Endpoint `/customers/:id/statement` retourne le nom
7. **Frontend télécharge le logo** → `http://localhost:8080/uploads/logo_1234567890.png`
8. **Logo s'affiche dans le PDF** ✅

## 🚀 Étapes à suivre

1. **Redémarrer le backend** pour charger les modifications
2. **Tester l'upload du logo:**
   - Aller dans Paramètres entreprise
   - Sélectionner un nouveau logo
   - Cliquer "Sauvegarder"
   - Vérifier que le fichier est uploadé dans `backend/uploads/`
3. **Tester l'affichage dans les relevés:**
   - Générer un relevé de compte
   - Le logo devrait s'afficher dans le PDF

## 📝 Notes importantes

- Le fichier logo est sauvegardé dans `backend/uploads/` avec un timestamp unique
- Seules les images (JPEG, PNG, GIF, WebP) sont acceptées
- Taille maximale: 5MB
- Le chemin stocké en base de données est juste le nom du fichier (ex: `logo_1234567890.png`)
- Les données existantes avec chemins complets seront nettoyées automatiquement

## 🔧 Fichiers modifiés

- `backend/src/routes/company-settings.js` - Ajout endpoint POST multipart
- `backend/src/models/company-settings.js` - Nettoyage des chemins
- `logesco_v2/lib/features/company_settings/controllers/company_settings_controller.dart` - Upload multipart
- `logesco_v2/lib/features/customers/services/statement_pdf_service.dart` - Nettoyage des chemins
- `logesco_v2/lib/features/suppliers/services/supplier_statement_pdf_service.dart` - Nettoyage des chemins
