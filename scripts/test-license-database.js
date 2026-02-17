const { PrismaClient } = require('@prisma/client');
const LicenseService = require('../src/services/license');

const prisma = new PrismaClient();
const licenseService = new LicenseService(prisma);

/**
 * Test de la base de données des licences
 */
async function testLicenseDatabase() {
  console.log(' Test de la base de données des licences...\n');

  try {
    // Test 1: Génération d'une licence
    console.log('1. Test de génération de licence...');
    const licenseData = {
      userId: 'user123',
      subscriptionType: 'monthly',
      deviceFingerprint: 'device-abc-123',
      expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 jours
      metadata: {
        plan: 'premium',
        features: ['analytics', 'export']
      }
    };

    const newLicense = await licenseService.generateLicense(licenseData);
    console.log(' Licence générée:', newLicense.licenseKey);

    // Test 2: Validation de la licence
    console.log('\n2. Test de validation de licence...');
    const validation = await licenseService.validateLicense(
      newLicense.licenseKey, 
      'device-abc-123'
    );
    console.log(' Validation:', validation.isValid ? 'VALIDE' : 'INVALIDE');

    // Test 3: Révocation de licence
    console.log('\n3. Test de révocation de licence...');
    await licenseService.revokeLicense(
      newLicense.licenseKey, 
      'Test de révocation',
      'TEST_USER'
    );
    console.log(' Licence révoquée');

    // Test 4: Validation après révocation
    console.log('\n4. Test de validation après révocation...');
    const validationAfterRevoke = await licenseService.validateLicense(
      newLicense.licenseKey, 
      'device-abc-123'
    );
    console.log(' Validation après révocation:', validationAfterRevoke.isValid ? 'VALIDE' : 'INVALIDE');
    console.log('   Erreurs:', validationAfterRevoke.errors);

    // Test 5: Statistiques
    console.log('\n5. Test des statistiques...');
    const stats = await licenseService.getLicenseStats();
    console.log(' Statistiques:', JSON.stringify(stats, null, 2));

    console.log('\n Tous les tests sont passés avec succès!');

  } catch (error) {
    console.error(' Erreur lors des tests:', error.message);
    console.error(error.stack);
  } finally {
    await prisma.$disconnect();
  }
}

// Exécuter les tests
if (require.main === module) {
  testLicenseDatabase();
}

module.exports = testLicenseDatabase;
