# Guide de test - Logo et Slogan (Flutter)

## ✅ Backend vérifié

Le backend peut correctement sauvegarder le logo et le slogan.
Test effectué avec succès.

## 🔧 Fonctionnalités implémentées

### 1. Sélection de logo
- ✅ Bouton "Sélectionner un logo" fonctionnel
- ✅ Utilise `file_picker` pour sélectionner une image
- ✅ Validation de la taille (max 5MB)
- ✅ Affichage du nom du fichier sélectionné
- ✅ Bouton de suppression du logo

### 2. Champ slogan
- ✅ Champ texte multiligne (2 lignes)
- ✅ Optionnel
- ✅ Limite de 200 caractères (validation backend)

## 📝 Étapes de test

### Test 1: Ajouter un slogan

1. Lancer l'application Flutter
2. Se connecter en tant qu'administrateur
3. Aller dans "Paramètres de l'entreprise"
4. Remplir le champ "Slogan (optionnel)" avec:
   ```
   Votre satisfaction, notre priorité
   ```
5. Cliquer sur "Sauvegarder"

**Résultat attendu:**
- ✅ Message "Profil sauvegardé avec succès"
- ✅ Le slogan reste affiché après sauvegarde
- ✅ Pas d'erreur dans les logs

**Vérification backend:**
```bash
cd backend
node -e "const { PrismaClient } = require('@prisma/client'); const p = new PrismaClient(); p.parametresEntreprise.findFirst().then(r => { console.log('Slogan:', r.slogan); p.$disconnect(); });"
```

### Test 2: Sélectionner un logo

1. Dans "Paramètres de l'entreprise"
2. Cliquer sur "Sélectionner un logo"
3. Choisir une image (PNG, JPG, etc.)
4. Vérifier que le message "Logo sélectionné: [nom]" s'affiche
5. Vérifier que la section logo affiche "Logo sélectionné"
6. Cliquer sur "Sauvegarder"

**Résultat attendu:**
- ✅ Sélecteur de fichiers s'ouvre
- ✅ Message de confirmation après sélection
- ✅ Bouton de suppression visible
- ✅ Sauvegarde réussie

**Vérification backend:**
```bash
cd backend
node -e "const { PrismaClient } = require('@prisma/client'); const p = new PrismaClient(); p.parametresEntreprise.findFirst().then(r => { console.log('Logo:', r.logo); p.$disconnect(); });"
```

### Test 3: Supprimer le logo

1. Après avoir sélectionné un logo
2. Cliquer sur l'icône de suppression (poubelle rouge)
3. Vérifier que le logo est supprimé
4. Sauvegarder

**Résultat attendu:**
- ✅ Logo supprimé de l'interface
- ✅ Bouton "Sélectionner un logo" réapparaît
- ✅ Sauvegarde avec logo = null

### Test 4: Modifier le slogan

1. Charger un profil avec un slogan existant
2. Modifier le slogan
3. Sauvegarder

**Résultat attendu:**
- ✅ Ancien slogan chargé correctement
- ✅ Modification sauvegardée
- ✅ Nouveau slogan affiché après rechargement

### Test 5: Validation

1. Essayer de saisir un slogan de plus de 200 caractères
2. Sauvegarder

**Résultat attendu:**
- ✅ Erreur de validation du backend
- ✅ Message d'erreur approprié

## 🐛 Dépannage

### Problème: Le slogan n'est pas sauvegardé

**Vérifications:**

1. **Le modèle Flutter a-t-il été régénéré?**
   ```bash
   cd logesco_v2
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

2. **Le backend a-t-il été redémarré?**
   ```bash
   cd backend
   npm start
   ```

3. **Vérifier les logs Flutter:**
   - Chercher des erreurs de sérialisation JSON
   - Vérifier que le champ `slogan` est bien envoyé dans la requête

4. **Vérifier les logs backend:**
   - Chercher la requête PUT `/api/company-settings`
   - Vérifier que le champ `slogan` est reçu

5. **Tester directement l'API:**
   ```bash
   # PowerShell
   $token = "VOTRE_TOKEN"
   $body = @{
       nomEntreprise = "Test"
       adresse = "Test"
       slogan = "Test slogan"
   } | ConvertTo-Json
   
   Invoke-RestMethod -Uri "http://localhost:3000/api/company-settings" `
       -Method PUT `
       -Headers @{Authorization="Bearer $token"; "Content-Type"="application/json"} `
       -Body $body
   ```

### Problème: Le logo ne se sélectionne pas

**Vérifications:**

1. **Le package file_picker est-il installé?**
   ```bash
   cd logesco_v2
   flutter pub get
   ```

2. **Permissions Windows:**
   - L'application a-t-elle accès au système de fichiers?
   - Essayer de sélectionner un fichier depuis un emplacement accessible

3. **Vérifier les logs:**
   - Chercher des erreurs de permission
   - Vérifier que `FilePicker.platform.pickFiles()` est appelé

### Problème: Erreur "Logo trop volumineux"

**Solution:**
- Choisir une image de moins de 5MB
- Ou modifier la limite dans le contrôleur:
  ```dart
  if (fileSize > 5 * 1024 * 1024) { // Modifier ici
  ```

## 📊 Vérification de la base de données

### Voir tous les paramètres:
```bash
cd backend
node -e "const { PrismaClient } = require('@prisma/client'); const p = new PrismaClient(); p.parametresEntreprise.findFirst().then(r => { console.log(JSON.stringify(r, null, 2)); p.$disconnect(); });"
```

### Réinitialiser le slogan:
```bash
cd backend
node -e "const { PrismaClient } = require('@prisma/client'); const p = new PrismaClient(); p.parametresEntreprise.updateMany({ data: { slogan: null } }).then(() => { console.log('Slogan réinitialisé'); p.$disconnect(); });"
```

### Réinitialiser le logo:
```bash
cd backend
node -e "const { PrismaClient } = require('@prisma/client'); const p = new PrismaClient(); p.parametresEntreprise.updateMany({ data: { logo: null } }).then(() => { console.log('Logo réinitialisé'); p.$disconnect(); });"
```

## ✅ Checklist de validation

- [ ] Le modèle Flutter a été régénéré
- [ ] Le backend a été redémarré
- [ ] Le slogan peut être saisi
- [ ] Le slogan est sauvegardé en base
- [ ] Le slogan est rechargé après fermeture/ouverture
- [ ] Le logo peut être sélectionné
- [ ] Le logo est sauvegardé (chemin)
- [ ] Le logo peut être supprimé
- [ ] La validation fonctionne (slogan > 200 caractères)
- [ ] La validation fonctionne (logo > 5MB)
- [ ] Pas d'erreur dans les logs Flutter
- [ ] Pas d'erreur dans les logs backend

## 🎯 Prochaines étapes

Une fois les tests validés:

1. **Intégrer dans les templates de facture**
   - Voir `INTEGRATION_LOGO_SLOGAN_FACTURES.md`

2. **Ajouter une prévisualisation du logo**
   - Afficher l'image dans le formulaire

3. **Gérer l'upload du logo**
   - Créer un endpoint d'upload
   - Copier le fichier vers un dossier uploads/

4. **Optimiser les images**
   - Redimensionner automatiquement
   - Compresser pour réduire la taille

---

**Date**: 28 février 2026
**Statut**: ✅ Implémentation terminée, tests en cours
