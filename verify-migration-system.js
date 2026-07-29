/**
 * Script de vérification du système de migration automatique
 */

const fs = require('fs');
const path = require('path');

console.log('╔══════════════════════════════════════════════════════════════╗');
console.log('║  Vérification du Système de Migration Automatique LOGESCO   ║');
console.log('╚══════════════════════════════════════════════════════════════╝\n');

const checks = {
  total: 0,
  passed: 0,
  failed: 0
};

function check(name, condition, successMsg, failMsg) {
  checks.total++;
  if (condition) {
    checks.passed++;
    console.log(`✅ ${name}: ${successMsg}`);
    return true;
  } else {
    checks.failed++;
    console.error(`❌ ${name}: ${failMsg}`);
    return false;
  }
}

// 1. Vérifier que schema-validator.js existe
const validatorPath = path.join(__dirname, 'src', 'utils', 'schema-validator.js');
check(
  'Schema Validator',
  fs.existsSync(validatorPath),
  'Fichier trouvé',
  'Fichier manquant : src/utils/schema-validator.js'
);

// 2. Vérifier que server.js contient _validateSchema
const serverPath = path.join(__dirname, 'src', 'server.js');
if (fs.existsSync(serverPath)) {
  const serverContent = fs.readFileSync(serverPath, 'utf8');
  check(
    'Méthode _validateSchema',
    serverContent.includes('_validateSchema'),
    'Méthode présente dans server.js',
    'Méthode manquante dans server.js'
  );
  
  check(
    'Appel _validateSchema',
    serverContent.includes('await this._validateSchema(prisma)'),
    'Appelée dans start()',
    'Non appelée dans start()'
  );
} else {
  check('Server.js', false, '', 'Fichier server.js manquant');
}

// 3. Vérifier que le test existe
const testPath = path.join(__dirname, 'test-schema-validator.js');
check(
  'Script de test',
  fs.existsSync(testPath),
  'test-schema-validator.js trouvé',
  'Script de test manquant'
);

// 4. Vérifier la documentation
const docsPath = path.join(__dirname, 'MIGRATIONS.md');
check(
  'Documentation',
  fs.existsSync(docsPath),
  'MIGRATIONS.md trouvé',
  'Documentation manquante'
);

const quickStartPath = path.join(__dirname, 'QUICK_START_MIGRATIONS.md');
check(
  'Guide rapide',
  fs.existsSync(quickStartPath),
  'QUICK_START_MIGRATIONS.md trouvé',
  'Guide rapide manquant'
);

// 5. Vérifier le backend embarqué
const embeddedBackend = path.join(
  process.env.LOCALAPPDATA,
  'LOGESCO',
  'backend'
);

if (fs.existsSync(embeddedBackend)) {
  const embeddedValidator = path.join(embeddedBackend, 'src', 'utils', 'schema-validator.js');
  check(
    'Backend embarqué - Validator',
    fs.existsSync(embeddedValidator),
    'Copié dans backend embarqué',
    'Pas encore copié (exécuter: Copy-Item backend\\src\\utils\\schema-validator.js $env:LOCALAPPDATA\\LOGESCO\\backend\\src\\utils\\'
  );
  
  const embeddedServer = path.join(embeddedBackend, 'src', 'server.js');
  if (fs.existsSync(embeddedServer)) {
    const embeddedServerContent = fs.readFileSync(embeddedServer, 'utf8');
    check(
      'Backend embarqué - Server',
      embeddedServerContent.includes('_validateSchema'),
      'Méthode présente dans backend embarqué',
      'server.js du backend embarqué non mis à jour'
    );
  }
} else {
  console.log('ℹ️  Backend embarqué non installé (normal en développement)');
}

// 6. Test de chargement du module
try {
  const SchemaValidator = require('./src/utils/schema-validator');
  check(
    'Chargement du module',
    typeof SchemaValidator === 'function',
    'Module chargeable sans erreur',
    'Erreur lors du chargement'
  );
  
  // Vérifier les méthodes essentielles
  const validator = new SchemaValidator(null);
  check(
    'Méthodes du validateur',
    typeof validator.validateAndFix === 'function' &&
    typeof validator.quickValidate === 'function' &&
    typeof validator.getRequiredSchema === 'function',
    'Toutes les méthodes présentes',
    'Méthodes manquantes'
  );
} catch (error) {
  check('Chargement du module', false, '', `Erreur: ${error.message}`);
}

// Résumé
console.log('\n╔══════════════════════════════════════════════════════════════╗');
console.log('║                         RÉSUMÉ                               ║');
console.log('╚══════════════════════════════════════════════════════════════╝');
console.log(`Total de vérifications : ${checks.total}`);
console.log(`✅ Réussies            : ${checks.passed}`);
console.log(`❌ Échouées            : ${checks.failed}`);

if (checks.failed === 0) {
  console.log('\n🎉 Système de migration automatique opérationnel !');
  console.log('\n📖 Prochaines étapes :');
  console.log('   1. Tester : node backend/test-schema-validator.js');
  console.log('   2. Lire : backend/QUICK_START_MIGRATIONS.md');
  console.log('   3. Déployer sur backend embarqué si nécessaire');
  process.exit(0);
} else {
  console.log('\n⚠️  Certaines vérifications ont échoué.');
  console.log('   Corrigez les erreurs ci-dessus avant de continuer.');
  process.exit(1);
}
