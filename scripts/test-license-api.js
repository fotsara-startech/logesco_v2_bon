const axios = require('axios');

const API_BASE = 'http://localhost:8080/api/v1';

/**
 * Test d'integration des API de licences
 */
async function testLicenseAPI() {
  console.log('Test d integration des API de licences...\n');

  try {
    // Test 1: Generer une licence
    console.log('1. Test de generation de licence via API...');
    const licenseData = {
      userId: 'api-test-user-123',
      subscriptionType: 'annual',
      deviceFingerprint: 'api-device-fingerprint',
      expiresAt: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString(),
      metadata: {
        plan: 'enterprise',
        features: ['all-features']
      }
    };

    const createResponse = await axios.post(`${API_BASE}/licenses`, licenseData);
    console.log('Licence creee:', createResponse.data.data.licenseKey);
    const licenseKey = createResponse.data.data.licenseKey;

    // Test 2: Valider la licence
    console.log('\n2. Test de validation via API...');
    const validateResponse = await axios.post(`${API_BASE}/licenses/${licenseKey}/validate`, {
      deviceFingerprint: 'api-device-fingerprint'
    });
    console.log('Validation:', validateResponse.data.data.isValid ? 'VALIDE' : 'INVALIDE');

    // Test 3: Recuperer toutes les licences
    console.log('\n3. Test de recuperation des licences...');
    const listResponse = await axios.get(`${API_BASE}/licenses`);
    console.log('Nombre de licences:', listResponse.data.data.length);

    // Test 4: Recuperer les statistiques
    console.log('\n4. Test des statistiques...');
    const statsResponse = await axios.get(`${API_BASE}/licenses/stats`);
    console.log('Statistiques:', JSON.stringify(statsResponse.data.data, null, 2));

    // Test 5: Revoquer la licence
    console.log('\n5. Test de revocation...');
    const revokeResponse = await axios.put(`${API_BASE}/licenses/${licenseKey}/revoke`, {
      reason: 'Test de revocation via API'
    });
    console.log('Licence revoquee');

    console.log('\nTous les tests API sont passes avec succes!');

  } catch (error) {
    if (error.response) {
      console.error('Erreur API:', error.response.status, error.response.data);
    } else {
      console.error('Erreur:', error.message);
    }
  }
}

// Executer les tests
if (require.main === module) {
  testLicenseAPI();
}

module.exports = testLicenseAPI;
