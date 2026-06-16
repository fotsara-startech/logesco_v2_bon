/**
 * Client Prisma singleton compatible avec pkg
 * Utilise ce module au lieu d'importer directement @prisma/client
 */

const { loadPrismaClient } = require('./prisma-loader');

// Charger PrismaClient une seule fois
const PrismaClient = loadPrismaClient();

// Instance singleton
let prismaInstance = null;

/**
 * Obtenir l'instance Prisma (singleton)
 * @returns {PrismaClient}
 */
function getPrismaClient() {
  if (!prismaInstance) {
    prismaInstance = new PrismaClient({
      log: [] // Désactiver tous les logs Prisma (erreurs interceptées par catch)
    });
    
    // Activer les hooks de synchronisation APRÈS la création de l'instance
    // Les hooks seront activés lors du premier appel à cette fonction
    if (process.env.CLOUD_DB_URL) {
      try {
        const { setupPrismaSyncHooks } = require('../middleware/prisma-sync-hooks');
        setupPrismaSyncHooks(prismaInstance);
      } catch (error) {
        console.error('❌ Erreur lors de l\'activation des hooks de sync:', error.message);
      }
    }
  }
  return prismaInstance;
}

/**
 * Créer une nouvelle instance Prisma (pour les tests ou cas spéciaux)
 * @param {Object} options - Options Prisma
 * @returns {PrismaClient}
 */
function createPrismaClient(options = {}) {
  return new PrismaClient(options);
}

module.exports = {
  PrismaClient,
  getPrismaClient,
  createPrismaClient,
  // Export par défaut pour compatibilité
  default: { PrismaClient }
};
