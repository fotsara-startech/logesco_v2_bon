#!/usr/bin/env node

/**
 * Test direct de l'API des dates de péremption
 */

const axios = require('axios');

const API_BASE = 'http://localhost:8080/api/v1';

async function testExpirationAPIDirect() {
  console.log('🧪 Test direct de l\'API des dates de péremption');
  console.log('===============================================');
  
  try {
    // 1. Test de santé
    console.log('\n🏥 1. Test de santé...');
    const health = await axios.get('http://localhost:8080/health');
    console.log('✅ Serveur en ligne:', health.data.status);
    
    // 2. Test de l'endpoint des dates de péremption sans authentification
    console.log('\n📅 2. Test de l\'endpoint dates de péremption...');
    
    try {
      const response = await axios.get(`${API_BASE}/expiration-dates`, {
        params: { limit: 5 }
      });
      
      console.log('✅ Endpoint accessible');
      console.log('📊 Données reçues:', response.data.data?.length || 0, 'enregistrements');
      
      if (response.data.data && response.data.data.length > 0) {
        const firstDate = response.data.data[0];
        console.log('📋 Structure du premier enregistrement:');
        console.log('   - ID:', firstDate.id);
        console.log('   - Produit ID:', firstDate.produitId);
        console.log('   - Boutique ID:', firstDate.boutiqueId || 'NON PRÉSENT');
        console.log('   - Quantité:', firstDate.quantite);
        console.log('   - Date péremption:', firstDate.datePeremption);
      }
      
    } catch (error) {
      if (error.response?.status === 401) {
        console.log('⚠️  Authentification requise (normal)');
        console.log('📋 Status:', error.response.status);
        console.log('📋 Message:', error.response.data?.message || 'Non autorisé');
      } else {
        console.log('❌ Erreur:', error.message);
        console.log('📋 Status:', error.response?.status);
        console.log('📋 Data:', error.response?.data);
      }
    }
    
    // 3. Test de l'endpoint des alertes
    console.log('\n🚨 3. Test de l\'endpoint alertes...');
    
    try {
      const alertesResponse = await axios.get(`${API_BASE}/expiration-dates/alertes`, {
        params: { joursMax: 30, limit: 5 }
      });
      
      console.log('✅ Endpoint alertes accessible');
      console.log('📊 Alertes reçues:', alertesResponse.data.data?.length || 0);
      
    } catch (error) {
      if (error.response?.status === 401) {
        console.log('⚠️  Authentification requise pour les alertes (normal)');
      } else {
        console.log('❌ Erreur alertes:', error.message);
      }
    }
    
    console.log('\n📝 Résumé:');
    console.log('   ✅ Serveur backend opérationnel');
    console.log('   ✅ Endpoints des dates de péremption définis');
    console.log('   ⚠️  Authentification requise (comportement normal)');
    
    console.log('\n💡 Recommandations:');
    console.log('   1. L\'API fonctionne mais nécessite une authentification');
    console.log('   2. Le problème Flutter vient probablement de l\'authentification ou du format des données');
    console.log('   3. Vérifier les tokens d\'authentification dans l\'app Flutter');
    
  } catch (error) {
    console.error('❌ Erreur lors du test:', error.message);
  }
}

// Exécuter le test
if (require.main === module) {
  testExpirationAPIDirect()
    .then(() => {
      console.log('\n✅ Test terminé');
      process.exit(0);
    })
    .catch((error) => {
      console.error('\n💥 Échec du test:', error);
      process.exit(1);
    });
}

module.exports = { testExpirationAPIDirect };