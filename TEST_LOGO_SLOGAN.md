# Guide de test - Logo et Slogan

## Étapes de test

### 1. Appliquer la migration
```bash
apply-company-settings-migration.bat
```

Vérifier que:
- ✅ La migration SQL s'applique sans erreur
- ✅ Le client Prisma se régénère correctement

### 2. Régénérer le modèle Flutter
```bash
cd logesco_v2
flutter pub run build_runner build --delete-conflicting-outputs
```

Vérifier que:
- ✅ Le fichier `company_profile.g.dart` se régénère
- ✅ Pas d'erreurs de compilation

### 3. Redémarrer le backend
```bash
cd backend
npm start
```

Vérifier que:
- ✅ Le serveur démarre sans erreur
- ✅ Les routes `/api/company-settings` sont disponibles

### 4. Tester l'interface Flutter

#### Test 1: Ajouter un slogan
1. Lancer l'application Flutter
2. Se connecter en tant qu'administrateur
3. Aller dans "Paramètres de l'entreprise"
4. Remplir le champ "Slogan (optionnel)" avec: "Votre satisfaction, notre priorité"
5. Cliquer sur "Sauvegarder"

**Résultat attendu:**
- ✅ Message de succès "Profil sauvegardé avec succès"
- ✅ Le slogan est affiché dans le formulaire après rechargement
- ✅ Pas d'erreur dans les logs

#### Test 2: Vérifier le slogan dans la base de données
```bash
cd backend
node -e "const sqlite3 = require('better-sqlite3'); const db = sqlite3('./database/logesco.db'); const result = db.prepare('SELECT slogan FROM parametres_entreprise').get(); console.log('Slogan:', result.slogan); db.close();"
```

**Résultat attendu:**
- ✅ Le slogan s'affiche correctement

#### Test 3: Tester le bouton logo
1. Dans "Paramètres de l'entreprise"
2. Cliquer sur "Sélectionner un logo"

**Résultat attendu:**
- ✅ Message "Fonctionnalité de sélection de logo à implémenter"
- ✅ Pas d'erreur

#### Test 4: Tester l'API backend
```bash
# Test avec curl (Windows PowerShell)
$token = "VOTRE_TOKEN_JWT"
Invoke-RestMethod -Uri "http://localhost:3000/api/company-settings" -Headers @{Authorization="Bearer $token"} | ConvertTo-Json
```

**Résultat attendu:**
- ✅ La réponse contient les champs `logo` et `slogan`
- ✅ Les valeurs sont NULL ou contiennent les données saisies

#### Test 5: Tester l'endpoint public
```bash
Invoke-RestMethod -Uri "http://localhost:3000/api/company-settings/public" | ConvertTo-Json
```

**Résultat attendu:**
- ✅ La réponse contient les champs `logo` et `slogan`
- ✅ Pas besoin d'authentification

### 5. Tests de validation

#### Test 6: Slogan trop long
1. Essayer de saisir un slogan de plus de 200 caractères
2. Sauvegarder

**Résultat attendu:**
- ✅ Erreur de validation du backend
- ✅ Message d'erreur approprié

#### Test 7: Champs optionnels vides
1. Laisser le slogan vide
2. Ne pas sélectionner de logo
3. Sauvegarder

**Résultat attendu:**
- ✅ Sauvegarde réussie
- ✅ Les champs restent NULL dans la base

### 6. Tests de compatibilité

#### Test 8: Anciennes données
1. Vérifier qu'un profil d'entreprise existant fonctionne toujours
2. Charger le profil
3. Modifier un champ existant (ex: téléphone)
4. Sauvegarder

**Résultat attendu:**
- ✅ Pas d'erreur
- ✅ Les modifications sont sauvegardées
- ✅ Les champs logo et slogan restent NULL

#### Test 9: Cache
1. Ajouter un slogan
2. Sauvegarder
3. Fermer et rouvrir l'application
4. Aller dans "Paramètres de l'entreprise"

**Résultat attendu:**
- ✅ Le slogan est chargé depuis le cache
- ✅ Pas d'appel API inutile

## Checklist de validation

### Backend
- [ ] Migration SQL appliquée
- [ ] Client Prisma régénéré
- [ ] Serveur démarre sans erreur
- [ ] Endpoint GET `/api/company-settings` retourne logo et slogan
- [ ] Endpoint GET `/api/company-settings/public` retourne logo et slogan
- [ ] Endpoint PUT `/api/company-settings` accepte logo et slogan
- [ ] Validation: slogan max 200 caractères
- [ ] Validation: logo max 500 caractères

### Frontend
- [ ] Modèle `company_profile.g.dart` régénéré
- [ ] Champ slogan visible dans le formulaire
- [ ] Section logo visible dans le formulaire
- [ ] Bouton "Sélectionner un logo" fonctionne
- [ ] Sauvegarde avec slogan fonctionne
- [ ] Chargement du profil avec slogan fonctionne
- [ ] Cache fonctionne avec les nouveaux champs
- [ ] Pas d'erreur de compilation
- [ ] Pas d'erreur d'exécution

### Base de données
- [ ] Colonne `logo` ajoutée
- [ ] Colonne `slogan` ajoutée
- [ ] Les deux colonnes acceptent NULL
- [ ] Les anciennes données restent intactes

## Problèmes connus

1. **Sélection de logo non implémentée**: La fonctionnalité de sélection de fichier image n'est pas encore implémentée. Pour l'instant, seul un message d'information s'affiche.

2. **Upload de logo**: Le système d'upload du logo vers le serveur n'est pas implémenté. Le champ `logo` stocke uniquement un chemin de fichier.

3. **Intégration dans les factures**: Les templates de facture ne sont pas encore mis à jour pour afficher le logo et le slogan.

## Prochaines étapes

1. Implémenter la sélection de fichier image (package `file_picker` ou `image_picker`)
2. Implémenter l'upload du logo vers le serveur
3. Mettre à jour les templates de facture pour afficher le logo (A4/A5)
4. Mettre à jour les templates de facture pour afficher le slogan (tous formats)
5. Ajouter une prévisualisation du logo dans le formulaire
6. Gérer la suppression du fichier logo du serveur
