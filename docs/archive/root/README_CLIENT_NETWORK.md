# LOGESCO v2 - Client Réseau (Frontend uniquement)

## Vue d'ensemble

Ce package contient tous les outils nécessaires pour compiler et déployer LOGESCO v2 en tant que client réseau sur des ordinateurs Windows connectés à un serveur centralisé.

### Caractéristiques

- **Frontend uniquement** : Pas de backend, pas de base de données locale
- **Connexion serveur requise** : L'application se connecte à un serveur LOGESCO centralisé
- **Installation simple** : Installeur Windows standard (Inno Setup)
- **Déploiement en masse** : Scripts PowerShell pour déployer sur plusieurs clients
- **Configuration persistante** : Les paramètres serveur sont conservés lors des mises à jour

## Fichiers inclus

### Scripts de compilation

- **`build-client-network-installer.bat`** - Compile l'installeur client réseau
  - Nettoie les anciens builds
  - Compile le frontend Flutter
  - Crée l'installeur Inno Setup

### Scripts Inno Setup

- **`installer-setup-client-network.iss`** - Script Inno Setup pour le client réseau
  - Installation simple et rapide
  - Aucun backend inclus
  - Configuration serveur persistante

### Scripts de déploiement

- **`deploy-client-network.ps1`** - Déploie l'application sur plusieurs clients
  - Teste la connexion réseau
  - Copie et exécute l'installeur
  - Configure automatiquement le serveur

### Fichiers de configuration

- **`config/client-network-config.json`** - Configuration exemple pour les clients
- **`clients-list.txt`** - Liste des clients pour le déploiement en masse

### Documentation

- **`GUIDE_INSTALLATION_CLIENT_RESEAU.md`** - Guide complet d'installation et de configuration
- **`README_CLIENT_NETWORK.md`** - Ce fichier

## Démarrage rapide

### 1. Compiler l'installeur

```bash
# Exécutez le script de compilation
build-client-network-installer.bat
```

L'installeur sera créé dans `release/LOGESCO-v2-Client-Network-Setup.exe`

### 2. Distribuer aux clients

#### Option A : Installation manuelle

1. Téléchargez `LOGESCO-v2-Client-Network-Setup.exe`
2. Double-cliquez pour installer
3. Configurez l'adresse du serveur au premier démarrage

#### Option B : Déploiement en masse

```powershell
# Préparez la liste des clients dans clients-list.txt
# Puis exécutez:

.\deploy-client-network.ps1 `
    -InstallerPath "release\LOGESCO-v2-Client-Network-Setup.exe" `
    -ClientsFile "clients-list.txt" `
    -ServerAddress "192.168.1.100" `
    -ServerPort 3000
```

### 3. Configuration serveur

Assurez-vous que le serveur LOGESCO est accessible :

```bash
# Vérifiez que le serveur écoute sur toutes les interfaces
# backend/src/server.js doit avoir:
# const HOST = '0.0.0.0';
# const PORT = 3000;

# Autorisez le port dans le pare-feu Windows
netsh advfirewall firewall add rule name="LOGESCO Backend" dir=in action=allow protocol=tcp localport=3000
```

## Utilisation détaillée

### Compilation

```bash
# Compilation simple
build-client-network-installer.bat

# Le script effectue:
# 1. Nettoyage des anciens builds
# 2. flutter clean
# 3. flutter pub get
# 4. flutter build windows --release
# 5. Compilation Inno Setup
```

### Déploiement en masse

#### Préparation

1. Créez un fichier `clients-list.txt` avec les noms des ordinateurs :

```
CLIENT-01
CLIENT-02
CLIENT-03
MAGASIN2-CLIENT-01
```

2. Assurez-vous que vous avez les permissions administrateur sur les clients

#### Exécution

```powershell
# Déploiement simple
.\deploy-client-network.ps1 `
    -InstallerPath "release\LOGESCO-v2-Client-Network-Setup.exe" `
    -ClientsFile "clients-list.txt" `
    -ServerAddress "192.168.1.100"

# Déploiement silencieux (sans interaction)
.\deploy-client-network.ps1 `
    -InstallerPath "release\LOGESCO-v2-Client-Network-Setup.exe" `
    -ClientsFile "clients-list.txt" `
    -ServerAddress "192.168.1.100" `
    -Silent `
    -NoRestart
```

#### Paramètres

- `-InstallerPath` : Chemin vers l'installeur (obligatoire)
- `-ClientsFile` : Fichier contenant la liste des clients (obligatoire)
- `-ServerAddress` : Adresse IP ou nom du serveur (défaut: 192.168.1.100)
- `-ServerPort` : Port du serveur (défaut: 3000)
- `-Silent` : Installation silencieuse sans interaction
- `-NoRestart` : Ne pas redémarrer après l'installation

### Configuration manuelle

Si vous devez configurer manuellement un client :

1. Ouvrez `%LOCALAPPDATA%\LOGESCO\client\client-network-config.json`
2. Modifiez les paramètres serveur :

```json
{
  "serverConfig": {
    "host": "192.168.1.100",
    "port": 3000,
    "protocol": "http",
    "baseUrl": "http://192.168.1.100:3000"
  }
}
```

3. Redémarrez l'application

## Architecture

### Client

```
Client Windows
    ↓
LOGESCO v2 (Frontend Flutter)
    ↓
Connexion HTTP/HTTPS
    ↓
Serveur LOGESCO (Backend Node.js)
    ↓
Base de données
```

### Stockage local

Le client stocke uniquement :
- Configuration serveur
- Préférences utilisateur (langue, thème)
- Cache temporaire

Aucune donnée métier n'est stockée localement.

## Sécurité

### Recommandations

1. **HTTPS en production**
   ```javascript
   // Configurez le serveur avec SSL/TLS
   const https = require('https');
   const fs = require('fs');
   
   const options = {
     key: fs.readFileSync('path/to/key.pem'),
     cert: fs.readFileSync('path/to/cert.pem')
   };
   
   https.createServer(options, app).listen(3000);
   ```

2. **Authentification forte**
   - Utilisez des identifiants forts
   - Changez les identifiants par défaut
   - Activez l'authentification multi-facteurs si disponible

3. **Pare-feu**
   - Limitez l'accès au port 3000
   - Utilisez un VPN pour les connexions distantes
   - Configurez les règles de pare-feu sur le serveur

4. **Logs et audit**
   - Activez les logs d'audit sur le serveur
   - Surveillez les tentatives de connexion
   - Archivez les logs régulièrement

## Dépannage

### Le client ne peut pas se connecter

```powershell
# Testez la connectivité réseau
ping 192.168.1.100

# Testez le port
telnet 192.168.1.100 3000

# Vérifiez les pare-feu
netsh advfirewall firewall show rule name="LOGESCO Backend"
```

### L'application se ferme après la connexion

1. Vérifiez les logs du serveur
2. Vérifiez que l'utilisateur existe
3. Vérifiez les permissions de l'utilisateur

### Problèmes de performance

1. Vérifiez la bande passante réseau
2. Vérifiez la latence vers le serveur
3. Vérifiez les ressources du serveur (CPU, RAM)

## Mise à jour

### Mise à jour simple

```bash
# Recompilez l'installeur
build-client-network-installer.bat

# Distribuez la nouvelle version
# Les clients existants seront mis à jour
# La configuration serveur sera conservée
```

### Mise à jour en masse

```powershell
# Utilisez le même script de déploiement
.\deploy-client-network.ps1 `
    -InstallerPath "release\LOGESCO-v2-Client-Network-Setup.exe" `
    -ClientsFile "clients-list.txt" `
    -ServerAddress "192.168.1.100"
```

## Prérequis système

### Pour la compilation

- Windows 10 ou supérieur
- Flutter SDK (dernière version stable)
- Inno Setup 6
- Visual Studio Build Tools (pour la compilation C++)
- 2 GB d'espace disque minimum

### Pour les clients

- Windows 10 ou supérieur
- Connexion réseau vers le serveur
- 500 MB d'espace disque
- Aucune installation supplémentaire

## Support

Pour toute question ou problème :

1. Consultez le `GUIDE_INSTALLATION_CLIENT_RESEAU.md`
2. Vérifiez les logs d'application
3. Contactez le support technique

## Changelog

### Version 2.0.0

- Première version du client réseau
- Support complet des fonctionnalités LOGESCO
- Configuration serveur persistante
- Déploiement en masse avec PowerShell
- Documentation complète

## Licence

LOGESCO v2 - Client Réseau
Tous droits réservés

