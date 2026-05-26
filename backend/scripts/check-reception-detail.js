require('dotenv').config();
const { PrismaClient } = require('../src/config/prisma-client');
const prisma = new PrismaClient();

async function check() {
  // Mouvements pour les produits des commandes récentes
  const produitIds = [721, 717, 712, 1028];
  
  for (const produitId of produitIds) {
    const mvts = await prisma.mouvementStock.findMany({
      where: { produitId, typeMouvement: 'achat' },
      orderBy: { dateMouvement: 'desc' },
      take: 3
    });
    
    const sb = await prisma.stockBoutique.findMany({ where: { produitId } });
    
    console.log(`\nProduit ${produitId}:`);
    console.log('  Mouvements achat:', mvts.map(m => ({ id: m.id, qte: m.changementQuantite, date: m.dateMouvement.toISOString().split('T')[0], ref: m.referenceId })));
    console.log('  stock_boutiques:', sb.map(s => ({ boutiqueId: s.boutiqueId, qte: s.quantiteDisponible, maj: s.derniereMaj.toISOString().split('T')[0] })));
  }

  // Vérifier les commandes 119-123 et leurs détails
  console.log('\n\nDétails commandes 119-123:');
  const commandes = await prisma.commandeApprovisionnement.findMany({
    where: { id: { in: [119, 120, 121, 122, 123] } },
    include: { details: true }
  });
  
  for (const c of commandes) {
    console.log(`\nCommande ${c.numeroCommande} (boutiqueId: ${c.boutiqueId}):`);
    for (const d of c.details) {
      console.log(`  Detail ID ${d.id}: produit ${d.produitId}, commandé ${d.quantiteCommandee}, reçu ${d.quantiteRecue}`);
      
      // Chercher le mouvement correspondant
      const mvt = await prisma.mouvementStock.findFirst({
        where: { referenceId: c.id, produitId: d.produitId, typeMouvement: 'achat' }
      });
      console.log(`  Mouvement trouvé:`, mvt ? `ID ${mvt.id}, qte +${mvt.changementQuantite}` : 'AUCUN');
    }
  }

  await prisma.$disconnect();
}

check().catch(e => { console.error(e.message); process.exit(1); });
