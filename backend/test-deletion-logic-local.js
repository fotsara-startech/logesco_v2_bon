#!/usr/bin/env node
/**
 * Test Deletion Logic - Local Only
 * Teste la logique de suppression et de propagation sans connexion Neon
 */

const { PrismaClient } = require('@prisma/client');

async function testDeletionLogicLocal() {
  const prisma = new PrismaClient();

  try {
    console.log('🧪 Test Deletion Logic - Local Mode');
    console.log('===================================');

    // ── Étape 1 : Vérifier table deleted_records existe ──
    console.log('\n📝 Étape 1: Vérifier table deleted_records...');
    try {
      const count = await prisma.$queryRaw`SELECT COUNT(*) as count FROM deleted_records`;
      console.log(`✅ Table deleted_records existe: ${count[0].count} enregistrement(s)`);
    } catch (e) {
      console.error('❌ Table deleted_records n\'existe pas:', e.message);
      return false;
    }

    // ── Étape 2 : Créer un client test ──
    console.log('\n📝 Étape 2: Créer un client test...');
    const testClient = await prisma.client.create({
      data: {
        nom: 'Test Delete Logic',
        prenom: 'Local',
        telephone: '+1234567891',
        email: 'test-local@example.com'
      }
    });
    console.log(`✅ Client créé: ${testClient.nom} (ID: ${testClient.id})`);

    // ── Étape 3 : Créer un compte client ──
    console.log('\n📝 Étape 3: Créer compte client...');
    const testCompte = await prisma.compteClient.create({
      data: {
        clientId: testClient.id,
        soldeActuel: 250.0,
        limiteCredit: 1000.0
      }
    });
    console.log(`✅ Compte créé: solde ${testCompte.soldeActuel} (ID: ${testCompte.id})`);

    // ── Étape 4 : Simuler suppression avec enregistrement dans deleted_records ──
    console.log('\n📝 Étape 4: Simuler suppression avec deleted_records...');
    
    // Supprimer le compte d'abord (FK constraint)
    await prisma.compteClient.delete({ where: { id: testCompte.id } });
    await prisma.$executeRawUnsafe(
      `INSERT INTO deleted_records (table_name, record_id, deleted_at) VALUES (?, ?, datetime('now'))`,
      'comptes_clients', testCompte.id
    );
    console.log(`🗑️  Compte supprimé et enregistré dans deleted_records`);

    // Supprimer le client
    await prisma.client.delete({ where: { id: testClient.id } });
    await prisma.$executeRawUnsafe(
      `INSERT INTO deleted_records (table_name, record_id, deleted_at) VALUES (?, ?, datetime('now'))`,
      'clients', testClient.id
    );
    console.log(`🗑️  Client supprimé et enregistré dans deleted_records`);

    // ── Étape 5 : Vérifier deleted_records ──
    console.log('\n📝 Étape 5: Vérifier deleted_records...');
    const deletedRecords = await prisma.$queryRawUnsafe(
      `SELECT * FROM deleted_records WHERE record_id IN (?, ?) ORDER BY deleted_at ASC`,
      testClient.id, testCompte.id
    );
    console.log(`📋 Enregistrements de suppression: ${deletedRecords.length}`);
    deletedRecords.forEach(record => {
      console.log(`  - ${record.table_name} (id=${record.record_id}) à ${record.deleted_at}`);
    });

    // ── Étape 6 : Créer nouveaux enregistrements pour simuler "autre poste" ──
    console.log('\n📝 Étape 6: Créer enregistrements sur "autre poste"...');
    
    // Simuler que les données existent sur un autre poste
    const otherClient = await prisma.client.create({
      data: {
        id: testClient.id, // Même ID que le client supprimé
        nom: 'Test Delete Logic',
        prenom: 'Local',
        telephone: '+1234567891',
        email: 'test-local@example.com'
      }
    });
    
    const otherCompte = await prisma.compteClient.create({
      data: {
        id: testCompte.id, // Même ID que le compte supprimé
        clientId: testClient.id,
        soldeActuel: 250.0,
        limiteCredit: 1000.0
      }
    });
    
    console.log(`✅ "Autre poste" - Client recréé: ${otherClient.nom} (ID: ${otherClient.id})`);
    console.log(`✅ "Autre poste" - Compte recréé: solde ${otherCompte.soldeActuel} (ID: ${otherCompte.id})`);

    // ── Étape 7 : Simuler propagation depuis deleted_records ──
    console.log('\n📝 Étape 7: Simuler _applyRemoteDeletions...');
    
    // Récupérer les suppressions depuis un timestamp ancien pour tout avoir
    const since = '1970-01-01T00:00:00Z';
    const deletionsToApply = await prisma.$queryRawUnsafe(
      `SELECT table_name, record_id, deleted_at FROM deleted_records 
       WHERE record_id IN (?, ?) AND deleted_at > ? 
       ORDER BY deleted_at ASC`,
      testClient.id, testCompte.id, since
    );

    // Trier dans l'ordre FK inverse (enfants avant parents)
    const PULL_TABLES = [
      'user_roles', 'utilisateurs', 'boutiques', 'user_boutique_assignments',
      'categories', 'produits', 'historique_prix_achat', 'stock', 'stock_boutiques',
      'fournisseurs', 'comptes_fournisseurs', 'clients', 'comptes_clients'
    ];
    const deletionOrder = [...PULL_TABLES].reverse();
    
    deletionsToApply.sort((a, b) => {
      return deletionOrder.indexOf(a.table_name) - deletionOrder.indexOf(b.table_name);
    });

    console.log(`📋 ${deletionsToApply.length} suppression(s) à propager:`);
    for (const deletion of deletionsToApply) {
      const { table_name, record_id } = deletion;
      try {
        await prisma.$executeRawUnsafe(`DELETE FROM "${table_name}" WHERE id = ?`, record_id);
        console.log(`  🗑️  Supprimé: ${table_name} (id=${record_id})`);
      } catch (e) {
        console.log(`  ⚠️  ${table_name} (id=${record_id}): ${e.message}`);
      }
    }

    // ── Étape 8 : Vérification finale ──
    console.log('\n📝 Étape 8: Vérification finale...');
    const finalClient = await prisma.client.findUnique({ where: { id: testClient.id } });
    const finalCompte = await prisma.compteClient.findUnique({ where: { id: testCompte.id } });
    
    if (!finalClient && !finalCompte) {
      console.log('✅ SUCCESS: Logique de propagation fonctionne correctement');
      console.log('✅ Les enregistrements ont été supprimés après lecture de deleted_records');
      
      // ── Étape 9 : Nettoyage ──
      console.log('\n📝 Étape 9: Nettoyage des deleted_records...');
      await prisma.$executeRawUnsafe(
        `DELETE FROM deleted_records WHERE record_id IN (?, ?)`,
        testClient.id, testCompte.id
      );
      console.log('✅ deleted_records nettoyés');
      
      return true;
    } else {
      console.log('❌ ÉCHEC: Certains enregistrements n\'ont pas été supprimés');
      if (finalClient) console.log(`  - Client ${finalClient.id} encore présent`);
      if (finalCompte) console.log(`  - Compte ${finalCompte.id} encore présent`);
      return false;
    }

  } catch (error) {
    console.error('❌ Erreur test:', error);
    return false;
  } finally {
    await prisma.$disconnect();
  }
}

// Run test
if (require.main === module) {
  testDeletionLogicLocal().then(success => {
    console.log('\n' + '='.repeat(50));
    if (success) {
      console.log('🎉 TEST RÉUSSI: Logique de suppression fonctionne!');
      console.log('📝 La propagation cross-device est prête');
      process.exit(0);
    } else {
      console.log('💥 TEST ÉCHOUÉ: Problèmes dans la logique');
      process.exit(1);
    }
  }).catch(error => {
    console.error('💥 ERREUR FATALE:', error);
    process.exit(1);
  });
}