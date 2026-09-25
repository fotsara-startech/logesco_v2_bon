/**
 * Script de vérification du système de migration automatique.
 * Contrôle que MIGRATION_ORDER (migration-runner.js) correspond exactement
 * aux dossiers présents dans prisma/migrations — la source unique de vérité
 * appliquée aux postes clients.
 */

const fs = require('fs');
const path = require('path');

console.log('╔══════════════════════════════════════════════════════════════╗');
console.log('║  Vérification du Système de Migration Automatique LOGESCO   ║');
console.log('╚══════════════════════════════════════════════════════════════╝\n');

const checks = { total: 0, passed: 0, failed: 0 };

function check(name, condition, successMsg, failMsg) {
  checks.total++;
  if (condition) {
    checks.passed++;
    console.log(`✅ ${name}: ${successMsg}`);
  } else {
    checks.failed++;
    console.error(`❌ ${name}: ${failMsg}`);
  }
  return condition;
}

// 1. Le runner existe et se charge
let migrationRunner;
try {
  migrationRunner = require('./src/services/migration-runner');
  check('Chargement du module', true, 'src/services/migration-runner.js chargé sans erreur');
} catch (error) {
  check('Chargement du module', false, '', `Erreur: ${error.message}`);
  process.exit(1);
}

// 2. Chaque entrée de MIGRATION_ORDER a bien un dossier + migration.sql
const migrationsDir = path.join(__dirname, 'prisma', 'migrations');
const missing = migrationRunner.MIGRATION_ORDER.filter(
  (name) => !fs.existsSync(path.join(migrationsDir, name, 'migration.sql'))
);
check(
  'MIGRATION_ORDER ↔ fichiers',
  missing.length === 0,
  `${migrationRunner.MIGRATION_ORDER.length} migration(s) toutes présentes sur disque`,
  `migration.sql manquant pour: ${missing.join(', ')}`
);

// 3. Aucun dossier de migration sur disque n'est absent du manifest
//    (sinon il ne sera jamais appliqué aux postes clients)
const onDisk = fs.readdirSync(migrationsDir).filter((entry) => {
  const full = path.join(migrationsDir, entry);
  return fs.statSync(full).isDirectory() && fs.existsSync(path.join(full, 'migration.sql'));
});
const notInManifest = onDisk.filter((name) => !migrationRunner.MIGRATION_ORDER.includes(name));
check(
  'Fichiers ↔ MIGRATION_ORDER',
  notInManifest.length === 0,
  'Tous les dossiers migration.sql sont référencés dans MIGRATION_ORDER',
  `Dossier(s) présents sur disque mais absents de MIGRATION_ORDER (jamais appliqués aux clients !): ${notInManifest.join(', ')}`
);

// 4. server.js appelle bien le runner
const serverPath = path.join(__dirname, 'src', 'server.js');
if (fs.existsSync(serverPath)) {
  const serverContent = fs.readFileSync(serverPath, 'utf8');
  check(
    "Appel migrationRunner.run()",
    serverContent.includes("require('./services/migration-runner')") &&
      serverContent.includes('migrationRunner.run('),
    'Appelé dans start()',
    'Non appelé dans start() — les migrations ne seront jamais rattrapées'
  );
} else {
  check('Server.js', false, '', 'Fichier server.js manquant');
}

// 5. L'installeur livre bien prisma/migrations/ chez le client
//    (sans ça, tout ce qui précède est vérifié... mais jamais présent sur
//    le poste client : c'est exactement le bug qui a cassé la migration
//    commerciaux/parametres chez plusieurs clients.)
const installerPath = path.join(__dirname, '..', 'installer-setup.iss');
if (fs.existsSync(installerPath)) {
  const installerContent = fs.readFileSync(installerPath, 'utf8');
  check(
    'Installeur ↔ prisma/migrations',
    /prisma\\migrations\\\*/i.test(installerContent),
    'installer-setup.iss copie bien prisma\\migrations\\* chez le client',
    "installer-setup.iss ne copie PAS prisma\\migrations\\* — aucune migration ne pourra jamais s'appliquer sur un poste client !"
  );
} else {
  check('Installeur', false, '', 'installer-setup.iss introuvable (chemin attendu : ../installer-setup.iss)');
}

// Résumé
console.log('\n╔══════════════════════════════════════════════════════════════╗');
console.log('║                         RÉSUMÉ                               ║');
console.log('╚══════════════════════════════════════════════════════════════╝');
console.log(`Total de vérifications : ${checks.total}`);
console.log(`✅ Réussies            : ${checks.passed}`);
console.log(`❌ Échouées            : ${checks.failed}`);

if (checks.failed === 0) {
  console.log('\n🎉 Système de migration automatique opérationnel.');
  process.exit(0);
} else {
  console.log('\n⚠️  Corrigez les erreurs ci-dessus avant de livrer une nouvelle version.');
  process.exit(1);
}
