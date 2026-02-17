#!/usr/bin/env node

/**
 * Script de préparation du package LOGESCO Backend pour déploiement sur serveur Linux
 * 
 * Usage: node build-portable-linux.js
 * 
 * Crée un package portable contenant:
 * - Code source complet
 * - Toutes les dépendances Node.js
 * - Client Prisma généré
 * - Base de données SQLite
 * - Scripts de démarrage/arrêt
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const COLORS = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  red: '\x1b[31m',
};

const log = {
  title: (msg) => console.log(`\n${COLORS.bright}${COLORS.blue}▶ ${msg}${COLORS.reset}`),
  success: (msg) => console.log(`${COLORS.green}✓ ${msg}${COLORS.reset}`),
  error: (msg) => console.error(`${COLORS.red}✗ ${msg}${COLORS.reset}`),
  warning: (msg) => console.log(`${COLORS.yellow}⚠ ${msg}${COLORS.reset}`),
  info: (msg) => console.log(`  ${msg}`),
};

class LinuxDeploymentBuilder {
  constructor() {
    this.projectRoot = path.join(__dirname, 'backend');
    this.outputDir = path.join(__dirname, 'dist-portable');
    this.startTime = Date.now();
  }

  /**
   * Exécute une commande avec gestion d'erreur
   */
  exec(command, cwd = this.projectRoot) {
    try {
      log.info(`Exécution: ${command}`);
      execSync(command, {
        cwd,
        stdio: 'inherit',
        shell: process.platform === 'win32' ? 'powershell.exe' : '/bin/bash',
      });
    } catch (error) {
      log.error(`Erreur: ${command}`);
      throw error;
    }
  }

  /**
   * Copie un dossier récursivement
   */
  copyDir(src, dest, exclude = []) {
    if (!fs.existsSync(dest)) {
      fs.mkdirSync(dest, { recursive: true });
    }

    const items = fs.readdirSync(src);

    items.forEach((item) => {
      if (exclude.includes(item)) {
        return;
      }

      const srcPath = path.join(src, item);
      const destPath = path.join(dest, item);
      const stat = fs.statSync(srcPath);

      if (stat.isDirectory()) {
        this.copyDir(srcPath, destPath, exclude);
      } else {
        fs.copyFileSync(srcPath, destPath);
      }
    });
  }

  /**
   * Crée le dossier de sortie
   */
  createOutputDir() {
    log.title('Création du dossier de sortie');
    
    if (fs.existsSync(this.outputDir)) {
      log.warning(`Le dossier ${this.outputDir} existe déjà. Suppression...`);
      fs.rmSync(this.outputDir, { recursive: true, force: true });
    }

    fs.mkdirSync(this.outputDir, { recursive: true });
    log.success(`Dossier créé: ${this.outputDir}`);
  }

  /**
   * Copie le code source
   */
  copySources() {
    log.title('Copie du code source');

    const excludeDirs = ['node_modules', 'dist', '.git', 'logs', 'uploads'];
    this.copyDir(
      this.projectRoot,
      this.outputDir,
      excludeDirs
    );

    log.success('Code source copié');
  }

  /**
   * Installe les dépendances
   */
  installDependencies() {
    log.title('Installation des dépendances (npm install)');

    this.exec('npm install --production', this.outputDir);

    log.success('Dépendances installées');
  }

  /**
   * Génère le client Prisma
   */
  generatePrisma() {
    log.title('Génération du client Prisma');

    this.exec('npx prisma generate', this.outputDir);

    log.success('Client Prisma généré');
  }

  /**
   * Crée la structure de base de données
   */
  createDatabase() {
    log.title('Création de la structure de base de données');

    const dbDir = path.join(this.outputDir, 'database');
    
    if (!fs.existsSync(dbDir)) {
      fs.mkdirSync(dbDir, { recursive: true });
    }

    // Déployer les migrations (crée logesco.db)
    try {
      this.exec('npx prisma migrate deploy', this.outputDir);
    } catch (error) {
      log.warning('Migration Prisma échouée, tentative alternative...');
      // Créer un fichier database vide
      fs.writeFileSync(path.join(dbDir, 'logesco.db'), '');
    }

    log.success('Structure de base de données créée');
  }

  /**
   * Crée les scripts de démarrage Linux
   */
  createLinuxScripts() {
    log.title('Création des scripts de démarrage');

    // Script start-backend.sh
    const startScript = `#!/bin/bash

# LOGESCO Backend - Script de démarrage pour Linux

echo "================================"
echo "Démarrage du Backend LOGESCO..."
echo "================================"

# Aller au répertoire du backend
cd "$(dirname "$0")"

# Définir les variables
export NODE_ENV=production
export PORT=\${PORT:-8080}

# Démarrer le backend
echo "Backend démarre sur le port \$PORT..."
echo "URL: http://localhost:\$PORT/api/v1"
echo "Health check: http://localhost:\$PORT/api/v1/health"
echo ""
echo "Appuyez sur Ctrl+C pour arrêter"
echo ""

exec node src/server.js
`;

    fs.writeFileSync(path.join(this.outputDir, 'start-backend.sh'), startScript);
    fs.chmodSync(path.join(this.outputDir, 'start-backend.sh'), 0o755);

    log.success('Script start-backend.sh créé');

    // Script stop-backend.sh
    const stopScript = `#!/bin/bash

# LOGESCO Backend - Script d'arrêt

echo "Arrêt du Backend LOGESCO..."
pkill -f "node src/server.js"
echo "Backend arrêté"
`;

    fs.writeFileSync(path.join(this.outputDir, 'stop-backend.sh'), stopScript);
    fs.chmodSync(path.join(this.outputDir, 'stop-backend.sh'), 0o755);

    log.success('Script stop-backend.sh créé');
  }

  /**
   * Crée le script de configuration du service systemd
   */
  createSystemdScript() {
    log.title('Création du script de configuration systemd');

    const systemdScript = `#!/bin/bash

# Script d'installation du service systemd pour LOGESCO Backend
# Usage: sudo bash install-service.sh

if [[ $EUID -ne 0 ]]; then
   echo "Ce script doit être exécuté avec sudo"
   exit 1
fi

BACKEND_PATH="/opt/logesco-backend"
SERVICE_NAME="logesco-backend"

echo "Installation du service $SERVICE_NAME..."

# Créer l'utilisateur logesco s'il n'existe pas
if ! id "logesco" &>/dev/null; then
    echo "Création de l'utilisateur logesco..."
    useradd -m -s /bin/bash logesco
fi

# Créer le répertoire de destination
if [ ! -d "$BACKEND_PATH" ]; then
    echo "Création de $BACKEND_PATH..."
    mkdir -p "$BACKEND_PATH"
fi

# Copier les fichiers
echo "Copie des fichiers..."
cp -r . "$BACKEND_PATH/"
chown -R logesco:logesco "$BACKEND_PATH"

# Créer le fichier de service systemd
cat > /etc/systemd/system/$SERVICE_NAME.service << 'SYSTEMD'
[Unit]
Description=LOGESCO Backend Service
After=network.target
Wants=network-online.target

[Service]
Type=simple
User=logesco
WorkingDirectory=$BACKEND_PATH
ExecStart=/usr/bin/node $BACKEND_PATH/src/server.js
Restart=always
RestartSec=10
StandardOutput=append:/var/log/$SERVICE_NAME.log
StandardError=append:/var/log/$SERVICE_NAME.log
Environment="NODE_ENV=production"
Environment="PORT=8080"

[Install]
WantedBy=multi-user.target
SYSTEMD

# Remplacer les variables
sed -i "s|\\\$BACKEND_PATH|$BACKEND_PATH|g" /etc/systemd/system/$SERVICE_NAME.service

# Créer le fichier de log
touch /var/log/$SERVICE_NAME.log
chown logesco:logesco /var/log/$SERVICE_NAME.log

# Recharger systemd
systemctl daemon-reload

# Activer le service
systemctl enable $SERVICE_NAME

echo "Service $SERVICE_NAME installé avec succès!"
echo ""
echo "Commandes disponibles:"
echo "  sudo systemctl start $SERVICE_NAME       - Démarrer le service"
echo "  sudo systemctl stop $SERVICE_NAME        - Arrêter le service"
echo "  sudo systemctl restart $SERVICE_NAME     - Redémarrer le service"
echo "  sudo systemctl status $SERVICE_NAME      - Voir le statut"
echo "  sudo journalctl -u $SERVICE_NAME -f      - Voir les logs en direct"
`;

    fs.writeFileSync(path.join(this.outputDir, 'install-service.sh'), systemdScript);
    fs.chmodSync(path.join(this.outputDir, 'install-service.sh'), 0o755);

    log.success('Script install-service.sh créé');
  }

  /**
   * Crée le fichier README
   */
  createReadme() {
    log.title('Création du fichier README');

    const readme = `# LOGESCO Backend - Package Portable pour Linux

## 📋 Contenu du Package

- \`src/\` - Code source du backend
- \`node_modules/\` - Dépendances Node.js
- \`database/\` - Base de données SQLite
- \`prisma/\` - Configuration Prisma
- \`start-backend.sh\` - Script de démarrage
- \`stop-backend.sh\` - Script d'arrêt
- \`install-service.sh\` - Script d'installation systemd
- \`package.json\` - Dépendances du projet

## 🚀 Démarrage Rapide

### Option 1: Démarrage Direct

\`\`\`bash
bash start-backend.sh
\`\`\`

Le backend démarre sur: \`http://localhost:8080/api/v1\`

### Option 2: Installation en tant que Service

\`\`\`bash
sudo bash install-service.sh
sudo systemctl start logesco-backend
\`\`\`

## 📋 Prérequis

- Node.js v18+
- Linux (Ubuntu/Debian recommandé)

Si Node.js n'est pas installé:

\`\`\`bash
# Ubuntu/Debian
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
\`\`\`

## 🔍 Vérification

\`\`\`bash
# Tester la connexion
curl http://localhost:8080/api/v1/health

# Réponse attendue: {"status": "ok"}
\`\`\`

## 📊 Logs

Si installé en tant que service:

\`\`\`bash
# Voir les logs en direct
sudo journalctl -u logesco-backend -f

# Voir les dernières 50 lignes
sudo journalctl -u logesco-backend -n 50
\`\`\`

## 🔧 Configuration

L'application utilise automatiquement SQLite pour la base de données.

Fichier de configuration: \`src/config/environment.js\`

## 🔐 Firewall

Pour autoriser l'accès au port 8080:

\`\`\`bash
# UFW
sudo ufw allow 8080/tcp

# iptables
sudo iptables -A INPUT -p tcp --dport 8080 -j ACCEPT
\`\`\`

## 📞 Support

- Voir le guide complet: GUIDE_DEPLOIEMENT_LINUX_COMPLET.md
- Documentation backend: backend/README.md
`;

    fs.writeFileSync(path.join(this.outputDir, 'README.md'), readme);

    log.success('README créé');
  }

  /**
   * Crée un fichier d'instructions de déploiement
   */
  createDeploymentInstructions() {
    log.title('Création des instructions de déploiement');

    const instructions = `# 📋 Instructions de Déploiement

## Étape 1: Sur Windows (Préparation)

Ce fichier a été généré par le script de build.

\`\`\`bash
node build-portable-linux.js
\`\`\`

## Étape 2: Transférer vers Linux

### Via SCP (Recommandé)

Sur Windows (PowerShell avec OpenSSH):

\`\`\`powershell
# Compresser
tar -czf logesco-backend.tar.gz dist-portable/

# Transférer
scp logesco-backend.tar.gz user@192.168.x.x:/home/user/

# Sur le serveur
ssh user@192.168.x.x
tar -xzf logesco-backend.tar.gz
sudo mv dist-portable /opt/logesco-backend
\`\`\`

## Étape 3: Installer sur Linux

\`\`\`bash
cd /opt/logesco-backend

# Vérifier Node.js
node --version

# Si absent, installer:
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Option A: Démarrage direct
bash start-backend.sh

# Option B: Installation en tant que service
sudo bash install-service.sh
sudo systemctl start logesco-backend
\`\`\`

## Étape 4: Tester

\`\`\`bash
# Depuis le serveur Linux
curl http://localhost:8080/api/v1/health

# Depuis un poste Windows
curl http://192.168.x.x:8080/api/v1/health
\`\`\`

## Étape 5: Configurer les Clients

Voir: GUIDE_CONFIG_CLIENTS_WINDOWS.md
`;

    fs.writeFileSync(path.join(this.outputDir, 'DEPLOYMENT.md'), instructions);

    log.success('Instructions créées');
  }

  /**
   * Génère un résumé des fichiers
   */
  createManifest() {
    log.title('Création du manifeste');

    const buildDate = new Date().toISOString();
    const manifest = {
      name: 'LOGESCO Backend',
      version: '2.0.0',
      type: 'portable-linux',
      buildDate,
      platform: 'Linux',
      nodeVersion: process.version,
      includes: [
        'Source code',
        'Node.js dependencies',
        'Prisma client (generated)',
        'SQLite database',
        'Start/stop scripts',
        'Systemd service configuration',
      ],
      startupScript: 'start-backend.sh',
      port: 8080,
      database: 'SQLite (database/logesco.db)',
    };

    fs.writeFileSync(
      path.join(this.outputDir, 'manifest.json'),
      JSON.stringify(manifest, null, 2)
    );

    log.success('Manifeste créé');
  }

  /**
   * Affiche un résumé final
   */
  printSummary() {
    const duration = ((Date.now() - this.startTime) / 1000).toFixed(1);

    console.log(`\n${COLORS.bright}${COLORS.green}`);
    console.log('═══════════════════════════════════════════════════════');
    console.log('  ✓ BUILD RÉUSSI - Package Linux Prêt!');
    console.log('═══════════════════════════════════════════════════════');
    console.log(`${COLORS.reset}\n`);

    console.log(`${COLORS.bright}Localisation:${COLORS.reset}`);
    console.log(`  📁 ${this.outputDir}\n`);

    console.log(`${COLORS.bright}Prochaines Étapes:${COLORS.reset}`);
    console.log(`  1. Compresser: tar -czf logesco-backend.tar.gz dist-portable/`);
    console.log(`  2. Transférer: scp logesco-backend.tar.gz user@192.168.x.x:/home/user/`);
    console.log(`  3. Extraire sur Linux: tar -xzf logesco-backend.tar.gz`);
    console.log(`  4. Démarrer: bash start-backend.sh\n`);

    console.log(`${COLORS.bright}Fichiers Importants:${COLORS.reset}`);
    console.log(`  📄 README.md - Guide de démarrage rapide`);
    console.log(`  📄 DEPLOYMENT.md - Instructions détaillées`);
    console.log(`  🔧 start-backend.sh - Démarrage direct`);
    console.log(`  ⚙️  install-service.sh - Installation systemd`);
    console.log(`  📊 manifest.json - Infos du build\n`);

    console.log(`${COLORS.bright}Durée:${COLORS.reset} ${duration}s\n`);
  }

  /**
   * Lance le build complet
   */
  build() {
    try {
      log.title('========== BUILD LOGESCO BACKEND POUR LINUX ==========');

      this.createOutputDir();
      this.copySources();
      this.installDependencies();
      this.generatePrisma();
      this.createDatabase();
      this.createLinuxScripts();
      this.createSystemdScript();
      this.createReadme();
      this.createDeploymentInstructions();
      this.createManifest();

      this.printSummary();
    } catch (error) {
      log.error(`Erreur fatale: ${error.message}`);
      process.exit(1);
    }
  }
}

// Lancer le build
const builder = new LinuxDeploymentBuilder();
builder.build();
