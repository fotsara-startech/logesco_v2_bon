# 🔧 Correction des chemins de logo dans les relevés de compte

## 🎯 Problème identifié

Le logo n'apparaissait pas dans les relevés de compte (clients et fournisseurs) parce que:

1. **Base de données stockait le chemin complet Windows:**
   ```
   C:\Users\DIGITAL MARKET\Downloads\Picture11.png
   ```

2. **Backend essayait de servir:**
   ```
   GET /uploads/C:/Users/DIGITAL%20MARKET/Downloads/Picture11.png
   ```
   → Erreur 404 car le fichier n'existe pas à ce chemin

3. **Le logo réel est stocké dans:**
   ```
   backend/uploads/Picture11.png
   ```

## ✅ Solutions appliquées

### 1. Backend - Nettoyage automatique des chemins (`backend/src/models/company-settings.js`)

Modification de la méthode `upsertSettings()` pour extraire juste le nom du fichier:

```javascript
// Nettoyer le chemin du logo: extraire juste le nom du fichier
let logoPath = data.logo || null;
if (logoPath && logoPath.trim().length > 0) {
  // Extraire juste le nom du fichier du chemin complet
  const fileName = logoPath.split(/[\\\/]/).pop();
  logoPath = fileName || logoPath;
}
```

**Résultat:** Les nouveaux uploads stockeront juste le nom du fichier (ex: `Picture11.png`)

### 2. Backend - Endpoints statement corrigés

**Clients** (`backend/src/routes/customers.js` ligne 548):
```javascript
logoPath: entreprise.logo || null  // ✅ Utilise le bon champ
```

**Fournisseurs** (`backend/src/routes/accounts.js` ligne 1117):
```javascript
logoPath: entreprise.logo || null  // ✅ Utilise le bon champ
```

### 3. Frontend - Nettoyage des chemins reçus

**Clients** (`logesco_v2/lib/features/customers/services/statement_pdf_service.dart`):
```dart
// Nettoyer le chemin: extraire juste le nom du fichier au cas où
if (logoPath.contains('\\') || logoPath.contains('/')) {
  final parts = logoPath.replaceAll('\\', '/').split('/');
  logoPath = parts.last;
}
```

**Fournisseurs** (`logesco_v2/lib/features/suppliers/services/supplier_statement_pdf_service.dart`):
- Même logique appliquée

### 4. Script de migration pour les données existantes

**Fichier:** `backend/fix-logo-paths.js`

Ce script nettoie les chemins de logo existants dans la base de données:

```bash
cd backend
node fix-logo-paths.js
```

**Résultat:** Tous les chemins complets seront convertis en juste le nom du fichier

## 📋 Étapes à suivre

1. **Exécuter le script de migration:**
   ```bash
   cd backend
   node fix-logo-paths.js
   ```

2. **Redémarrer le backend** pour charger les modifications

3. **Tester la génération d'un relevé de compte:**
   - Le logo devrait maintenant s'afficher correctement dans le PDF

## 🔍 Vérification

Après les corrections, le flux devrait être:

1. ✅ Base de données: `Picture11.png` (juste le nom)
2. ✅ Backend envoie: `logoPath: "Picture11.png"`
3. ✅ Frontend construit: `http://localhost:8080/uploads/Picture11.png`
4. ✅ Backend sert le fichier depuis: `backend/uploads/Picture11.png`
5. ✅ Logo s'affiche dans le PDF

## 📝 Notes

- Le nettoyage des chemins se fait automatiquement pour les nouveaux uploads
- Le script de migration nettoie les données existantes
- Le frontend a une double protection: il nettoie aussi les chemins au cas où
