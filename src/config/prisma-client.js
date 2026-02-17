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
      log: process.env.NODE_ENV === 'development' ? ['error'] : ['error']
    });
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
