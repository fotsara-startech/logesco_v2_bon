/**
 * Chargeur Prisma compatible avec pkg
 * Utilise module.createRequire pour bypasser le snapshot pkg
 * et charger @prisma/client depuis le filesystem réel.
 */

const path = require('path');
const fs   = require('fs');
const { createRequire } = require('module');

const isPkg = typeof process.pkg !== 'undefined';

function loadPrismaClient() {
  if (isPkg) {
    // En mode pkg, require() normal est intercepté par le snapshot.
    // createRequire avec un chemin filesystem réel bypasse ça.
    const exeDir = path.dirname(process.execPath);
    const prismaClientPath = path.join(exeDir, 'node_modules', '@prisma', 'client');

    if (!fs.existsSync(prismaClientPath)) {
      throw new Error(
        `Prisma Client introuvable dans: ${prismaClientPath}\n` +
        `Assurez-vous que node_modules/@prisma/client est present a cote de l'executable.`
      );
    }

    // Créer un require ancré dans le dossier de l'exe (filesystem réel)
    const requireFromExe = createRequire(path.join(exeDir, 'dummy.js'));
    const { PrismaClient } = requireFromExe('@prisma/client');
    return PrismaClient;
  } else {
    const { PrismaClient } = require('@prisma/client');
    return PrismaClient;
  }
}

module.exports = { loadPrismaClient };
