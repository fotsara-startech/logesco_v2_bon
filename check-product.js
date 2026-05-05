const { PrismaClient } = require('@prisma/client');
const p = new PrismaClient();

p.produit.findUnique({
  where: { id: 1033 },
  select: { id: true, reference: true, prixUnitaire: true, nom: true }
}).then(r => {
  console.log(JSON.stringify(r, null, 2));
  return p.$disconnect();
});
