# Déploiement du Client LOGESCO sur Réseau Local

## 🎯 Objectif
Installer et configurer le client LOGESCO pour se connecter à un serveur sur le réseau local (ex: `192.168.100.101:8080`).

## ⚠️ Problème Résolu
Le client compilé tentait de se connecter à `localhost` au premier démarrage. Ce problème a été corrigé en permettant la configuration dynamique de l'adresse du serveur.

## 📋 Étapes de Déploiement

### 1. Préparation du Serveur
Avant de déployer les clients, assurez-vous que:
- Le serveur LOGESCO est en cours d'exécution
- L'adresse IP du serveur est stable (ex: `192.168.100.101`)
- Le port `8080` est accessible depuis les clients
- Le firewall n'est pas bloquant

**Vérification:**
```bash
# Sur le serveur, vérifier que l'API répond
curl http://192.168.100.101:8080/api/v1/auth/test
```

### 2. Installation du Client

#### Option A: Installation Standard
1. Téléchargez l'installateur `logesco-client-setup.exe`
2. Exécutez l'installateur
3. Suivez les instructions
4. L'application s'installe dans `C:\Program Files\LOGESCO`

#### Option B: Installation Portable
1. Téléchargez `logesco-client-portable.zip`
2. Décompressez dans le dossier de votre choix
3. Exécutez `logesco.exe`

### 3. Configuration du Serveur (IMPORTANT!)

**Avant de lancer l'application pour la première fois**, vous DEVEZ configurer l'adresse du serveur.

#### Méthode 1: Script Automatique (RECOMMANDÉ)

**Sur Windows (Batch):**
```batch
configure-server.bat
```

**Sur Windows (PowerShell):**
```powershell
.\configure-server.ps1
```

Le script vous demandera:
- L'adresse IP du serveur (ex: `192.168.100.101`)
- Le port (par défaut: `8080`)

**Exemple:**
```
Entrez l'adresse IP du serveur: 192.168.100.101
Entrez le port du serveur: 8080
```

Le script crée automatiquement le fichier `C:\Users\[VotreNom]\Documents\server_config.txt`

#### Méthode 2: Configuration Manuelle

1. Ouvrez l'Explorateur de fichiers
2. Allez dans: `C:\Users\[VotreNom]\Documents`
3. Créez un fichier texte nommé `server_config.txt`
4. Écrivez dedans:
   ```
   http://192.168.100.101:8080/api/v1
   ```
5. Sauvegardez le fichier

#### Méthode 3: Configuration dans l'Application

1. Lancez l'application LOGESCO
2. Allez dans **Paramètres** (Settings)
3. Cherchez **Configuration du serveur**
4. Entrez l'adresse: `http://192.168.100.101:8080/api/v1`
5. Cliquez sur **Sauvegarder**

### 4. Premier Démarrage

1. Lancez l'application LOGESCO
2. Attendez le chargement initial (peut prendre 10-15 secondes)
3. Vous devriez voir l'écran de connexion
4. Connectez-vous avec les identifiants par défaut:
   - **Utilisateur:** `admin`
   - **Mot de passe:** `admin123`

### 5. Vérification de la Connexion

Si l'application se connecte correctement, vous verrez:
- ✅ L'écran de connexion s'affiche
- ✅ Vous pouvez vous connecter
- ✅ Le dashboard se charge

Si ça ne fonctionne pas:
- ❌ Écran blanc ou erreur de connexion
- ❌ Impossible de se connecter

## 🔧 Dépannage

### L'app ne se connecte pas au serveur

**Vérifications:**

1. **Vérifier l'adresse IP du serveur:**
   ```bash
   # Sur le serveur, ouvrir CMD et taper:
   ipconfig
   ```
   Cherchez l'adresse IPv4 (ex: `192.168.100.101`)

2. **Vérifier que le serveur répond:**
   ```bash
   # Sur le client, ouvrir CMD et taper:
   ping 192.168.100.101
   ```
   Vous devriez voir des réponses

3. **Vérifier que l'API répond:**
   ```bash
   # Ouvrir un navigateur et aller à:
   http://192.168.100.101:8080/api/v1/auth/test
   ```
   Vous devriez voir une réponse JSON

4. **Vérifier le fichier de configuration:**
   - Ouvrez `C:\Users\[VotreNom]\Documents\server_config.txt`
   - Vérifiez que l'URL est correcte
   - Redémarrez l'application

### Le fichier de configuration n'est pas créé

1. Vérifiez que vous avez les permissions d'écriture dans `Documents`
2. Essayez de créer le fichier manuellement
3. Redémarrez l'application

### L'app utilise toujours l'ancienne adresse

1. Supprimez le fichier `server_config.txt`
2. Redémarrez l'application
3. Recréez le fichier de configuration

## 📊 Format de l'URL

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
- `192.168.100.101:8080/api/v1` ❌ (manque `http://`)
- `http://192.168.100.101` ❌ (manque le port et `/api/v1`)
- `http://192.168.100.101:8080` ❌ (manque `/api/v1`)

## 🚀 Déploiement en Masse

Pour déployer sur plusieurs postes:

1. **Préparez un script batch:**
   ```batch
   @echo off
   REM Installer LOGESCO
   logesco-client-setup.exe /S
   
   REM Configurer le serveur
   echo http://192.168.100.101:8080/api/v1 > %USERPROFILE%\Documents\server_config.txt
   
   REM Lancer l'application
   start "LOGESCO" "C:\Program Files\LOGESCO\logesco.exe"
   ```

2. **Distribuez ce script aux clients**

3. **Les clients exécutent le script**

## 📞 Support

Si vous avez des problèmes:
1. Vérifiez que le serveur est en cours d'exécution
2. Vérifiez l'adresse IP du serveur
3. Vérifiez que le firewall n'est pas bloquant
4. Consultez les logs de l'application
5. Contactez le support technique

## ✅ Checklist de Déploiement

- [ ] Serveur LOGESCO en cours d'exécution
- [ ] Adresse IP du serveur identifiée
- [ ] Port 8080 accessible depuis les clients
- [ ] Firewall configuré correctement
- [ ] Client LOGESCO installé
- [ ] Fichier `server_config.txt` créé
- [ ] Application lancée avec succès
- [ ] Connexion réussie avec identifiants par défaut
- [ ] Dashboard chargé correctement
