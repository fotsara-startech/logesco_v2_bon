# Guide d'Installation - LOGESCO v2 Client Réseau

## Vue d'ensemble

Ce guide explique comment compiler et distribuer LOGESCO v2 pour les clients en réseau local qui se connectent à un serveur centralisé.

## Prérequis

### Pour la compilation
- Windows 10 ou supérieur
- Flutter SDK (dernière version stable)
- Inno Setup 6 (https://jrsoftware.org/isdl.php)
- Visual Studio Build Tools (pour la compilation C++)

### Pour les clients
- Windows 10 ou supérieur
- Connexion réseau vers le serveur LOGESCO
- Aucune installation supplémentaire requise

## Compilation de l'installeur Client Réseau

### Étape 1 : Préparation

```bash
# Clonez ou mettez à jour le repository
git clone <repository-url>
cd logesco

# Vérifiez que Flutter est installé
flutter --version

# Vérifiez que Inno Setup 6 est installé
# Chemin par défaut: C:\Program Files (x86)\Inno Setup 6\ISCC.exe
```

### Étape 2 : Compilation

Exécutez le script de build :

```bash
build-client-network-installer.bat
```

Le script effectuera automatiquement :
1. Nettoyage des anciens builds
2. Compilation Flutter (frontend uniquement)
3. Vérification des fichiers compilés
4. Création de l'installeur Inno Setup

### Étape 3 : Résultat

L'installeur sera créé dans le dossier `release/` :
```
release/LOGESCO-v2-Client-Network-Setup.exe
```

## Distribution aux clients

### Fichiers à fournir

1. **LOGESCO-v2-Client-Network-Setup.exe** - L'installeur
2. **Informations de connexion** :
   - Adresse IP ou nom du serveur
   - Port (par défaut: 3000)
   - Identifiants de connexion

### Instructions pour les clients

#### Installation

1. Téléchargez `LOGESCO-v2-Client-Network-Setup.exe`
2. Double-cliquez sur le fichier
3. Suivez l'assistant d'installation
4. Cliquez sur "Terminer" pour lancer l'application

#### Configuration initiale

Au premier démarrage :

1. L'application affichera un écran de configuration serveur
2. Entrez l'adresse du serveur (ex: `192.168.1.100`)
3. Entrez le port (par défaut: `3000`)
4. Cliquez sur "Tester la connexion"
5. Une fois la connexion confirmée, entrez vos identifiants
6. Cliquez sur "Connexion"

#### Utilisation

- L'application fonctionne exactement comme la version complète
- Toutes les données sont stockées sur le serveur
- Aucune base de données locale
- La déconnexion du serveur rend l'application inutilisable

## Configuration serveur

### Préparation du serveur

Assurez-vous que le serveur LOGESCO est configuré pour accepter les connexions réseau :

```javascript
// backend/src/server.js
const PORT = process.env.PORT || 3000;
const HOST = '0.0.0.0'; // Écoute sur toutes les interfaces réseau

app.listen(PORT, HOST, () => {
  console.log(`Serveur LOGESCO écoute sur ${HOST}:${PORT}`);
});
```

### Pare-feu Windows

Autorisez le port 3000 (ou le port configuré) :

```powershell
# En tant qu'administrateur
netsh advfirewall firewall add rule name="LOGESCO Backend" dir=in action=allow protocol=tcp localport=3000
```

### Configuration réseau

Pour les clients, fournissez :

```
Adresse serveur: 192.168.1.100
Port: 3000
URL complète: http://192.168.1.100:3000
```

## Mise à jour des clients

### Procédure de mise à jour

1. Téléchargez la nouvelle version de `LOGESCO-v2-Client-Network-Setup.exe`
2. Exécutez l'installeur sur le client
3. L'assistant détectera qu'une version est déjà installée
4. Cliquez sur "Mettre à jour"
5. La configuration serveur sera conservée
6. Cliquez sur "Terminer" pour relancer l'application

### Mise à jour en masse

Pour mettre à jour plusieurs clients :

```batch
REM Script de mise à jour en masse
@echo off
for /f "tokens=*" %%A in (clients.txt) do (
    echo Mise à jour de %%A...
    psexec \\%%A -s "C:\Program Files\LOGESCO\LOGESCO-v2-Client-Network-Setup.exe" /VERYSILENT /NORESTART
)
```

## Dépannage

### Le client ne peut pas se connecter au serveur

1. Vérifiez que le serveur est en cours d'exécution
2. Vérifiez l'adresse IP du serveur
3. Vérifiez que le port est correct
4. Vérifiez les pare-feu (client et serveur)
5. Testez la connectivité réseau :
   ```bash
   ping 192.168.1.100
   telnet 192.168.1.100 3000
   ```

### L'application se ferme après la connexion

1. Vérifiez les logs du serveur
2. Vérifiez que l'utilisateur existe sur le serveur
3. Vérifiez que l'utilisateur a les permissions requises

### Problèmes de performance

1. Vérifiez la bande passante réseau
2. Vérifiez la latence vers le serveur
3. Vérifiez les ressources du serveur (CPU, RAM)
4. Vérifiez les logs du serveur pour les erreurs

## Fichiers modifiés

### Pour le client réseau

Les fichiers suivants sont modifiés/créés :

- `installer-setup-client-network.iss` - Script Inno Setup pour client réseau
- `build-client-network-installer.bat` - Script de compilation
- `config/client-network-config.json` - Configuration exemple

### Pas de modifications dans le code Flutter

Le code Flutter reste inchangé. La configuration serveur est gérée par :
- `logesco_v2/lib/core/config/api_config.dart`
- `logesco_v2/lib/core/config/app_config.dart`

## Sécurité

### Recommandations

1. **HTTPS en production** : Configurez le serveur avec SSL/TLS
2. **Authentification** : Utilisez des identifiants forts
3. **Pare-feu** : Limitez l'accès au port 3000
4. **VPN** : Utilisez un VPN pour les connexions distantes
5. **Logs** : Activez les logs d'audit sur le serveur

### Configuration HTTPS

```javascript
// backend/src/server.js
const https = require('https');
const fs = require('fs');

const options = {
  key: fs.readFileSync('path/to/key.pem'),
  cert: fs.readFileSync('path/to/cert.pem')
};

https.createServer(options, app).listen(3000);
```

## Support

Pour toute question ou problème :
- Consultez la documentation complète
- Contactez le support technique
- Vérifiez les logs d'application

## Changelog

### Version 2.0.0
- Première version du client réseau
- Support complet des fonctionnalités LOGESCO
- Configuration serveur persistante
- Mise à jour automatique de la configuration

