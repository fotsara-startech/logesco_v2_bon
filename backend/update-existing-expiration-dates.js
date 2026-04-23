#!/usr/bin/env node

/**
 * Script pour mettre à jour les dates de péremption existantes avec boutiqueId
 */

const { PrismaClient } = require('@prisma/client');

async function updateExistingExpirationDates() {
  console.log('🔄 Mise à jour des dates de péremption existantes...');
  
  const prisma = new PrismaClient();
  
  try {
    // 1. Trouver la boutique principale
    console.log('📋 Recherche de la boutique principale...');
    
    const boutiquePrincipale = await prisma.$queryRaw`
      SELECT id, nom FROM boutiques WHERE est_principale = 1 LIMIT 1
    `;
    
    if (boutiquePrincipale.length === 0) {
      console.log('❌ Aucune boutique principale trouvée. Création d\'une boutique par défaut...');
      
      const result = await prisma.$executeRaw`
        INSERT INTO boutiques (nom, est_principale, is_active, date_creation, date_modification)
        VALUES ('Boutique Principale', 1, 1, datetime('now'), datetime('now'))
      `;
      
      const newBoutique = await prisma.$queryRaw`
        SELECT id, nom FROM boutiques WHERE est_principale = 1 LIMIT 1
      `;
      
      console.log(`✅ Boutique principale créée: ${newBoutique[0].nom} (ID: ${newBoutique[0].id})`);
      boutiquePrincipale.push(newBoutique[0]);
    } else {
      console.log(`✅ Boutique principale trouvée: ${boutiquePrincipale[0].nom} (ID: ${boutiquePrincipale[0].id})`);
    }
    
    const boutiqueId = boutiquePrincipale[0].id;
    
    // 2. Vérifier les dates de péremption sans boutiqueId
    console.log('🔍 Vérification des dates de péremption sans boutiqueId...');
    
    const datesWithoutBoutique = await prisma.$queryRaw`
      SELECT COUNT(*) as count FROM dates_peremption WHERE boutique_id IS NULL
    `;
    
    const countWithoutBoutique = datesWithoutBoutique[0].count;
    console.log(`📊 ${countWithoutBoutique} date(s) de péremption sans boutiqueId trouvée(s)`);
    
    if (countWithoutBoutique > 0) {
      // 3. Mettre à jour les dates existantes
      console.log('🔄 Mise à jour des dates de péremption...');
      
      const updateResult = await prisma.$executeRaw`
        UPDATE dates_peremption 
        SET boutique_id = ${boutiqueId}
        WHERE boutique_id IS NULL
      `;
      
      console.log(`✅ ${updateResult} date(s) de péremption mise(s) à jour avec boutiqueId = ${boutiqueId}`);
    } else {
      console.log('✅ Toutes les dates de péremption ont déjà un boutiqueId');
    }
    
    // 4. Vérification finale
    console.log('🔍 Vérification finale...');
    
    const finalStats = await prisma.$queryRaw`
      SELECT 
        COUNT(*) as total,
        COUNT(boutique_id) as avec_boutique,
        boutique_id
      FROM dates_peremption 
      GROUP BY boutique_id
    `;
    
    console.log('📊 Statistiques finales:');
    finalStats.forEach(stat => {
      if (stat.boutique_id) {
        console.log(`   - Boutique ${stat.boutique_id}: ${stat.total} date(s) de péremption`);
      } else {
        console.log(`   - Sans boutique: ${stat.total} date(s) de péremption`);
      }
    });
    
    // 5. Test d'une requête avec le nouveau champ
    console.log('🧪 Test d\'une requête avec boutiqueId...');
    
    const testQuery = await prisma.$queryRaw`
      SELECT 
        dp.id,
        dp.quantite,
        dp.date_peremption,
        dp.boutique_id,
        p.nom as produit_nom,
        b.nom as boutique_nom
      FROM dates_peremption dp
      LEFT JOIN produits p ON dp.produit_id = p.id
      LEFT JOIN boutiques b ON dp.boutique_id = b.id
      LIMIT 3
    `;
    
    console.log('✅ Exemple de données avec boutiqueId:');
    testQuery.forEach((row, index) => {
      console.log(`   ${index + 1}. ${row.produit_nom || 'Produit inconnu'} - ${row.quantite} unités - Boutique: ${row.boutique_nom || 'Inconnue'}`);
    });
    
    console.log('\n🎉 Mise à jour terminée avec succès!');
    
  } catch (error) {
    console.error('❌ Erreur lors de la mise à jour:', error);
    throw error;
  } finally {
    await prisma.$disconnect();
  }
}

// Exécuter la mise à jour
if (require.main === module) {
  updateExistingExpirationDates()
    .then(() => {
      console.log('✅ Mise à jour terminée avec succès!');
      process.exit(0);
    })
    .catch((error) => {
      console.error('💥 Échec de la mise à jour:', error);
      process.exit(1);
    });
}

module.exports = { updateExistingExpirationDates };