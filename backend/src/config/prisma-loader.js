/**
 * Chargeur Prisma compatible avec pkg
 * Charge Prisma depuis le système de fichiers au lieu du snapshot
 */

const path = require('path');
const fs = require('fs');

// Détecte si on est en mode pkg
const isPkg = typeof process.pkg !== 'undefined';

/**
 * Charge PrismaClient de manière compatible avec pkg
 * @returns {Object} PrismaClient
 */
function loadPrismaClient() {
  if (isPkg) {
    // En mode pkg, charger Prisma depuis le dossier à côté de l'exe
    const exeDir = path.dirname(process.execPath);
    const prismaClientPath = path.join(exeDir, 'node_modules', '@prisma', 'client');
    
    // Vérifier si le dossier existe
    if (!fs.existsSync(prismaClientPath)) {
      throw new Error(
        `Prisma Client introuvable dans: ${prismaClientPath}\n` +
        `Assurez-vous que le dossier node_modules/@prisma/client est présent à côté de l'exécutable.`
      );
    }
    
    // Charger depuis le chemin absolu
    const { PrismaClient } = require(prismaClientPath);
    return PrismaClient;
  } else {
    // En mode développement, charger normalement
    const { PrismaClient } = require('@prisma/client');
    return PrismaClient;
  }
}

module.exports = { loadPrismaClient };
