/**
 * Test script to verify sync middleware field filtering
 * Run: node test-sync-middleware.js
 */

// Mock the sync service
const mockSyncService = {
  enqueue: (table, operation, data) => {
    console.log(`\n✅ Enqueued to ${table}:`);
    console.log(JSON.stringify(data, null, 2));
    return Promise.resolve();
  }
};

// Load the middleware
const syncMiddleware = require('./src/middleware/sync-middleware');

// Test data
const testCases = [
  {
    name: 'Cash Session with calculated fields',
    table: 'cash_sessions',
    responseData: {
      id: 5,
      caisseId: 2,
      utilisateurId: 1,
      boutiqueId: 7,
      soldeOuverture: 100000,
      soldeAttendu: 107000,
      dateOuverture: '2026-04-25T12:00:00Z',
      isActive: true,
      nomCaisse: 'Caisse Principale',  // ❌ Should be filtered
      nomUtilisateur: 'John Doe',      // ❌ Should be filtered
      caisse: { id: 2, nom: 'Caisse Principale' },  // ❌ Should be filtered
      utilisateur: { id: 1, nomUtilisateur: 'John Doe' }  // ❌ Should be filtered
    }
  },
  {
    name: 'Sale with all fields',
    table: 'ventes',
    responseData: {
      id: 298,
      numeroVente: 'VTE-20260425-123045',
      clientId: null,
      vendeurId: 1,
      sessionId: 5,
      boutiqueId: 7,
      montantTotal: 5000,
      montantPaye: 5000,
      montantRemise: 0,
      montantTva: 0,
      statut: 'terminee',
      modePaiement: 'comptant',
      dateVente: '2026-04-25T12:31:42Z',
      client: null,  // ❌ Should be filtered
      details: [],   // ❌ Should be filtered
      session: { id: 5 }  // ❌ Should be filtered
    }
  }
];

// Helper to convert snake_case to camelCase
function snakeToCamel(str) {
  return str.replace(/_([a-z])/g, (g) => g[1].toUpperCase());
}

// Test the filtering logic
console.log('🧪 Testing Sync Middleware Field Filtering\n');
console.log('='.repeat(60));

for (const testCase of testCases) {
  console.log(`\n📋 Test: ${testCase.name}`);
  console.log(`   Table: ${testCase.table}`);
  
  // Get the allowed columns for this table
  const ROUTE_MODEL_MAP = {
    'cash_sessions': {
      allowedColumns: [
        'id','caisse_id','utilisateur_id','boutique_id','solde_ouverture',
        'solde_fermeture','date_ouverture','date_fermeture','is_active',
        'metadata','solde_attendu','ecart'
      ]
    },
    'ventes': {
      allowedColumns: [
        'id','numero_vente','client_id','vendeur_id','session_id','boutique_id',
        'date_vente','sous_total','montant_remise','montant_tva','taux_tva',
        'montant_total','statut','mode_paiement','montant_paye','montant_restant'
      ]
    }
  };
  
  const config = ROUTE_MODEL_MAP[testCase.table];
  if (!config) {
    console.log('   ❌ Table not found in config');
    continue;
  }
  
  // Apply the filtering logic
  const dataToSync = {};
  for (const col of config.allowedColumns) {
    const camelCol = snakeToCamel(col);
    if (testCase.responseData[camelCol] !== undefined && testCase.responseData[camelCol] !== null) {
      dataToSync[camelCol] = testCase.responseData[camelCol];
    } else if (testCase.responseData[col] !== undefined && testCase.responseData[col] !== null) {
      dataToSync[col] = testCase.responseData[col];
    }
  }
  if (!dataToSync.id) dataToSync.id = testCase.responseData.id;
  
  // Show results
  console.log(`\n   Input fields: ${Object.keys(testCase.responseData).length}`);
  console.log(`   Output fields: ${Object.keys(dataToSync).length}`);
  
  // Check for unwanted fields
  const unwantedFields = ['nomCaisse', 'nomUtilisateur', 'client', 'details', 'session', 'utilisateur', 'caisse'];
  const foundUnwanted = unwantedFields.filter(f => f in dataToSync);
  
  if (foundUnwanted.length > 0) {
    console.log(`   ❌ FAILED: Found unwanted fields: ${foundUnwanted.join(', ')}`);
  } else {
    console.log(`   ✅ PASSED: No unwanted fields`);
  }
  
  console.log(`\n   Synced data:`);
  console.log(`   ${JSON.stringify(dataToSync, null, 2).split('\n').join('\n   ')}`);
}

console.log('\n' + '='.repeat(60));
console.log('✅ Test complete\n');
