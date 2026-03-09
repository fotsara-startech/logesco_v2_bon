/**
 * Script de test pour vérifier la sauvegarde du logo et slogan
 */

const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function testLogoSlogan() {
  console.log('========================================');
  console.log('Test: Sauvegarde Logo et Slogan');
  console.log('========================================');
  console.log('');

  try {
    // 1. Récupérer les paramètres actuels
    console.log('1. Récupération des paramètres actuels...');
    let settings = await prisma.parametresEntreprise.findFirst();
    
    if (!settings) {
      console.log('⚠️  Aucun paramètre trouvé, création...');
      settings = await prisma.parametresEntreprise.create({
        data: {
          nomEntreprise: 'Test Entreprise',
          adresse: 'Test Adresse',
          localisation: 'Test Ville',
          telephone: '123456789',
          email: 'test@test.com',
          nuiRccm: 'TEST123',
          logo: null,
          slogan: null
        }
      });
      console.log('✅ Paramètres créés');
    } else {
      console.log('✅ Paramètres trouvés');
      console.log('   - Nom:', settings.nomEntreprise);
      console.log('   - Logo actuel:', settings.logo || 'NULL');
      console.log('   - Slogan actuel:', settings.slogan || 'NULL');
    }

    console.log('');

    // 2. Mettre à jour avec un slogan
    console.log('2. Mise à jour avec un slogan de test...');
    const updatedSettings = await prisma.parametresEntreprise.update({
      where: { id: settings.id },
      data: {
        slogan: 'Votre satisfaction, notre priorité - TEST'
      }
    });

    console.log('✅ Slogan mis à jour');
    console.log('   - Nouveau slogan:', updatedSettings.slogan);

    console.log('');

    // 3. Vérifier la sauvegarde
    console.log('3. Vérification de la sauvegarde...');
    const verifySettings = await prisma.parametresEntreprise.findFirst({
      where: { id: settings.id }
    });

    if (verifySettings.slogan === 'Votre satisfaction, notre priorité - TEST') {
      console.log('✅ Slogan correctement sauvegardé en base de données');
    } else {
      console.log('❌ ERREUR: Le slogan n\'a pas été sauvegardé correctement');
      console.log('   - Attendu: "Votre satisfaction, notre priorité - TEST"');
      console.log('   - Reçu:', verifySettings.slogan);
    }

    console.log('');

    // 4. Tester avec un logo
    console.log('4. Mise à jour avec un chemin de logo...');
    const withLogo = await prisma.parametresEntreprise.update({
      where: { id: settings.id },
      data: {
        logo: '/uploads/logos/test-logo.png'
      }
    });

    console.log('✅ Logo mis à jour');
    console.log('   - Nouveau logo:', withLogo.logo);

    console.log('');

    // 5. Afficher le résultat final
    console.log('5. État final des paramètres:');
    const finalSettings = await prisma.parametresEntreprise.findFirst({
      where: { id: settings.id }
    });

    console.log('   - Nom:', finalSettings.nomEntreprise);
    console.log('   - Adresse:', finalSettings.adresse);
    console.log('   - Logo:', finalSettings.logo || 'NULL');
    console.log('   - Slogan:', finalSettings.slogan || 'NULL');

    console.log('');
    console.log('========================================');
    console.log('✅ Test terminé avec succès!');
    console.log('========================================');

  } catch (error) {
    console.error('');
    console.error('========================================');
    console.error('❌ ERREUR lors du test');
    console.error('========================================');
    console.error('');
    console.error('Message:', error.message);
    console.error('Stack:', error.stack);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

// Exécuter le test
testLogoSlogan()
  .then(() => {
    console.log('');
    console.log('Le backend peut maintenant sauvegarder le logo et le slogan.');
    console.log('Testez maintenant depuis l\'application Flutter.');
    console.log('');
    process.exit(0);
  })
  .catch((error) => {
    console.error('Erreur fatale:', error);
    process.exit(1);
  });
