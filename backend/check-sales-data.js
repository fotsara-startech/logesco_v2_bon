/**
 * Script pour vérifier les données des ventes
 */

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function checkSalesData() {
  try {
    console.log('🔍 Vérification des données de ventes...\n');
    
    // Récupérer les 10 dernières ventes
    const ventes = await prisma.vente.findMany({
      orderBy: { dateVente: 'desc' },
      take: 10,
      include: {
        client: true
      }
    });
    
    console.log(`✅ ${ventes.length} vente(s) trouvée(s)\n`);
    
    for (const vente of ventes) {
      console.log(`📋 Vente ${vente.numeroVente}:`);
      console.log(`   ID: ${vente.id}`);
      console.log(`   Date: ${vente.dateVente.toLocaleString('fr-FR')}`);
      console.log(`   Client: ${vente.client ? `${vente.client.nom} ${vente.client.prenom || ''}` : 'Aucun'}`);
      console.log(`   Montant total: ${vente.montantTotal} FCFA`);
      console.log(`   Montant payé: ${vente.montantPaye} FCFA`);
      console.log(`   Montant restant: ${vente.montantRestant} FCFA`);
      console.log(`   Mode paiement: ${vente.modePaiement}`);
      console.log('');
    }
    
  } catch (error) {
    console.error('❌ Erreur:', error);
  } finally {
    await prisma.$disconnect();
  }
}

checkSalesData();
