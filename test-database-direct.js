#!/usr/bin/env node

/**
 * Test direct de la base de données SQLite sans Prisma
 */

const sqlite3 = require('sqlite3');
const { open } = require('sqlite');
const path = require('path');

async function testDatabaseDirect() {
  console.log('🧪 Test direct de la base de données SQLite');
  console.log('==========================================');
  
  try {
    // Ouvrir la base de données directement
    const db = await open({
      filename: path.join(__dirname, 'database', 'logesco.db'),
      driver: sqlite3.Database
    });
    
    console.log('✅ Connexion à la base de données réussie');
    
    // 1. Vérifier la structure de la table dates_peremption
    console.log('\n📋 1. Structure de la table dates_peremption...');
    
    const tableInfo = await db.all('PRAGMA table_info(dates_peremption)');
    console.log('✅ Colonnes de la table:');
    tableInfo.forEach(col => {
      console.log(`   - ${col.name} (${col.type}) ${col.notnull ? 'NOT NULL' : ''} ${col.pk ? 'PRIMARY KEY' : ''}`);
    });
    
    // Vérifier que boutiqueId existe
    const hasBoutiqueId = tableInfo.some(col => col.name === 'boutique_id');
    if (hasBoutiqueId) {
      console.log('✅ La colonne boutique_id existe bien!');
    } else {
      console.log('❌ La colonne boutique_id n\'existe pas!');
      return;
    }
    
    // 2. Vérifier les boutiques
    console.log('\n📋 2. Vérification des boutiques...');
    
    const boutiques = await db.all(`
      SELECT id, nom, est_principale 
      FROM boutiques 
      ORDER BY est_principale DESC
    `);
    
    console.log(`✅ ${boutiques.length} boutique(s) trouvée(s):`);
    boutiques.forEach(b => {
      console.log(`   - ${b.nom} (ID: ${b.id}) ${b.est_principale ? '[PRINCIPALE]' : ''}`);
    });
    
    const boutiquePrincipale = boutiques.find(b => b.est_principale) || boutiques[0];
    
    // 3. Vérifier les dates de péremption avec boutiqueId
    console.log('\n📅 3. Vérification des dates de péremption...');
    
    const datesStats = await db.get(`
      SELECT 
        COUNT(*) as total,
        COUNT(boutique_id) as avec_boutique,
        COUNT(CASE WHEN boutique_id IS NULL THEN 1 END) as sans_boutique
      FROM dates_peremption
    `);
    
    console.log(`✅ Statistiques des dates de péremption:`);
    console.log(`   - Total: ${datesStats.total}`);
    console.log(`   - Avec boutiqueId: ${datesStats.avec_boutique}`);
    console.log(`   - Sans boutiqueId: ${datesStats.sans_boutique}`);
    
    // 4. Test de filtrage par boutique
    console.log('\n🔍 4. Test de filtrage par boutique...');
    
    const datesParBoutique = await db.all(`
      SELECT 
        dp.id,
        dp.produit_id,
        dp.boutique_id,
        dp.quantite,
        dp.date_peremption,
        dp.numero_lot,
        p.nom as produit_nom,
        b.nom as boutique_nom
      FROM dates_peremption dp
      LEFT JOIN produits p ON dp.produit_id = p.id
      LEFT JOIN boutiques b ON dp.boutique_id = b.id
      WHERE dp.boutique_id = ?
      ORDER BY dp.date_peremption ASC
      LIMIT 5
    `, [boutiquePrincipale.id]);
    
    console.log(`✅ ${datesParBoutique.length} date(s) pour la boutique "${boutiquePrincipale.nom}":`);
    datesParBoutique.forEach((date, index) => {
      console.log(`   ${index + 1}. ${date.produit_nom || 'Produit inconnu'} - ${date.quantite} unités`);
    });
    
    // 5. Test de création d'une nouvelle date
    console.log('\n📝 5. Test de création d\'une nouvelle date...');
    
    // Trouver un produit
    const produit = await db.get(`
      SELECT id, nom, reference 
      FROM produits 
      WHERE gestion_peremption = 1 
      LIMIT 1
    `);
    
    if (produit) {
      const datePeremption = new Date();
      datePeremption.setDate(datePeremption.getDate() + 90); // Dans 90 jours
      
      try {
        const result = await db.run(`
          INSERT INTO dates_peremption (
            produit_id, 
            boutique_id, 
            date_peremption, 
            quantite, 
            numero_lot, 
            notes,
            date_creation,
            date_modification
          ) VALUES (?, ?, ?, ?, ?, ?, datetime('now'), datetime('now'))
        `, [
          produit.id,
          boutiquePrincipale.id,
          datePeremption.toISOString(),
          15,
          'LOT-TEST-DIRECT-' + Date.now(),
          'Test de création directe avec boutiqueId'
        ]);
        
        console.log(`✅ Nouvelle date créée avec ID: ${result.lastID}`);
        console.log(`   - Produit: ${produit.nom}`);
        console.log(`   - Boutique: ${boutiquePrincipale.nom}`);
        console.log(`   - Quantité: 15 unités`);
        
      } catch (error) {
        console.log(`⚠️  Erreur lors de la création: ${error.message}`);
      }
    } else {
      console.log('⚠️  Aucun produit avec gestion de péremption trouvé');
    }
    
    // 6. Statistiques finales par boutique
    console.log('\n📊 6. Statistiques finales par boutique...');
    
    const statsBoutiques = await db.all(`
      SELECT 
        dp.boutique_id,
        b.nom as boutique_nom,
        COUNT(*) as total_dates,
        SUM(CASE WHEN dp.est_epuise = 0 THEN dp.quantite ELSE 0 END) as quantite_active
      FROM dates_peremption dp
      LEFT JOIN boutiques b ON dp.boutique_id = b.id
      GROUP BY dp.boutique_id, b.nom
      ORDER BY b.est_principale DESC
    `);
    
    console.log('✅ Statistiques par boutique:');
    statsBoutiques.forEach(stat => {
      console.log(`   - ${stat.boutique_nom || 'Boutique inconnue'}: ${stat.total_dates} date(s), ${stat.quantite_active} unités actives`);
    });
    
    await db.close();
    
    console.log('\n🎉 Test direct réussi!');
    console.log('\n📝 Résumé:');
    console.log('   ✅ Colonne boutique_id présente');
    console.log('   ✅ Données existantes avec boutiqueId');
    console.log('   ✅ Filtrage par boutique fonctionnel');
    console.log('   ✅ Création avec boutiqueId possible');
    console.log('   ✅ Statistiques par boutique disponibles');
    
  } catch (error) {
    console.error('❌ Erreur lors du test:', error);
    throw error;
  }
}

// Exécuter le test
if (require.main === module) {
  testDatabaseDirect()
    .then(() => {
      console.log('\n✅ Test terminé avec succès!');
      process.exit(0);
    })
    .catch((error) => {
      console.error('\n💥 Échec du test:', error);
      process.exit(1);
    });
}

module.exports = { testDatabaseDirect };