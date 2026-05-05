const { PrismaClient } = require('@prisma/client');
const p = new PrismaClient();

async function check() {
  // Vérifier avec Prisma
  const prod = await p.$queryRawUnsafe(
    'SELECT id, reference, prix_unitaire, nom FROM produits WHERE id = 1033'
  );
  console.log('SQLite raw:', JSON.stringify(prod, null, 2));
  
  // Aussi vérifier via Prisma ORM
  const prod2 = await p.produit.findUnique({ where: { id: 1033 }, select: { id: true, prixUnitaire: true, reference: true } });
  console.log('Prisma ORM:', JSON.stringify(prod2, null, 2));
  
  await p.$disconnect();
}

check().catch(console.error);
