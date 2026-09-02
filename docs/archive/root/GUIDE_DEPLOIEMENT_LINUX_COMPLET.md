# 📋 Guide Complet: Déployer LOGESCO Backend sur Serveur Linux

**Date:** Janvier 2026  
**Version:** 2.0.0  
**Objectif:** Installer le backend sur un serveur Linux pour accès réseau depuis postes Windows clients

---

## 🏗️ Architecture Cible

```
┌──────────────────────────────────┐
│   SERVEUR LINUX (Central)         │
│  ┌─────────────────────────────┐  │
│  │ Backend LOGESCO             │  │
│  │ - Node.js + Express         │  │
│  │ - Prisma ORM                │  │
│  │ - SQLite (database/)        │  │
│  │ Port: 8080                  │  │
│  └─────────────────────────────┘  │
│  IP: 192.168.x.x (à définir)      │
└──────────────────────────────────┘
         │         │         │
         ▼         ▼         ▼
    ┌────────┐ ┌────────┐ ┌────────┐
    │Poste 1 │ │Poste 2 │ │Poste 3 │
    │Windows │ │Windows │ │Windows │
    │Client  │ │Client  │ │Client  │
    └────────┘ └────────┘ └────────┘
```

---

## 📋 PHASE 1: Préparation du Backend (Sur Windows)

### 1.1 Vérifier les Dépendances

```bash
# Vérifier Node.js
node --version          # v18+ requis
npm --version           # v9+ requis

# Aller au dossier backend
cd backend
```

### 1.2 Installer & Configurer

```bash
# Installer les dépendances
npm install

# Générer Prisma client
npx prisma generate

# Créer/initialiser la base de données
npx prisma migrate deploy

# Vérifier la base de données
npx prisma db push
```

### 1.3 Créer le Package Transportable

```bash
# Exécuter le script de préparation
node build-portable-linux.js
```

**Résultat:** Dossier `dist-portable/` contenant :
- ✅ Code complet du backend
- ✅ `node_modules/` avec toutes les dépendances
- ✅ Client Prisma généré
- ✅ Base de données SQLite
- ✅ Scripts de démarrage

---

## 📦 PHASE 2: Transférer sur Serveur Linux

### 2.1 Options de Transfert

#### Option A: Via SSH/SCP (Recommandé - Sécurisé)

```bash
# Sur Windows, avec git-bash ou PowerShell (avec OpenSSH)

# 1. Compresser le package
tar -czf logesco-backend.tar.gz dist-portable/

# 2. Transférer vers Linux
scp logesco-backend.tar.gz user@192.168.x.x:/home/user/

# 3. Sur le serveur Linux, extraire
tar -xzf logesco-backend.tar.gz
mv dist-portable logesco-backend
```

#### Option B: Via Partage Réseau (SMB/Samba)

```bash
# Copier dist-portable/ sur partage réseau client
# Puis sur serveur Linux:
cp -r /mnt/network-share/dist-portable /opt/logesco-backend
```

#### Option C: Via Clé USB (Si pas de réseau)

```bash
# Copier dist-portable/ sur clé USB
# Puis sur serveur Linux:
sudo cp -r /media/usb/dist-portable /opt/logesco-backend
```

---

## 🐧 PHASE 3: Configuration sur Serveur Linux

### 3.1 Créer l'Utilisateur Dédié (Optionnel mais recommandé)

```bash
# Accéder avec sudo
sudo su -

# Créer utilisateur
sudo useradd -m -s /bin/bash logesco

# Définir le répertoire
sudo mkdir -p /opt/logesco-backend
sudo chown -R logesco:logesco /opt/logesco-backend
```

### 3.2 Transférer & Préparer les Fichiers

```bash
# Se connecter au serveur Linux
ssh user@192.168.x.x

# Naviger et extraire
cd /opt
tar -xzf logesco-backend.tar.gz
cd logesco-backend

# Vérifier la structure
ls -la
# Doit afficher: node_modules/, src/, database/, package.json, etc.
```

### 3.3 Installer Node.js sur Linux (Si absent)

```bash
# Vérifier si Node.js est installé
node --version

# Si absent, installer:
# Ubuntu/Debian
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Vérifier
node --version
npm --version
```

### 3.4 Installer les Dépendances (Si nécessaire)

```bash
cd /opt/logesco-backend

# Si node_modules n'a pas été transféré
npm install --production

# Générer Prisma client pour Linux
npx prisma generate
```

### 3.5 Configuration de la Base de Données

```bash
# Vérifier que database/ existe
ls -la database/

# Si absent, créer:
mkdir -p database

# Initialiser la base de données
npx prisma migrate deploy
```

### 3.6 Tester le Backend Manuellement

```bash
# Démarrer le backend
npm start

# Vous devriez voir:
# ✓ Server running on http://0.0.0.0:8080
# ✓ Database connected (SQLite)
# ✓ CORS enabled

# Dans une autre session SSH, tester:
curl http://localhost:8080/api/v1/health
```

**Résultat attendu:** Réponse JSON `{"status": "ok"}`

---

## 🚀 PHASE 4: Configuration Automatique (Systemd)

### 4.1 Créer le Service Systemd

```bash
sudo nano /etc/systemd/system/logesco-backend.service
```

**Coller ce contenu:**

```ini
[Unit]
Description=LOGESCO Backend Service
After=network.target
Wants=network-online.target

[Service]
Type=simple
User=logesco
WorkingDirectory=/opt/logesco-backend
ExecStart=/usr/bin/node /opt/logesco-backend/src/server.js
Restart=always
RestartSec=10
StandardOutput=append:/var/log/logesco-backend.log
StandardError=append:/var/log/logesco-backend.log
Environment="NODE_ENV=production"
Environment="PORT=8080"

[Install]
WantedBy=multi-user.target
```

### 4.2 Activer le Service

```bash
# Recharger systemd
sudo systemctl daemon-reload

# Activer le service
sudo systemctl enable logesco-backend

# Démarrer le service
sudo systemctl start logesco-backend

# Vérifier le statut
sudo systemctl status logesco-backend
```

### 4.3 Voir les Logs

```bash
# Logs en temps réel
sudo tail -f /var/log/logesco-backend.log

# Ou avec journalctl
sudo journalctl -u logesco-backend -f
```

---

## 🔥 PHASE 5: Configuration Firewall

### 5.1 Permettre l'Accès au Port 8080

```bash
# UFW (Ubuntu/Debian)
sudo ufw allow 8080/tcp

# iptables
sudo iptables -A INPUT -p tcp --dport 8080 -j ACCEPT
sudo iptables-save | sudo tee /etc/iptables/rules.v4

# Vérifier
sudo ufw status
```

### 5.2 Tester l'Accès Réseau depuis Windows

```powershell
# Sur un poste Windows:
Invoke-WebRequest -Uri "http://192.168.x.x:8080/api/v1/health"

# Ou avec curl:
curl http://192.168.x.x:8080/api/v1/health

# Résultat attendu: {"status": "ok"}
```

---

## 🔐 PHASE 6: Sécurité & Optimisation

### 6.1 Configuration CORS (Important!)

Si les clients accèdent de IP différentes, vérifier `/opt/logesco-backend/src/server.js` :

```javascript
// Vérifier que CORS est configuré
const corsOptions = {
  origin: '*', // Ou spécifier les IPs autorisées
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
};

app.use(cors(corsOptions));
```

### 6.2 HTTPS (Optionnel - Pour accès Internet)

```bash
# Installer Certbot
sudo apt-get install certbot

# Générer certificat
sudo certbot certonly --standalone -d your-domain.com

# Configurer Node.js pour HTTPS
# (Modifier src/server.js)
```

### 6.3 Reverse Proxy avec Nginx (Optionnel)

```bash
sudo nano /etc/nginx/sites-available/logesco
```

```nginx
server {
    listen 80;
    server_name 192.168.x.x;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

### 6.4 Backup Automatique de la Base de Données

```bash
# Créer script de backup
cat > /usr/local/bin/backup-logesco-db.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/opt/logesco-backup"
mkdir -p $BACKUP_DIR
cp /opt/logesco-backend/database/logesco.db $BACKUP_DIR/logesco-$(date +%Y%m%d-%H%M%S).db
# Garder les 7 derniers backups
ls -t $BACKUP_DIR/logesco-*.db | tail -n +8 | xargs rm -f
EOF

# Rendre exécutable
sudo chmod +x /usr/local/bin/backup-logesco-db.sh

# Ajouter au crontab pour backup quotidien
sudo crontab -e
# Ajouter: 0 2 * * * /usr/local/bin/backup-logesco-db.sh
```

---

## 🖥️ PHASE 7: Configuration des Clients Windows

**→ Voir le guide séparé: [GUIDE_CONFIG_CLIENTS_WINDOWS.md](GUIDE_CONFIG_CLIENTS_WINDOWS.md)**

---

## 📝 Checklist Déploiement

- [ ] Backend compilé et testé sur Windows
- [ ] Package portable créé (`dist-portable/`)
- [ ] Backend transféré sur serveur Linux
- [ ] Node.js installé sur Linux
- [ ] Dépendances installées
- [ ] Base de données initialisée
- [ ] Backend testé manuellement
- [ ] Service systemd configuré et actif
- [ ] Firewall configured
- [ ] CORS configuration vérifiée
- [ ] Backup configuré
- [ ] Clients Windows configurés
- [ ] Connexion réseau testée depuis un poste client

---

## 🆘 Troubleshooting

### Problème: "Command not found: npm"

```bash
# Node.js n'est pas installé
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
```

### Problème: "Cannot start service"

```bash
# Vérifier les logs
sudo journalctl -u logesco-backend -n 50

# Test manuel
cd /opt/logesco-backend
node src/server.js
```

### Problème: "Cannot find module 'prisma'"

```bash
cd /opt/logesco-backend
npm install
npx prisma generate
```

### Problème: "Port 8080 already in use"

```bash
# Trouver le processus
sudo lsof -i :8080

# Tuer le processus (si nécessaire)
sudo kill -9 <PID>

# Ou utiliser un autre port dans .env
echo "PORT=8081" >> .env
```

### Problème: Clients ne peuvent pas se connecter

```bash
# 1. Tester depuis Linux
curl http://localhost:8080/api/v1/health

# 2. Tester depuis Windows
ping 192.168.x.x
curl http://192.168.x.x:8080/api/v1/health

# 3. Vérifier firewall
sudo ufw status
sudo ufw allow 8080/tcp

# 4. Vérifier CORS
# Voir src/server.js
```

---

## 📞 Contacts & Support

- **Logs serveur:** `/var/log/logesco-backend.log`
- **Config backend:** `/opt/logesco-backend/src/config/environment.js`
- **Database:** `/opt/logesco-backend/database/logesco.db`

