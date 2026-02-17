/**
 * Démarre le backend LOGESCO comme un service Windows
 * Utilise node-windows pour créer un vrai service Windows
 */

const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs');

console.log('🚀 Démarrage du backend LOGESCO en mode service...\n');

// Créer le dossier database si nécessaire
const dbPath = path.join(__dirname, 'database');
if (!fs.existsSync(dbPath)) {
  fs.mkdirSync(dbPath, { recursive: true });
  console.log('✅ Dossier database créé');
}

// Vérifier si Prisma client est généré
const prismaClientPath = path.join(__dirname, 'node_modules', '.prisma', 'client');
const needsGenerate = !fs.existsSync(prismaClientPath);

// Vérifier si la base de données existe
const dbFile = path.join(dbPath, 'logesco.db');
const needsDbPush = !fs.existsSync(dbFile);

// Fonction pour exécuter une commande
function runCommand(command, args, description) {
  return new Promise((resolve, reject) => {
    console.log(`⏳ ${description}...`);
    const proc = spawn(command, args, {
      cwd: __dirname,
      stdio: 'pipe',
      shell: true
    });

    let output = '';
    proc.stdout.on('data', (data) => {
      output += data.toString();
    });

    proc.stderr.on('data', (data) => {
      output += data.toString();
    });

    proc.on('close', (code) => {
      if (code === 0) {
        console.log(`✅ ${description} terminé`);
        resolve();
      } else {
        console.error(`❌ ${description} échoué (code ${code})`);
        console.error(output);
        reject(new Error(`${description} failed`));
      }
    });
  });
}

// Initialisation asynchrone
async function initialize() {
  try {
    // Générer Prisma client si nécessaire
    if (needsGenerate) {
      await runCommand('npx', ['prisma', 'generate'], 'Génération Prisma Client');
    } else {
      console.log('✅ Prisma Client déjà généré');
    }

    // Créer la base de données si nécessaire
    if (needsDbPush) {
      await runCommand('npx', ['prisma', 'db', 'push', '--accept-data-loss', '--skip-generate'], 'Création base de données');
    } else {
      console.log('✅ Base de données déjà présente');
    }

    console.log('\n🎯 Démarrage du serveur...\n');

    // Démarrer le serveur
    const server = spawn('node', ['src/server.js'], {
      cwd: __dirname,
      stdio: 'inherit',
      shell: true,
      detached: false
    });

    // Gérer l'arrêt propre
    process.on('SIGINT', () => {
      console.log('\n📨 Arrêt du serveur...');
      server.kill('SIGTERM');
      process.exit(0);
    });

    process.on('SIGTERM', () => {
      console.log('\n📨 Arrêt du serveur...');
      server.kill('SIGTERM');
      process.exit(0);
    });

    server.on('exit', (code) => {
      console.log(`\n🛑 Serveur arrêté (code ${code})`);
      process.exit(code);
    });

  } catch (error) {
    console.error('\n❌ Erreur lors de l\'initialisation:', error.message);
    process.exit(1);
  }
}

// Lancer l'initialisation
initialize();
