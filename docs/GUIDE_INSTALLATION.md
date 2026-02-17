# Guide d'Installation - LOGESCO v2

## Table des Matières

1. [Vue d'Ensemble](#vue-densemble)
2. [Installation Desktop (Mode Local)](#installation-desktop-mode-local)
3. [Installation Web (Mode Cloud)](#installation-web-mode-cloud)
4. [Configuration Initiale](#configuration-initiale)
5. [Vérification de l'Installation](#vérification-de-linstallation)
6. [Dépannage](#dépannage)
7. [Désinstallation](#désinstallation)

---

## Vue d'Ensemble

LOGESCO v2 est disponible en deux modes de déploiement :

### Mode Desktop (Local)
- ✅ Installation sur Windows
- ✅ Fonctionne 100% hors ligne
- ✅ Données stockées localement (SQLite)
- ✅ Idéal pour usage mono-poste
- ✅ Installation en un clic

### Mode Web (Cloud)
- ✅ Accessible via navigateur
- ✅ Nécessite connexion internet
- ✅ Données dans le cloud (PostgreSQL)
- ✅ Idéal pour multi-utilisateurs
- ✅ Accès depuis n'importe où

---

## Installation Desktop (Mode Local)

### Prérequis Système

**Configuration Minimale**
- Système d'exploitation : Windows 10 ou supérieur (64-bit)
- Processeur : Intel Core i3 ou équivalent
- RAM : 4 GB minimum
- Espace disque : 500 MB disponible
- Résolution écran : 1280x720 minimum

**Configuration Recommandée**
- Système d'exploitation : Windows 11 (64-bit)
- Processeur : Intel Core i5 ou supérieur
- RAM : 8 GB ou plus
- Espace disque : 1 GB disponible
- Résolution écran : 1920x1080 ou supérieure

### Étape 1 : Téléchargement

1. Téléchargez le fichier d'installation : `LOGESCO-v2-Setup.exe`
2. Vérifiez l'intégrité du fichier (optionnel) :
   - Taille : ~150 MB
   - Checksum MD5 : [fourni avec le téléchargement]

### Étape 2 : Installation

1. **Lancez l'installateur**
   - Double-cliquez sur `LOGESCO-v2-Setup.exe`
   - Si Windows affiche un avertissement de sécurité, cliquez sur **Plus d'infos** puis **Exécuter quand même**

2. **Assistant d'Installation**
   - Cliquez sur **Suivant**
   - Acceptez les termes de la licence
   - Choisissez le dossier d'installation (par défaut : `C:\Program Files\LOGESCO\`)
   - Cliquez sur **Installer**

3. **Installation Automatique**
   L'installateur effectue automatiquement :
   - ✅ Copie des fichiers de l'application
   - ✅ Installation de l'API REST comme service Windows
   - ✅ Création de la base de données SQLite
   - ✅ Configuration des connexions locales
   - ✅ Création des raccourcis (Bureau + Menu Démarrer)
   - ✅ Configuration du pare-feu Windows

4. **Finalisation**
   - Attendez la fin de l'installation (2-3 minutes)
   - Cochez **Lancer LOGESCO v2** si vous voulez démarrer immédiatement
   - Cliquez sur **Terminer**

### Étape 3 : Premier Démarrage

1. **Lancement de l'Application**
   - Double-cliquez sur l'icône LOGESCO sur votre bureau
   - OU : Menu Démarrer > LOGESCO v2

2. **Vérification du Service API**
   - L'application vérifie automatiquement que l'API est démarrée
   - Si l'API n'est pas démarrée, l'application la démarre automatiquement

3. **Écran de Connexion**
   - Utilisateur par défaut : `admin`
   - Mot de passe par défaut : `admin123`
   - Cliquez sur **Se connecter**

4. **Configuration Initiale**
   - Changez le mot de passe administrateur (recommandé)
   - Configurez les informations de votre entreprise
   - L'application est prête à l'emploi !

### Structure des Fichiers Installés

```
C:\Program Files\LOGESCO\
├── app\
│   ├── logesco_desktop.exe          # Application Flutter
│   └── data\                         # Ressources de l'application
├── api\
│   ├── logesco_api.exe               # API REST (service Windows)
│   ├── config\
│   │   └── local.json                # Configuration locale
│   └── logs\                         # Logs de l'API
├── database\
│   └── logesco.db                    # Base de données SQLite
├── backup\                           # Sauvegardes automatiques
└── docs\                             # Documentation
```

### Configuration du Service Windows

Le service **LOGESCO API** est installé automatiquement et configuré pour :
- ✅ Démarrage automatique avec Windows
- ✅ Port : 8080 (configurable)
- ✅ Redémarrage automatique en cas d'erreur

**Gérer le Service Manuellement**

1. Ouvrez **Services Windows** :
   - Appuyez sur `Win + R`
   - Tapez `services.msc`
   - Appuyez sur Entrée

2. Recherchez **LOGESCO API Service**

3. Actions disponibles :
   - **Démarrer** : Clic droit > Démarrer
   - **Arrêter** : Clic droit > Arrêter
   - **Redémarrer** : Clic droit > Redémarrer
   - **Propriétés** : Clic droit > Propriétés (pour changer le type de démarrage)

### Sauvegarde des Données (Mode Local)

**Sauvegarde Automatique**
- Le système crée une sauvegarde quotidienne dans `C:\Program Files\LOGESCO\backup\`
- Format : `logesco_backup_YYYYMMDD.db`
- Rétention : 30 jours

**Sauvegarde Manuelle**

1. **Méthode Simple**
   - Dans l'application : Menu > Paramètres > Sauvegarder les données
   - Choisissez l'emplacement de sauvegarde
   - Cliquez sur **Sauvegarder**

2. **Méthode Manuelle**
   - Fermez l'application LOGESCO
   - Arrêtez le service LOGESCO API
   - Copiez le fichier `C:\Program Files\LOGESCO\database\logesco.db`
   - Collez-le dans un emplacement sûr (clé USB, cloud, etc.)

**Restauration d'une Sauvegarde**

1. Fermez l'application LOGESCO
2. Arrêtez le service LOGESCO API
3. Remplacez `C:\Program Files\LOGESCO\database\logesco.db` par votre sauvegarde
4. Redémarrez le service LOGESCO API
5. Lancez l'application

---

## Installation Web (Mode Cloud)

### Prérequis

**Côté Client (Utilisateur)**
- Navigateur web moderne :
  - Google Chrome 90+ (recommandé)
  - Mozilla Firefox 88+
  - Microsoft Edge 90+
  - Safari 14+
- Connexion internet stable (minimum 1 Mbps)

**Côté Serveur (Administrateur)**
- Serveur Linux (Ubuntu 20.04+ recommandé) ou Windows Server
- Docker et Docker Compose installés
- PostgreSQL 13+ (ou via Docker)
- Nom de domaine (optionnel mais recommandé)
- Certificat SSL (Let's Encrypt recommandé)

### Déploiement avec Docker (Recommandé)

#### Étape 1 : Préparation du Serveur

1. **Connexion au Serveur**
   ```bash
   ssh user@votre-serveur.com
   ```

2. **Installation de Docker**
   ```bash
   # Mise à jour du système
   sudo apt update && sudo apt upgrade -y

   # Installation de Docker
   curl -fsSL https://get.docker.com -o get-docker.sh
   sudo sh get-docker.sh

   # Installation de Docker Compose
   sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
   sudo chmod +x /usr/local/bin/docker-compose

   # Vérification
   docker --version
   docker-compose --version
   ```

3. **Création du Répertoire de Déploiement**
   ```bash
   mkdir -p /opt/logesco
   cd /opt/logesco
   ```

#### Étape 2 : Configuration

1. **Créez le fichier `docker-compose.yml`**
   ```bash
   nano docker-compose.yml
   ```

   Contenu :
   ```yaml
   version: '3.8'

   services:
     # Base de données PostgreSQL
     db:
       image: postgres:15-alpine
       container_name: logesco_db
       restart: always
       environment:
         POSTGRES_DB: logesco
         POSTGRES_USER: logesco_user
         POSTGRES_PASSWORD: ${DB_PASSWORD}
       volumes:
         - postgres_data:/var/lib/postgresql/data
         - ./backup:/backup
       ports:
         - "5432:5432"
       healthcheck:
         test: ["CMD-SHELL", "pg_isready -U logesco_user"]
         interval: 10s
         timeout: 5s
         retries: 5

     # API REST Backend
     api:
       image: logesco/api:latest
       container_name: logesco_api
       restart: always
       depends_on:
         db:
           condition: service_healthy
       environment:
         NODE_ENV: production
         DATABASE_URL: postgresql://logesco_user:${DB_PASSWORD}@db:5432/logesco
         JWT_SECRET: ${JWT_SECRET}
         PORT: 3000
       ports:
         - "3000:3000"
       volumes:
         - ./logs:/app/logs
         - ./uploads:/app/uploads
       healthcheck:
         test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
         interval: 30s
         timeout: 10s
         retries: 3

     # Application Web Flutter
     web:
       image: logesco/web:latest
       container_name: logesco_web
       restart: always
       depends_on:
         - api
       environment:
         API_URL: ${API_URL}
       ports:
         - "80:80"
         - "443:443"
       volumes:
         - ./nginx/ssl:/etc/nginx/ssl:ro
         - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro

   volumes:
     postgres_data:
       driver: local

   networks:
     default:
       name: logesco_network
   ```

2. **Créez le fichier `.env`**
   ```bash
   nano .env
   ```

   Contenu :
   ```env
   # Base de données
   DB_PASSWORD=VotreMotDePasseSecurise123!

   # JWT Secret (générez une clé aléatoire sécurisée)
   JWT_SECRET=VotreCleSecreteTresLongueEtAleatoire456!

   # URL de l'API (remplacez par votre domaine)
   API_URL=https://api.votre-domaine.com
   ```

   ⚠️ **Important** : Changez les mots de passe et secrets !

3. **Générez des Secrets Sécurisés**
   ```bash
   # Générer un mot de passe aléatoire
   openssl rand -base64 32

   # Générer un JWT secret
   openssl rand -hex 64
   ```

#### Étape 3 : Configuration SSL (HTTPS)

**Option 1 : Let's Encrypt (Gratuit, Recommandé)**

1. **Installation de Certbot**
   ```bash
   sudo apt install certbot python3-certbot-nginx -y
   ```

2. **Obtention du Certificat**
   ```bash
   sudo certbot certonly --standalone -d votre-domaine.com -d api.votre-domaine.com
   ```

3. **Copie des Certificats**
   ```bash
   mkdir -p nginx/ssl
   sudo cp /etc/letsencrypt/live/votre-domaine.com/fullchain.pem nginx/ssl/
   sudo cp /etc/letsencrypt/live/votre-domaine.com/privkey.pem nginx/ssl/
   ```

**Option 2 : Certificat Auto-Signé (Développement)**

```bash
mkdir -p nginx/ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout nginx/ssl/privkey.pem \
  -out nginx/ssl/fullchain.pem \
  -subj "/CN=votre-domaine.com"
```

#### Étape 4 : Déploiement

1. **Téléchargez les Images Docker**
   ```bash
   docker-compose pull
   ```

2. **Démarrez les Services**
   ```bash
   docker-compose up -d
   ```

3. **Vérifiez le Statut**
   ```bash
   docker-compose ps
   ```

   Tous les services doivent être **Up** et **healthy**.

4. **Consultez les Logs**
   ```bash
   # Logs de tous les services
   docker-compose logs -f

   # Logs d'un service spécifique
   docker-compose logs -f api
   ```

#### Étape 5 : Initialisation de la Base de Données

1. **Exécutez les Migrations**
   ```bash
   docker-compose exec api npm run migrate
   ```

2. **Créez l'Utilisateur Administrateur**
   ```bash
   docker-compose exec api npm run seed:admin
   ```

   Credentials par défaut :
   - Utilisateur : `admin`
   - Mot de passe : `admin123`

### Configuration DNS

Configurez vos enregistrements DNS :

```
Type    Nom                     Valeur
A       votre-domaine.com       IP_DU_SERVEUR
A       api.votre-domaine.com   IP_DU_SERVEUR
```

### Accès à l'Application Web

1. Ouvrez votre navigateur
2. Accédez à : `https://votre-domaine.com`
3. Connectez-vous avec les credentials par défaut
4. **Changez immédiatement le mot de passe !**

### Sauvegarde des Données (Mode Cloud)

**Sauvegarde Automatique PostgreSQL**

1. **Créez un Script de Sauvegarde**
   ```bash
   nano /opt/logesco/backup.sh
   ```

   Contenu :
   ```bash
   #!/bin/bash
   DATE=$(date +%Y%m%d_%H%M%S)
   BACKUP_DIR="/opt/logesco/backup"
   
   # Créer le répertoire si nécessaire
   mkdir -p $BACKUP_DIR
   
   # Sauvegarde de la base de données
   docker-compose exec -T db pg_dump -U logesco_user logesco > $BACKUP_DIR/logesco_$DATE.sql
   
   # Compression
   gzip $BACKUP_DIR/logesco_$DATE.sql
   
   # Suppression des sauvegardes de plus de 30 jours
   find $BACKUP_DIR -name "logesco_*.sql.gz" -mtime +30 -delete
   
   echo "Sauvegarde terminée : logesco_$DATE.sql.gz"
   ```

2. **Rendez le Script Exécutable**
   ```bash
   chmod +x /opt/logesco/backup.sh
   ```

3. **Configurez une Tâche Cron (Sauvegarde Quotidienne)**
   ```bash
   crontab -e
   ```

   Ajoutez :
   ```
   0 2 * * * /opt/logesco/backup.sh >> /opt/logesco/backup.log 2>&1
   ```

   (Sauvegarde tous les jours à 2h du matin)

**Restauration d'une Sauvegarde**

```bash
# Arrêtez l'API
docker-compose stop api

# Restaurez la base de données
gunzip -c /opt/logesco/backup/logesco_YYYYMMDD_HHMMSS.sql.gz | \
  docker-compose exec -T db psql -U logesco_user logesco

# Redémarrez l'API
docker-compose start api
```

### Mise à Jour de l'Application

```bash
cd /opt/logesco

# Téléchargez les nouvelles images
docker-compose pull

# Redémarrez avec les nouvelles versions
docker-compose up -d

# Exécutez les migrations si nécessaire
docker-compose exec api npm run migrate
```

---

## Configuration Initiale

### Première Connexion

1. **Connexion Administrateur**
   - Utilisateur : `admin`
   - Mot de passe : `admin123`

2. **Changement du Mot de Passe**
   - Cliquez sur votre nom en haut à droite
   - Sélectionnez **Paramètres**
   - Cliquez sur **Changer le mot de passe**
   - Entrez un mot de passe fort
   - Enregistrez

### Configuration de l'Entreprise

1. **Informations de l'Entreprise**
   - Menu > Paramètres > Entreprise
   - Remplissez :
     - Nom de l'entreprise
     - Adresse
     - Téléphone
     - Email
     - Logo (optionnel)
   - Enregistrez

2. **Paramètres de Vente**
   - Devise par défaut
   - Format de numérotation des ventes
   - TVA (si applicable)

3. **Paramètres de Stock**
   - Seuils d'alerte par défaut
   - Gestion des réservations

### Création des Utilisateurs

1. Menu > Paramètres > Utilisateurs
2. Cliquez sur **+ Nouvel Utilisateur**
3. Remplissez les informations
4. Définissez les permissions
5. Enregistrez

---

## Vérification de l'Installation

### Tests de Base

**1. Test de Connexion**
- ✅ Connexion réussie avec les credentials
- ✅ Tableau de bord s'affiche correctement

**2. Test de Création de Données**
- ✅ Créer un produit
- ✅ Créer un client
- ✅ Créer un fournisseur

**3. Test de Vente**
- ✅ Créer une vente avec le produit créé
- ✅ Vérifier la mise à jour du stock
- ✅ Vérifier l'affichage dans le tableau de bord

**4. Test de Sauvegarde (Desktop)**
- ✅ Créer une sauvegarde manuelle
- ✅ Vérifier que le fichier est créé

### Vérification des Services (Desktop)

1. **Vérifier le Service API**
   ```cmd
   sc query "LOGESCO API Service"
   ```
   Statut attendu : **RUNNING**

2. **Vérifier la Connectivité API**
   - Ouvrez un navigateur
   - Accédez à : `http://localhost:8080/health`
   - Réponse attendue : `{"status": "ok"}`

3. **Vérifier la Base de Données**
   - Le fichier `C:\Program Files\LOGESCO\database\logesco.db` existe
   - Taille > 0 KB

### Vérification des Services (Web)

1. **Vérifier les Conteneurs Docker**
   ```bash
   docker-compose ps
   ```
   Tous les services doivent être **Up** et **healthy**.

2. **Vérifier l'API**
   ```bash
   curl https://api.votre-domaine.com/health
   ```
   Réponse attendue : `{"status": "ok"}`

3. **Vérifier la Base de Données**
   ```bash
   docker-compose exec db psql -U logesco_user -d logesco -c "SELECT COUNT(*) FROM utilisateurs;"
   ```
   Doit retourner au moins 1 (l'admin).

---

## Dépannage

### Problèmes Courants (Desktop)

**Problème : "Impossible de se connecter à l'API"**

Solutions :
1. Vérifiez que le service est démarré :
   ```cmd
   sc query "LOGESCO API Service"
   ```
2. Si arrêté, démarrez-le :
   ```cmd
   sc start "LOGESCO API Service"
   ```
3. Vérifiez le pare-feu Windows :
   - Panneau de configuration > Pare-feu Windows
   - Autoriser LOGESCO API sur le port 8080

**Problème : "Base de données corrompue"**

Solutions :
1. Restaurez une sauvegarde récente
2. Si pas de sauvegarde, contactez le support

**Problème : "L'application ne démarre pas"**

Solutions :
1. Vérifiez les prérequis système
2. Réinstallez l'application
3. Consultez les logs : `C:\Program Files\LOGESCO\api\logs\`

### Problèmes Courants (Web)

**Problème : "502 Bad Gateway"**

Solutions :
1. Vérifiez que l'API est démarrée :
   ```bash
   docker-compose ps api
   ```
2. Consultez les logs :
   ```bash
   docker-compose logs api
   ```
3. Redémarrez l'API :
   ```bash
   docker-compose restart api
   ```

**Problème : "Connexion à la base de données échouée"**

Solutions :
1. Vérifiez que PostgreSQL est démarré :
   ```bash
   docker-compose ps db
   ```
2. Vérifiez les credentials dans `.env`
3. Redémarrez la base de données :
   ```bash
   docker-compose restart db
   ```

**Problème : "Certificat SSL invalide"**

Solutions :
1. Vérifiez que les certificats existent :
   ```bash
   ls -l nginx/ssl/
   ```
2. Renouvelez le certificat Let's Encrypt :
   ```bash
   sudo certbot renew
   ```
3. Redémarrez le service web :
   ```bash
   docker-compose restart web
   ```

### Logs et Diagnostic

**Desktop**
- Logs API : `C:\Program Files\LOGESCO\api\logs\`
- Logs Application : `C:\Users\[Utilisateur]\AppData\Local\LOGESCO\logs\`

**Web**
```bash
# Tous les logs
docker-compose logs -f

# Logs API uniquement
docker-compose logs -f api

# Logs base de données
docker-compose logs -f db

# Dernières 100 lignes
docker-compose logs --tail=100 api
```

---

## Désinstallation

### Désinstallation Desktop

**Méthode 1 : Désinstalleur Windows**
1. Panneau de configuration > Programmes et fonctionnalités
2. Recherchez **LOGESCO v2**
3. Cliquez sur **Désinstaller**
4. Suivez l'assistant

**Méthode 2 : Désinstallation Manuelle**
1. Arrêtez le service LOGESCO API
2. Supprimez le service :
   ```cmd
   sc delete "LOGESCO API Service"
   ```
3. Supprimez le dossier : `C:\Program Files\LOGESCO\`
4. Supprimez les raccourcis

⚠️ **Attention** : Sauvegardez vos données avant de désinstaller !

### Désinstallation Web

```bash
cd /opt/logesco

# Arrêtez et supprimez les conteneurs
docker-compose down

# Supprimez les volumes (ATTENTION : supprime les données !)
docker-compose down -v

# Supprimez les images
docker rmi logesco/api:latest logesco/web:latest

# Supprimez le répertoire
cd ..
rm -rf /opt/logesco
```

⚠️ **Attention** : Sauvegardez vos données avant de désinstaller !

---

## Support et Assistance

### Ressources

- 📖 **Documentation** : Consultez le Guide Utilisateur
- 🎥 **Vidéos** : Tutoriels sur www.logesco.com/videos
- 💬 **Forum** : community.logesco.com
- 📧 **Email** : support@logesco.com
- 📞 **Téléphone** : +XXX XXX XXX XXX

### Informations à Fournir pour le Support

Lors d'une demande de support, fournissez :
- Version de LOGESCO (Menu > À propos)
- Système d'exploitation et version
- Description détaillée du problème
- Captures d'écran si applicable
- Logs (si disponibles)

---

**Version du document** : 1.0
**Dernière mise à jour** : Novembre 2024
**LOGESCO v2** - Logiciel de Gestion Commerciale
