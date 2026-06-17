#!/usr/bin/env node
/**
 * Test API Client Deletion with Sync
 * Teste la suppression d'un client via l'API et vérifie la synchronisation
 */

const http = require('http');

function makeRequest(options, data = null) {
  return new Promise((resolve, reject) => {
    const req = http.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => body += chunk);
      res.on('end', () => {
        try {
          const jsonBody = body ? JSON.parse(body) : {};
          resolve({ status: res.statusCode, data: jsonBody, headers: res.headers });
        } catch (e) {
          resolve({ status: res.statusCode, data: body, headers: res.headers });
        }
      });
    });

    req.on('error', reject);
    
    if (data) {
      req.write(JSON.stringify(data));
    }
    req.end();
  });
}

async function testApiClientDeletion() {
  const baseOptions = {
    hostname: 'localhost',
    port: 8080,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer test-token'  // Placeholder token
    }
  };

  try {
    console.log('🧪 Test API Client Deletion with Sync');
    console.log('====================================');

    // ── Étape 1 : Créer un client via API ──
    console.log('\n📝 Étape 1: Créer un client via API...');
    const createResponse = await makeRequest({
      ...baseOptions,
      path: '/api/v1/customers',
      method: 'POST'
    }, {
      nom: 'Test API Delete',
      prenom: 'Client',
      telephone: '+1111111111',
      email: 'test-api-delete@example.com'
    });

    if (createResponse.status !== 201) {
      console.error('❌ Échec création client:', createResponse);
      return false;
    }

    const clientId = createResponse.data.client.id;
    console.log(`✅ Client créé via API: ${createResponse.data.client.nom} (ID: ${clientId})`);

    // ── Étape 2 : Attendre un peu pour que la synchronisation se fasse ──
    console.log('\n📝 Étape 2: Attendre synchronisation initiale...');
    await new Promise(resolve => setTimeout(resolve, 2000));

    // ── Étape 3 : Supprimer le client via API ──
    console.log('\n📝 Étape 3: Supprimer le client via API...');
    const deleteResponse = await makeRequest({
      ...baseOptions,
      path: `/api/v1/customers/${clientId}`,
      method: 'DELETE'
    });

    if (deleteResponse.status !== 200) {
      console.error('❌ Échec suppression client:', deleteResponse);
      return false;
    }

    console.log(`✅ Client supprimé via API: ${deleteResponse.data.message}`);

    // ── Étape 4 : Vérifier les logs d'opération ──
    console.log('\n📝 Étape 4: Vérifier les logs d\'opération...');
    const { PrismaClient } = require('@prisma/client');
    const prisma = new PrismaClient();

    const operationLogs = await prisma.$queryRawUnsafe(
      `SELECT * FROM operation_log WHERE record_id = ? AND table_name IN ('clients', 'comptes_clients') ORDER BY timestamp DESC`,
      clientId
    );

    console.log(`📋 Logs d'opération trouvés: ${operationLogs.length}`);
    operationLogs.forEach(log => {
      console.log(`  - ${log.operation_type} ${log.table_name} (id=${log.record_id}) [${log.status}]`);
    });

    // ── Étape 5 : Vérifier deleted_records ──
    console.log('\n📝 Étape 5: Vérifier deleted_records...');
    const deletedRecords = await prisma.$queryRawUnsafe(
      `SELECT * FROM deleted_records WHERE record_id = ? ORDER BY deleted_at DESC`,
      clientId
    );

    console.log(`📋 deleted_records trouvés: ${deletedRecords.length}`);
    deletedRecords.forEach(record => {
      console.log(`  - ${record.table_name} (id=${record.record_id}) à ${record.deleted_at}`);
    });

    await prisma.$disconnect();

    // ── Étape 6 : Vérification finale ──
    console.log('\n📝 Étape 6: Vérification finale...');
    
    const hasDeleteLogs = operationLogs.some(log => log.operation_type === 'DELETE');
    const hasDeletedRecords = deletedRecords.length > 0;
    
    if (hasDeleteLogs && hasDeletedRecords) {
      console.log('✅ SUCCESS: Suppression API fonctionne avec synchronisation');
      console.log('✅ Les logs d\'opération et deleted_records sont créés correctement');
      return true;
    } else {
      console.log('❌ ÉCHEC: Problèmes dans la synchronisation');
      if (!hasDeleteLogs) console.log('  - Manque logs d\'opération DELETE');
      if (!hasDeletedRecords) console.log('  - Manque enregistrements deleted_records');
      return false;
    }

  } catch (error) {
    console.error('❌ Erreur test:', error);
    return false;
  }
}

// Run test
if (require.main === module) {
  testApiClientDeletion().then(success => {
    console.log('\n' + '='.repeat(50));
    if (success) {
      console.log('🎉 TEST RÉUSSI: API deletion avec sync fonctionne!');
      process.exit(0);
    } else {
      console.log('💥 TEST ÉCHOUÉ: Problèmes détectés dans l\'API');
      process.exit(1);
    }
  }).catch(error => {
    console.error('💥 ERREUR FATALE:', error);
    process.exit(1);
  });
}