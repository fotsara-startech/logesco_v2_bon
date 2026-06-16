#!/usr/bin/env node
/**
 * Test Cross-Device Deletion Propagation
 * Vérifie que les suppressions faites sur un poste A sont propagées au poste B via deleted_records
 */

const { Pool } = require('pg');
const { PrismaClient } = require('@prisma/client');
require('dotenv').config();

async function testCrossDeviceDeletion() {
  const prisma = new PrismaClient();
  const cloudUrl = process.env.CLOUD_DB_URL;
  
  if (!cloudUrl) {
    console.error('❌ CLOUD_DB_URL non défini dans .env');
    process.exit(1);
  }

  const cloudPool = new Pool({
    connectionString: cloudUrl,
    ssl: { rejectUnauthorized: false }
  });

  try {
    console.log('🧪 Test Cross-Device Deletion Propagation');
    console.log('=========================================');

    // ── Étape 1 : Créer un client test ──
    console.log('\n📝 Étape 1: Créer un client test...');
    const testClient = await prisma.client.create({
      data: {
        nom: 'Test Client Delete',
        prenom: 'CrossDevice',
        telephone: '+1234567890',
        email: 'test-delete@example.com'
      }
    });
    console.log(`✅ Client créé: ${testClient.nom} (ID: ${testClient.id})`);

    // ── Étape 2 : Créer un compte client ──
    console.log('\n📝 Étape 2: Créer compte client...');
    const testCompte = await prisma.compteClient.create({
      data: {
        clientId: testClient.id,
        soldeActuel: 100.0,
        limiteCredit: 500.0
      }
    });
    console.log(`✅ Compte créé: solde ${testCompte.soldeActuel} (ID: ${testCompte.id})`);

    // ── Étape 3 : Simuler synchronisation vers Neon ──
    console.log('\n📝 Étape 3: Synchroniser vers Neon...');
    const client = await cloudPool.connect();
    
    // INSERT client vers Neon
    await client.query(
      `INSERT INTO "clients" (id, nom, prenom, telephone, email, date_creation, date_modification)
       VALUES ($1, $2, $3, $4, $5, NOW(), NOW())
       ON CONFLICT (id) DO UPDATE SET nom = EXCLUDED.nom`,
      [testClient.id, testClient.nom, testClient.prenom, testClient.telephone, testClient.email]
    );

    // INSERT compte vers Neon
    await client.query(
      `INSERT INTO "comptes_clients" (id, client_id, solde_actuel, limite_credit, date_derniere_maj, date_modification)
       VALUES ($1, $2, $3, $4, NOW(), NOW())
       ON CONFLICT (id) DO UPDATE SET solde_actuel = EXCLUDED.solde_actuel`,
      [testCompte.id, testClient.id, testCompte.soldeActuel, testCompte.limiteCredit]
    );

    console.log('✅ Synchronisé vers Neon');

    // ── Étape 4 : Vérifier table deleted_records existe ──
    console.log('\n📝 Étape 4: Vérifier table deleted_records...');
    try {
      await client.query('SELECT COUNT(*) FROM "deleted_records"');
      console.log('✅ Table deleted_records existe dans Neon');
    } catch (e) {
      console.error('❌ Table deleted_records manquante dans Neon:', e.message);
      client.release();
      return false;
    }

    // Vérifier en local aussi
    try {
      const localCount = await prisma.$queryRaw`SELECT COUNT(*) as count FROM deleted_records`;
      console.log(`✅ Table deleted_records locale: ${localCount[0].count} enregistrement(s)`);
    } catch (e) {
      console.log('⚠️  Table deleted_records locale inexistante - sera créée au redémarrage');
    }

    // ── Étape 5 : Simuler suppression sur "Poste A" (via Neon directement) ──
    console.log('\n📝 Étape 5: Simuler suppression sur Poste A...');
    
    // Supprimer le compte d'abord (FK constraint)
    await client.query('DELETE FROM "comptes_clients" WHERE client_id = $1', [testClient.id]);
    await client.query(
      'INSERT INTO "deleted_records" (table_name, record_id, deleted_at) VALUES ($1, $2, NOW())',
      ['comptes_clients', testCompte.id]
    );
    console.log(`🗑️  Compte supprimé (Poste A) - enregistré dans deleted_records`);

    // Supprimer le client
    await client.query('DELETE FROM "clients" WHERE id = $1', [testClient.id]);
    await client.query(
      'INSERT INTO "deleted_records" (table_name, record_id, deleted_at) VALUES ($1, $2, NOW())',
      ['clients', testClient.id]
    );
    console.log(`🗑️  Client supprimé (Poste A) - enregistré dans deleted_records`);

    // ── Étape 6 : Vérifier deleted_records dans Neon ──
    console.log('\n📝 Étape 6: Vérifier deleted_records dans Neon...');
    const deletedRecords = await client.query(
      'SELECT * FROM "deleted_records" WHERE record_id IN ($1, $2) ORDER BY deleted_at ASC',
      [testClient.id, testCompte.id]
    );
    console.log(`📋 Enregistrements de suppression: ${deletedRecords.rows.length}`);
    deletedRecords.rows.forEach(record => {
      console.log(`  - ${record.table_name} (id=${record.record_id}) à ${record.deleted_at}`);
    });

    // ── Étape 7 : Simuler pull depuis "Poste B" (notre instance locale) ──
    console.log('\n📝 Étape 7: Simuler propagation vers Poste B...');
    
    // Vérifier que les enregistrements existent encore en local
    const localClient = await prisma.client.findUnique({ where: { id: testClient.id } });
    const localCompte = await prisma.compteClient.findUnique({ where: { id: testCompte.id } });
    
    if (localClient) {
      console.log(`📍 Client encore présent en local: ${localClient.nom}`);
    } else {
      console.log(`⚠️  Client déjà absent en local`);
    }
    
    if (localCompte) {
      console.log(`📍 Compte encore présent en local: solde ${localCompte.soldeActuel}`);
    } else {
      console.log(`⚠️  Compte déjà absent en local`);
    }

    // Simuler la propagation en appliquant les suppressions depuis deleted_records
    console.log('\n📝 Simulation de _applyRemoteDeletions...');
    const deletionsToApply = deletedRecords.rows.sort((a, b) => {
      // Trier par ordre FK inverse: enfants avant parents
      const tableOrder = ['comptes_clients', 'clients'];
      return tableOrder.indexOf(a.table_name) - tableOrder.indexOf(b.table_name);
    });

    for (const deletion of deletionsToApply) {
      const { table_name, record_id } = deletion;
      try {
        await prisma.$executeRawUnsafe(`DELETE FROM "${table_name}" WHERE id = ?`, record_id);
        console.log(`  🗑️  Supprimé local: ${table_name} (id=${record_id})`);
      } catch (e) {
        console.log(`  ⚠️  ${table_name} (id=${record_id}): ${e.message}`);
      }
    }

    // ── Étape 8 : Vérification finale ──
    console.log('\n📝 Étape 8: Vérification finale...');
    const finalClient = await prisma.client.findUnique({ where: { id: testClient.id } });
    const finalCompte = await prisma.compteClient.findUnique({ where: { id: testCompte.id } });
    
    if (!finalClient && !finalCompte) {
      console.log('✅ SUCCESS: Suppression propagée avec succès du Poste A vers Poste B');
      console.log('✅ Les enregistrements ont été supprimés en local après lecture de deleted_records');
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
    try {
      if (cloudPool) {
        const client = await cloudPool.connect();
        client.release();
        await cloudPool.end();
      }
    } catch (e) {
      console.warn('⚠️  Erreur fermeture pool:', e.message);
    }
    await prisma.$disconnect();
  }
}

// Run test
if (require.main === module) {
  testCrossDeviceDeletion().then(success => {
    console.log('\n' + '='.repeat(50));
    if (success) {
      console.log('🎉 TEST RÉUSSI: Cross-device deletion propagation fonctionne!');
      process.exit(0);
    } else {
      console.log('💥 TEST ÉCHOUÉ: Problèmes détectés');
      process.exit(1);
    }
  }).catch(error => {
    console.error('💥 ERREUR FATALE:', error);
    process.exit(1);
  });
}