# LOGESCO - Instructions de correction des migrations

## Problème
Après une mise à jour de LOGESCO, certaines fonctionnalités ne marchent pas correctement à cause de migrations de base de données manquantes.

## ✅ Solution automatique (recommandée)

**À partir de cette version, les migrations s'appliquent automatiquement au démarrage !**

Si vous avez toujours des problèmes après le redémarrage, suivez les instructions ci-dessous.

## Solution manuelle (si nécessaire)

### Option 1 : Script dans l'installation LOGESCO

1. Ouvrez le dossier d'installation :
   - Appuyez sur **Windows + R**
   - Tapez : `%LOCALAPPDATA%\LOGESCO\backend\scripts`
   - Appuyez sur **Entrée**

2. Double-cliquez sur `fix-migrations-client.bat`

3. Attendez le message "TERMINE AVEC SUCCES"

4. Relancez LOGESCO

### Option 2 : Script autonome (si le premier ne marche pas)

1. **Téléchargez** le fichier `fix-migrations-LOGESCO.bat` (fourni par le support)
2. **Placez-le** n'importe où (bureau, téléchargements, etc.)
3. **Double-cliquez** dessus
4. Le script cherchera automatiquement LOGESCO et appliquera les corrections
5. Relancez LOGESCO

## Vérification

Après avoir exécuté le script :

1. Relancez LOGESCO
2. Vérifiez que toutes les fonctionnalités marchent :
   - Ventes
   - Stock
   - Mouvements financiers
   - Comptes clients/fournisseurs
   - Caisse

## Prévention automatique

À partir de maintenant, les migrations sont appliquées automatiquement à chaque démarrage du backend, donc ce problème ne devrait plus se reproduire.

## En cas de problème

Si le script échoue :

1. **Notez le message d'erreur** affiché
2. **Prenez une capture d'écran**
3. **Contactez le support** avec :
   - La capture d'écran
   - Le chemin d'installation de LOGESCO
   - La version de Windows

### Emplacements d'installation possibles

- `%LOCALAPPDATA%\LOGESCO\backend`
- `C:\Program Files\LOGESCO\backend`
- `D:\LOGESCO\backend`

Pour trouver le chemin exact :
1. Faites un clic droit sur le raccourci LOGESCO
2. Propriétés → Emplacement du fichier

## Informations techniques

Le script applique les migrations suivantes :
- Colonnes `date_modification` sur 14 tables
- Colonnes `stock_initial` et `stock_final` sur `mouvements_stock`
- Colonne `image_url` sur `produits`
- Création automatique des index pour optimiser les performances

**Temps d'exécution** : 5-15 secondes selon la taille de la base de données

---

**Support** : [Votre email/téléphone de support]
