# Backend Embarqué - Information et Mise à Jour

## Architecture du système

Ce projet utilise **deux instances du backend** :

### 1. Backend principal (développement)
- **Emplacement** : `backend/src/`
- **Usage** : Développement et tests
- **Démarrage** : Manuel via `npm start` ou `node src/server.js`
- **Port** : 8080

### 2. Backend embarqué (production)
- **Emplacement** : `%LOCALAPPDATA%\LOGESCO\backend\`
  - Sur Windows : `C:\Users\[VotreNom]\AppData\Local\LOGESCO\backend\`
- **Usage** : Utilisé par l'application Flutter en production
- **Démarrage** : Automatique au lancement de l'application Flutter
- **Port** : 8080
- **Contenu** :
  ```
  %LOCALAPPDATA%\LOGESCO\backend\
  ├── node.exe              # Node.js portable
  ├── src\
  │   ├── server.js         # Point d'entrée
  │   └── routes\
  │       ├── sales.js      # 👈 FICHIER CORRIGÉ
  │       └── ...
  ├── node_modules\         # Dépendances NPM
  ├── database\             # Base SQLite
  └── prisma\              # Schéma Prisma
  ```

## Correction "Monnaie à rendre"

### Fichier modifié
`backend/src/routes/sales.js` (lignes ~1029-1044)

### Problème
La monnaie rendue au client était enregistrée comme crédit dans son compte.

### Solution appliquée
Le backend distingue maintenant :
- **Monnaie à rendre** : montant versé > montant TTC → ne crée PAS de crédit
- **Dette client** : montant versé < montant TTC → enregistre la dette

## Application de la correction

### Option 1 : Script automatique (RECOMMANDÉ)
```batch
APPLIQUER-CORRECTION-MONNAIE-COMPLET.bat
```

Ce script :
1. ✅ Vérifie le backend principal
2. ✅ Copie la correction vers le backend embarqué
3. ✅ Copie la correction vers dist-exe (si existe)
4. ✅ Redémarre les processus Node.js

### Option 2 : Copie manuelle
```batch
# Arrêter l'application Flutter et tous les processus Node.js
taskkill /F /IM node.exe

# Copier le fichier corrigé
copy backend\src\routes\sales.js "%LOCALAPPDATA%\LOGESCO\backend\src\routes\sales.js"

# Redémarrer l'application Flutter
```

### Option 3 : Rebuild complet (lors du prochain déploiement)
Lors du prochain build de l'application :
```batch
# Build de la version embarquée
build-portable-backend.bat

# Ou build complet
build-both-versions.bat
```

La correction sera automatiquement incluse dans le nouveau package.

## Vérification de la correction

### 1. Vérifier que le fichier est à jour
```batch
type "%LOCALAPPDATA%\LOGESCO\backend\src\routes\sales.js" | findstr "Monnaie à rendre"
```

Si la correction est appliquée, vous devriez voir :
```javascript
// C'est de la MONNAIE À RENDRE, pas un crédit client
console.log(`💵 Monnaie à rendre au client: ...`);
```

### 2. Tester dans l'application
1. Créer une vente
2. Montant TTC : 17888 FCFA
3. Montant versé : 20000 FCFA
4. Vérifier :
   - ✅ Interface affiche "Monnaie à rendre: 2113 FCFA"
   - ✅ Compte client reste à 0 FCFA (pas de crédit)

### 3. Vérifier les logs backend
Dans la console Node.js, chercher :
```
💵 Monnaie à rendre au client: 2113 FCFA
```

## Emplacement de sauvegarde

Avant d'appliquer la correction, une sauvegarde est créée :
```
%LOCALAPPDATA%\LOGESCO\backend\src\routes\sales.js.backup
```

Pour restaurer la version précédente (si nécessaire) :
```batch
copy "%LOCALAPPDATA%\LOGESCO\backend\src\routes\sales.js.backup" "%LOCALAPPDATA%\LOGESCO\backend\src\routes\sales.js"
```

## État actuel

- ✅ **Backend principal** : Correction appliquée dans `backend/src/routes/sales.js`
- ⚠️ **Backend embarqué** : À mettre à jour manuellement ou via le script
- ℹ️ **dist-exe** : À mettre à jour si package déjà créé

## Notes importantes

1. **Cohérence** : Les deux backends doivent avoir la même version du code
2. **Base de données** : La correction ne modifie pas les données existantes, seulement les nouvelles ventes
3. **Déploiement** : Lors du prochain déploiement chez les clients, utiliser le script de build pour inclure automatiquement la correction

## Support

Pour plus d'informations, voir :
- `CORRECTION_MONNAIE_A_RENDRE.md` - Documentation de la correction
- `REDEMARRER-BACKEND-CORRECTION-MONNAIE.bat` - Redémarrage backend principal
- `APPLIQUER-CORRECTION-MONNAIE-COMPLET.bat` - Application sur tous les backends
