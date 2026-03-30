# Guide de Configuration du Serveur LOGESCO

## Problème
Après l'installation du client LOGESCO, l'application ne se connecte pas au serveur même si l'API fonctionne via le navigateur.

## Cause
L'adresse du serveur est compilée en dur dans l'application. Si vous changez l'IP du serveur après la compilation, l'app ne le saura pas.

## Solution

### Méthode 1: Utiliser le script de configuration (RECOMMANDÉ)

#### Sur Windows (Batch)
1. Ouvrez `configure-server.bat`
2. Entrez l'adresse IP du serveur (ex: `192.168.100.101`)
3. Entrez le port (par défaut: `8080`)
4. Le script crée automatiquement le fichier de configuration
5. Redémarrez l'application LOGESCO

#### Sur Windows (PowerShell)
1. Ouvrez PowerShell en tant qu'administrateur
2. Exécutez: `.\configure-server.ps1`
3. Entrez l'adresse IP et le port
4. Redémarrez l'application LOGESCO

### Méthode 2: Configuration manuelle

1. Ouvrez l'Explorateur de fichiers
2. Allez dans: `C:\Users\[VotreNom]\Documents`
3. Créez un fichier texte nommé `server_config.txt`
4. Écrivez dedans: `http://192.168.100.101:8080/api/v1`
   - Remplacez `192.168.100.101` par l'IP réelle de votre serveur
   - Remplacez `8080` par le port réel si différent
5. Sauvegardez le fichier
6. Redémarrez l'application LOGESCO

### Méthode 3: Configuration dans l'application

1. Lancez l'application LOGESCO
2. Allez dans les paramètres (Settings)
3. Cherchez "Configuration du serveur"
4. Entrez l'adresse du serveur
5. Cliquez sur "Sauvegarder"

## Vérification

Pour vérifier que la configuration est correcte:

1. Lancez l'application
2. Essayez de vous connecter
3. Si ça fonctionne, c'est bon!
4. Si ça ne fonctionne pas, vérifiez:
   - L'adresse IP du serveur est correcte
   - Le port est correct (généralement 8080)
   - Le serveur est en cours d'exécution
   - Le firewall n'est pas bloquant

## Format de l'URL

L'URL doit être au format:
```
http://[IP_OU_HOSTNAME]:[PORT]/api/v1
```

### Exemples valides:
- `http://192.168.100.101:8080/api/v1`
- `http://192.168.1.50:8080/api/v1`
- `http://serveur.local:8080/api/v1`
- `http://logesco-server:8080/api/v1`

### Exemples invalides:
- `192.168.100.101:8080/api/v1` (manque `http://`)
- `http://192.168.100.101` (manque le port et `/api/v1`)
- `http://192.168.100.101:8080` (manque `/api/v1`)

## Dépannage

### L'app ne se connecte toujours pas
1. Vérifiez que le serveur est en cours d'exécution
2. Testez l'URL dans un navigateur: `http://192.168.100.101:8080/api/v1/auth/test`
3. Vérifiez que le firewall n'est pas bloquant
4. Vérifiez que l'adresse IP est correcte (utilisez `ipconfig` sur le serveur)

### Le fichier de configuration n'est pas créé
1. Vérifiez que vous avez les permissions d'écriture dans le dossier Documents
2. Essayez de créer le fichier manuellement
3. Redémarrez l'application

### L'app utilise toujours l'ancienne adresse
1. Supprimez le fichier `server_config.txt` du dossier Documents
2. Redémarrez l'application
3. Recréez le fichier de configuration

## Support

Si vous avez des problèmes, contactez le support technique avec:
- L'adresse IP du serveur
- Le port utilisé
- Le message d'erreur exact
- Le résultat du test dans le navigateur
