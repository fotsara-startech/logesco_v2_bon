const { PrismaClient } = require('@prisma/client');

/**
 * Script d'initialisation pour les licences
 * Crée les données de base nécessaires
 */
async function initializeLicenseData() {
  const prisma = new PrismaClient();

  try {
    console.log(' Initialisation des données de licences...');

    // Vérifier si des licences existent déjà
    const existingLicenses = await prisma.license.count();
    
    if (existingLicenses > 0) {
      console.log(  licence(s) déjà présente(s) dans la base de données);
      return;
    }

    console.log(' Aucune licence trouvée, initialisation terminée');
    console.log(' Base de données des licences prête');

  } catch (error) {
    console.error(' Erreur lors de l\'initialisation des licences:', error);
    throw error;
  } finally {
    await prisma.();
  }
}

// Exécuter si appelé directement
if (require.main === module) {
  initializeLicenseData()
    .then(() => {
      console.log(' Initialisation des licences terminée avec succès');
      process.exit(0);
    })
    .catch((error) => {
      console.error(' Erreur fatale:', error);
      process.exit(1);
    });
}

module.exports = { initializeLicenseData };
