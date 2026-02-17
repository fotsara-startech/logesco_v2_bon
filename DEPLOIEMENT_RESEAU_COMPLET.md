# 🚀 GUIDE COMPLET: Déployer LOGESCO sur Serveur Linux avec Clients Réseau

**Version:** 2.0.0  
**Date:** Janvier 2026  
**Statut:** 📋 Prêt pour déploiement  

---

## 📊 Vue d'Ensemble

Ce guide explique comment :
1. **Préparer** le backend pour Linux sur Windows
2. **Installer & configurer** le backend sur serveur Linux
3. **Déployer** l'application cliente sur les postes Windows
4. **Tester** la connexion réseau complète

---

## 🎯 Architecture Cible

```
┌────────────────────────────────────────┐
│     SERVEUR LINUX (Centralisé)          │
│  ┌──────────────────────────────────┐  │
│  │ Backend LOGESCO v2                │  │
│  │ - Node.js + Express               │  │
│  │ - Prisma + SQLite                 │  │
│  │ - Port 8080                       │  │
│  │ - Accès Réseau Activé             │  │
│  └──────────────────────────────────┘  │
│  IP: 192.168.x.x (à définir)           │
└────────────────────────────────────────┘
       ▲              ▲              ▲
       │              │              │
  ┌────┴───┐   ┌──────┴───┐  ┌──────┴───┐
  │ Client  │   │ Client   │  │ Client   │
  │ Windows │   │ Windows  │  │ Windows  │
  │ (Caisse)│   │ (Caisse) │  │(Gestion) │
  └─────────┘   └──────────┘  └──────────┘
  
  Chaque client accède au serveur via le réseau
```

---

## 📋 RÉSUMÉ DES 3 GUIDES CRÉÉS

### 📄 1. GUIDE_DEPLOIEMENT_LINUX_COMPLET.md
Guide détaillé pour installer le backend sur le serveur Linux.
- Configuration de l'environnement
- Installation des dépendances
- Lancement du service
- Sécurité & Firewall
- Troubleshooting

### 🛠️ 2. Script: backend/build-portable-linux.js
Script automatisé pour préparer le package Linux sur Windows.
```bash
cd backend
node build-portable-linux.js
```
Crée: `dist-portable/` avec tout ce qui est nécessaire

### 🖥️ 3. GUIDE_CONFIG_CLIENTS_WINDOWS.md
Guide pour configurer les postes clients Windows.
- Modification de la configuration (localhost → IP serveur)
- Recompilation Flutter
- Test de connexion
- Troubleshooting

### ⚙️ 4. Bonus: configurer-client-reseau.bat
Script automatisé pour modifier la config du client.
```batch
configurer-client-reseau.bat 192.168.1.100
```

---

## 🚀 PROCÉDURE RAPIDE (Résumé)

### **JOUR 1 - Sur Windows (Préparation)**

#### Étape 1: Préparer le Backend pour Linux

```bash
# Aller au dossier backend
cd backend

# Installer les dépendances
npm install

# Créer le package portable pour Linux
node build-portable-linux.js

# Résultat: dist-portable/
```

#### Étape 2: Compresser pour Transférer

```bash
# Compresser le package
tar -czf logesco-backend.tar.gz dist-portable/

# Copier sur clé USB ou partition partagée
# Ou compresser en ZIP si plus facile
# dist-portable.zip
```

---

### **JOUR 2 - Sur Serveur Linux (Installation)**

#### Étape 3: Recevoir et Extraire le Package

```bash
# Accéder au serveur
ssh user@192.168.1.100

# Extraire le package
tar -xzf logesco-backend.tar.gz

# Placer au bon endroit
sudo mv dist-portable /opt/logesco-backend
cd /opt/logesco-backend
```

#### Étape 4: Vérifier & Démarrer

```bash
# Vérifier Node.js
node --version

# Si absent, installer
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Démarrer le backend
bash start-backend.sh

# Vous devez voir:
# ✓ Server running on http://0.0.0.0:8080
```

#### Étape 5: Configurer Systemd (Optionnel mais recommandé)

```bash
cd /opt/logesco-backend
sudo bash install-service.sh

# Le service démarre automatiquement
sudo systemctl status logesco-backend
```

#### Étape 6: Vérifier l'Accès Réseau

```bash
# Depuis le serveur Linux
curl http://localhost:8080/api/v1/health

# Depuis un autre poste du réseau (PowerShell Windows)
curl http://192.168.1.100:8080/api/v1/health

# Résultat attendu: {"status": "ok"}
```

---

### **JOUR 3 - Sur les Postes Clients Windows**

#### Étape 7: Configurer les Clients

**Option A: Automatisé (Recommandé)**

```bash
# À la racine du projet
configurer-client-reseau.bat 192.168.1.100
```

**Option B: Manuel**

Éditer les fichiers Dart et remplacer `localhost:8080` par `192.168.1.100:8080`:
- `logesco_v2/lib/core/config/api_config.dart`
- `logesco_v2/lib/core/config/environment_config.dart`
- `logesco_v2/lib/core/bindings/initial_bindings.dart`
- `logesco_v2/lib/config/local_config.dart`

#### Étape 8: Recompiler & Déployer

```bash
cd logesco_v2

# Nettoyer
flutter clean
flutter pub get

# Build pour distribution
flutter build windows --release

# Créer l'installeur (optionnel)
build-production.bat
```

#### Étape 9: Installer sur les Postes Clients

```bash
# Option 1: Double-cliquer sur l'installeur
LOGESCO-v2-Setup.exe

# Option 2: Copier manuellement
xcopy /E /I /Y logesco_v2\build\windows\x64\runner\Release\* \poste-client\c$\Program Files\LOGESCO\
```

#### Étape 10: Tester la Connexion

```powershell
# Sur le poste client:

# 1. Ping
ping 192.168.1.100

# 2. Health check
curl http://192.168.1.100:8080/api/v1/health

# 3. Lancer l'application
& "C:\Program Files\LOGESCO\logesco_v2.exe"

# 4. Se connecter avec admin/admin123
```

---

## 📋 Checklist Complète

### Préparation Windows
- [ ] Backend testé en local
- [ ] `npm install` exécuté
- [ ] `node build-portable-linux.js` lancé
- [ ] `dist-portable/` créé avec succès
- [ ] Package compressé et prêt à transférer

### Installation Serveur Linux
- [ ] Backend reçu sur le serveur
- [ ] Package extrait dans `/opt/logesco-backend`
- [ ] Node.js v18+ installé
- [ ] `npm install` exécuté (si nécessaire)
- [ ] `bash start-backend.sh` fonctionne
- [ ] Health check répond: `curl http://localhost:8080/api/v1/health`
- [ ] Port 8080 ouvert dans le firewall
- [ ] Service systemd configuré (optionnel)

### Configuration Clients Windows
- [ ] IP du serveur Linux identifiée
- [ ] Fichiers Dart modifiés
- [ ] `flutter clean` + `flutter pub get` exécutés
- [ ] Build windows lancée
- [ ] Application installée sur les postes
- [ ] Ping vers le serveur réussit
- [ ] Health check local réussit
- [ ] Application lancée avec connexion au serveur

### Tests Finaux
- [ ] Login réussit avec admin/admin123
- [ ] Données visibles (produits, clients, etc.)
- [ ] Transactions possibles
- [ ] Tous les modules fonctionnent
- [ ] Plusieurs postes clients connectés simultanément

---

## 🔐 Points de Sécurité Importants

### Firewall
```bash
# Sur le serveur Linux
sudo ufw allow 8080/tcp
sudo ufw enable
```

### CORS (Important pour accès réseau)
Vérifier dans `backend/src/server.js`:
```javascript
const corsOptions = {
  origin: '*', // Ou restricter aux IPs connues
  credentials: true,
};
```

### Base de Données
- ✅ SQLite (fichier local) - Simple, pas de serveur
- Fichier: `/opt/logesco-backend/database/logesco.db`
- Backup recommandé: voir guide Deploiement Linux

### HTTPS (Optionnel)
Pour accès à travers Internet (pas local):
```bash
# Installer certbot sur Linux
sudo apt-get install certbot

# Générer certificat
sudo certbot certonly --standalone -d votre-domaine.com

# Configurer Node.js
# (Voir guide Deploiement Linux pour détails)
```

---

## 🆘 Troubleshooting Rapide

### Le backend ne démarre pas
```bash
cd /opt/logesco-backend
node src/server.js
# Regarder l'erreur exacte
```

### Les clients ne se connectent pas
```bash
# 1. Vérifier le ping
ping 192.168.1.100

# 2. Vérifier le firewall
sudo ufw status
sudo ufw allow 8080/tcp

# 3. Vérifier que le backend tourne
ps aux | grep "node"

# 4. Vérifier les logs
sudo journalctl -u logesco-backend -f
```

### "Connection Timeout" sur le client
```bash
# Le problème est généralement:
# 1. IP serveur incorrecte
# 2. Backend pas en écoute
# 3. Firewall bloque le port
# 4. Problème réseau

# Vérifications:
ping 192.168.1.100
curl http://192.168.1.100:8080/api/v1/health
```

---

## 📊 Fichiers Créés pour Cette Déploiement

| Fichier | Localisation | Description |
|---------|-------------|-------------|
| **GUIDE_DEPLOIEMENT_LINUX_COMPLET.md** | Racine projet | Guide détaillé serveur Linux |
| **GUIDE_CONFIG_CLIENTS_WINDOWS.md** | Racine projet | Guide configuration clients |
| **build-portable-linux.js** | `backend/` | Script de construction package |
| **configurer-client-reseau.bat** | Racine projet | Script config automatique clients |
| **dist-portable/** | Racine projet | Package final pour Linux |
| **start-backend.sh** | `dist-portable/` | Démarrage direct |
| **install-service.sh** | `dist-portable/` | Installation systemd |

---

## 📞 Workflow Recommandé

```
JOUR 1 (Lundi)
├─ Préparer le package Linux
├─ Transférer vers le client
└─ Recevoir sur serveur Linux

JOUR 2 (Mardi)
├─ Installer backend sur Linux
├─ Tester connection backend
└─ Configurer firewall/service

JOUR 3 (Mercredi)
├─ Configurer clients Windows
├─ Recompiler applications
├─ Installer sur postes clients
└─ Tests finaux & validation

JOUR 4 (Jeudi) - OPTIONNEL
└─ Formation utilisateurs
```

---

## 🎯 Résumé Ultra-Rapide

**3 commandes principales:**

1️⃣ **Sur Windows (Préparation):**
```bash
cd backend && node build-portable-linux.js
```

2️⃣ **Sur Linux (Installation):**
```bash
tar -xzf logesco-backend.tar.gz
sudo mv dist-portable /opt/logesco-backend
cd /opt/logesco-backend && bash start-backend.sh
```

3️⃣ **Sur Windows (Configuration clients):**
```bash
configurer-client-reseau.bat 192.168.1.100
cd logesco_v2 && flutter build windows --release
```

---

## 📚 Documentation Complète

- **[GUIDE_DEPLOIEMENT_LINUX_COMPLET.md](GUIDE_DEPLOIEMENT_LINUX_COMPLET.md)** - Détails serveur Linux
- **[GUIDE_CONFIG_CLIENTS_WINDOWS.md](GUIDE_CONFIG_CLIENTS_WINDOWS.md)** - Détails clients Windows
- **backend/README.md** - Documentation backend
- **logesco_v2/README.md** - Documentation client Flutter

---

## ✅ Confirmation de Compréhension

Tu as bien compris l'architecture ?

- ✅ **Backend** = Sur serveur Linux (centralisé)
- ✅ **Clients** = Sur postes Windows (distants, via réseau)
- ✅ **Base de données** = SQLite sur le serveur
- ✅ **Communication** = HTTP sur port 8080

→ **Tous les clients accèdent au même backend/database centralisés**

---

## 🚀 Prochaines Étapes

1. **Demander l'IP du serveur Linux** au client
2. **Exécuter `node build-portable-linux.js`** sur Windows
3. **Transférer le package** au serveur Linux
4. **Installer & tester** le backend sur Linux
5. **Configurer les clients** avec le script batch
6. **Déployer** sur les postes client

---

**Questions ? Voir les guides détaillés ou consulter les fichiers README dans chaque dossier.**

