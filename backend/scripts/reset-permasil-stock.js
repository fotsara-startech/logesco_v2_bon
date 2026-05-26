require('dotenv').config();
const { PrismaClient } = require('../src/config/prisma-client');
const prisma = new PrismaClient();

async function run() {
  // Remettre stock Permasil à 0 pour tester proprement
  await prisma.$executeRawUnsafe(
    'UPDATE stock_boutiques SET quantite_disponible = 0 WHERE boutique_id = 7 AND produit_id = 724'
  );
  // Supprimer le mouvement de test
  await prisma.$executeRawUnsafe(
    'DELETE FROM mouvements_stock WHERE id = 1042'
  );
  // Remettre la commande en attente pour pouvoir retester
  await prisma.$executeRawUnsafe(
    'UPDATE commandes_approvisionnement SET statut = ? WHERE id = 127', 'en_attente'
  );
  await prisma.$executeRawUnsafe(
    'UPDATE details_commandes_approvisionnement SET quantite_recue = 0 WHERE id = 268'
  );
  console.log('✅ Stock Permasil remis à 0, commande 127 remise en attente');
  await prisma.$disconnect();
}
run().catch(e => { console.error(e.message); process.exit(1); });
