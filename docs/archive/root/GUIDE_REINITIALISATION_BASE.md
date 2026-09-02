# Guide - Réinitialisation de la Base de Données

## Vue d'ensemble

Ce guide explique comment utiliser les scripts de réinitialisation de la base de données LOGESCO pour repartir avec une base vierge.

## Scripts Disponibles

### 1. `reinitialiser-base-donnees.bat` (Version Développement)

**Emplacement** : Racine du projet  
**Usage** : Pour les développeurs pendant le développement

### 2. `REINITIALISER-BASE-DONNEES.bat` (Version Client)

**Emplacement** : Package client (release\LOGESCO-Client-Optimise\)  
**Usage** : Pour les clients en production

## ⚠️ ATTENTION - Opération Critique

### Ce que fait le script

Le script de réinitialisation va :

1. ✅ **Sauvegarder** automatiquement l'ancienne base de données
2. ❌ **Supprimer** TOUTES les données actuelles :
   - Tous les produits
   - Toutes les ventes
   - Tous les clients
   - Tous les fournisseurs
   - Toutes les transactions
   - Tous les mouvements de stock
   - Tous les utilisateurs personnalisés
   - Toutes les sessions de caisse
   - Tout l'historique

3. ✅ **Créer** une nouvelle base vierge avec uniquement :
   - 1 utilisateur admin (admin/admin123)
   - 1 caisse principale (solde 0)
   - Paramètres entreprise par défaut

### Quand utiliser ce script

✅ **Utilisez ce script si** :
- Des données de test sont présentes après l'installation
- Vous voulez repartir de zéro
- La base de données est corrompue
- Vous voulez faire des tests sans affecter les vraies données

❌ **N'utilisez PAS ce script si** :
- Vous avez des données de production importantes
- Vous n'avez pas de sauvegarde externe
- Vous n'êtes pas sûr de vouloir tout supprimer

## Utilisation

### Étape 1 : Préparation

1. **Arrêtez LOGESCO** complètement
2. **Sauvegardez manuellement** (optionnel mais recommandé) :
   ```
   Copiez le fichier: backend\database\logesco.db
   Vers un emplacement sûr (clé USB, cloud, etc.)
   ```

### Étape 2 : Exécution

#### Version Développement

```batch
# Depuis la racine du projet
reinitialiser-base-donnees.bat
```

#### Version Client

```batch
# Depuis le dossier LOGESCO-Client-Optimise
REINITIALISER-BASE-DONNEES.bat
```

### Étape 3 : Confirmations

Le script demande **DEUX confirmations** pour éviter les suppressions accidentelles :

#### Confirmation 1
```
Tapez OUI (en majuscules) pour confirmer:
```
Réponse attendue : `OUI`

#### Confirmation 2 (Version Client uniquement)
```
Tapez exactement: REINITIALISER
```
Réponse attendue : `REINITIALISER`

### Étape 4 : Processus

Le script exécute automatiquement :

```
[1/7] Vérification prérequis (Node.js)
[2/7] Vérification emplacement
[3/7] Arrêt de LOGESCO
[4/7] Sauvegarde ancienne base
[5/7] Suppression ancienne base
[6/7] Création nouvelle base VIERGE
[7/7] Vérification nouvelle base
```

### Étape 5 : Après la réinitialisation

1. **Démarrez LOGESCO**
   ```batch
   DEMARRER-LOGESCO.bat
   ```

2. **Connectez-vous**
   - Utilisateur : `admin`
   - Mot de passe : `admin123`

3. **Personnalisez immédiatement** :
   - Paramètres > Entreprise (nom, adresse, téléphone, etc.)
   - Paramètres > Utilisateurs > Changer mot de passe admin
   - Créez vos utilisateurs
   - Ajoutez vos produits

## Sauvegarde Automatique

### Emplacement

Le script crée automatiquement une sauvegarde dans :
```
backend\database\backups\logesco_backup_YYYYMMDD_HHMMSS.db
```

Exemple :
```
backend\database\backups\logesco_backup_20260302_143025.db
```

### Format du nom

- `YYYYMMDD` : Date (Année, Mois, Jour)
- `HHMMSS` : Heure (Heure, Minute, Seconde)

### Restauration depuis la sauvegarde

Si vous voulez restaurer l'ancienne base :

1. Arrêtez LOGESCO
2. Allez dans `backend\database\backups\`
3. Copiez le fichier de sauvegarde souhaité
4. Collez-le dans `backend\database\`
5. Renommez-le en `logesco.db`
6. Redémarrez LOGESCO

## Vérification

### Vérification Automatique

Le script vérifie automatiquement que la nouvelle base est vierge :

```
✅ BASE VIERGE CONFIRMEE - TOUT EST OK
   Utilisateurs: 1
   Produits: 0
   Ventes: 0
   Clients: 0
   Fournisseurs: 0
   Caisses: 1
   Entreprise: Mon Entreprise
```

### Vérification Manuelle

Vous pouvez aussi utiliser le script de vérification :

```batch
verifier-base-vierge.bat
```

## Résolution de Problèmes

### Erreur : Module @prisma/client non trouvé

**Problème** : `Error: Cannot find module '@prisma/client'`

**Cause** : Cette erreur a été corrigée dans la dernière version des scripts. Si vous l'obtenez encore :

**Solution** :
1. Assurez-vous d'utiliser les scripts corrigés (Mars 2026)
2. Vérifiez que `backend\node_modules\@prisma\client` existe
3. Si absent, installez les dépendances :
   ```batch
   cd backend
   npm install
   npx prisma generate
   cd ..
   ```
4. Réexécutez le script

**Note** : Les scripts créent maintenant le fichier temporaire dans `backend\` où se trouve `node_modules\`.

### Erreur : Node.js non installé

**Problème** : `❌ ERREUR: Node.js n'est pas installe!`

**Solution** :
1. Installez Node.js depuis https://nodejs.org/
2. Version recommandée : 18 LTS ou supérieure
3. Redémarrez le terminal
4. Réexécutez le script

### Erreur : Dossier backend non trouvé

**Problème** : `❌ ERREUR: Dossier backend\database non trouve!`

**Solution** :
1. Assurez-vous d'être dans le bon dossier
2. Le script doit être exécuté depuis :
   - La racine de LOGESCO, OU
   - Le dossier backend de LOGESCO

### Erreur : Sauvegarde échouée

**Problème** : `⚠️ ATTENTION: Sauvegarde echouee!`

**Options** :
1. Créez une sauvegarde manuelle avant de continuer
2. Tapez `OUI` pour continuer sans sauvegarde (risqué)
3. Tapez `NON` pour annuler

### Erreur : Prisma Client non trouvé

**Problème** : `⚠️ Prisma Client non trouve`

**Solution** : Le script génère automatiquement Prisma Client. Si ça échoue :
```batch
cd backend
npm install
npx prisma generate
cd ..
```

### Erreur : Création structure échouée

**Problème** : `❌ ERREUR: Creation structure echouee`

**Solution** :
1. Vérifiez que le fichier `backend\prisma\schema.prisma` existe
2. Vérifiez les permissions du dossier `backend\database\`
3. Réexécutez le script

### Erreur : Initialisation données échouée

**Problème** : `❌ ERREUR: Initialisation donnees echouee`

**Solution** :
1. Vérifiez que le fichier `backend\prisma\seed.js` existe
2. Vérifiez les logs affichés pour plus de détails
3. Réexécutez le script

## Sécurité

### ⚠️ Actions Critiques Après Réinitialisation

1. **Changez le mot de passe admin immédiatement**
   - Le mot de passe par défaut `admin123` est connu
   - Allez dans Paramètres > Utilisateurs
   - Modifiez le mot de passe admin

2. **Personnalisez les informations entreprise**
   - Allez dans Paramètres > Entreprise
   - Remplissez toutes les informations

3. **Créez des utilisateurs avec rôles appropriés**
   - Ne donnez pas les droits admin à tout le monde
   - Créez des rôles spécifiques (vendeur, gestionnaire, etc.)

## Cas d'Usage

### Cas 1 : Données de test présentes après installation

**Situation** : Le package client contient des données de test

**Solution** :
```batch
1. REINITIALISER-BASE-DONNEES.bat
2. Confirmer avec REINITIALISER puis OUI
3. Attendre la fin du processus
4. Démarrer LOGESCO
5. Personnaliser
```

### Cas 2 : Vouloir repartir de zéro

**Situation** : Vous avez fait des tests et voulez recommencer

**Solution** :
```batch
1. Sauvegarder manuellement si nécessaire
2. REINITIALISER-BASE-DONNEES.bat
3. Confirmer
4. Redémarrer proprement
```

### Cas 3 : Base de données corrompue

**Situation** : Erreurs lors de l'utilisation de LOGESCO

**Solution** :
```batch
1. Essayer de sauvegarder manuellement
2. REINITIALISER-BASE-DONNEES.bat
3. Restaurer les données depuis une sauvegarde externe si disponible
```

### Cas 4 : Migration vers nouvelle version

**Situation** : Nouvelle version de LOGESCO avec changements de structure

**Solution** :
```batch
1. Exporter les données importantes (Excel, CSV)
2. REINITIALISER-BASE-DONNEES.bat
3. Réimporter les données
```

## Checklist Post-Réinitialisation

Après avoir réinitialisé la base, suivez cette checklist :

- [ ] LOGESCO démarre sans erreur
- [ ] Connexion avec admin/admin123 fonctionne
- [ ] Dashboard s'affiche (vide)
- [ ] Paramètres entreprise personnalisés
- [ ] Mot de passe admin changé
- [ ] Utilisateurs créés avec rôles appropriés
- [ ] Caisse principale configurée
- [ ] Premiers produits ajoutés
- [ ] Test de vente effectué
- [ ] Impression reçu testée

## Support

### Logs

En cas de problème, consultez les logs :
- Logs backend : `backend\logs\`
- Sortie du script : Visible dans la console

### Contact

Si vous rencontrez des problèmes persistants :
1. Notez le message d'erreur exact
2. Vérifiez les logs
3. Contactez le support avec :
   - Message d'erreur
   - Étape où ça bloque
   - Version de Node.js (`node --version`)
   - Version de LOGESCO

## Fichiers Créés/Modifiés

### Scripts

1. `reinitialiser-base-donnees.bat` - Version développement
2. `REINITIALISER-BASE-DONNEES.bat` - Version client (dans le package)

### Documentation

3. `GUIDE_REINITIALISATION_BASE.md` - Ce guide

### Modifications

4. `preparer-pour-client-optimise.bat` - Inclut maintenant le script de réinitialisation dans le package

## Notes Importantes

- ⚠️ La réinitialisation est **IRREVERSIBLE** (sauf restauration depuis sauvegarde)
- ✅ Une sauvegarde automatique est **TOUJOURS** créée
- 🔒 Changez le mot de passe admin **IMMEDIATEMENT** après réinitialisation
- 💾 Gardez des sauvegardes externes régulières
- 🧪 Testez sur une copie avant de réinitialiser en production

---

**Version** : 2.0 OPTIMISÉE  
**Date** : Mars 2026  
**Statut** : ✅ Scripts de réinitialisation disponibles
