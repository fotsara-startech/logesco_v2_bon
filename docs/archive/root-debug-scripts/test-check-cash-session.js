/**
 * Test pour vérifier la session de caisse
 */

const axios = require('axios');

const API_URL = 'http://localhost:8080/api/v1';

const TEST_USER = {
  nomUtilisateur: 'admin',
  motDePasse: 'admin123'
};

let authToken = '';

async function authenticate() {
  const response = await axios.post(`${API_URL}/auth/login`, TEST_USER);
  authToken = response.data.data.accessToken;
  console.log('✅ Authentifié');
}

async function checkSession() {
  try {
    await authenticate();
    
    console.log('\n📊 Vérification de la session de caisse...\n');
    
    // Récupérer la session active
    try {
      const response = await axios.get(`${API_URL}/cash-sessions/active`, {
        headers: { Authorization: `Bearer ${authToken}` }
      });
      
      if (response.data.success && response.data.data) {
        const session = response.data.data;
        console.log('✅ Session active trouvée:');
        console.log(`   ID: ${session.id}`);
        console.log(`   Caisse ID: ${session.caisseId}`);
        console.log(`   Utilisateur ID: ${session.utilisateurId}`);
        console.log(`   Solde initial: ${session.soldeInitial} FCFA`);
        console.log(`   Solde actuel: ${session.soldeActuel} FCFA`);
        console.log(`   Statut: ${session.statut}`);
        console.log(`   Date ouverture: ${session.dateOuverture}`);
        
        if (session.soldeActuel === null || session.soldeActuel === undefined) {
          console.log('\n⚠️  PROBLÈME: Le solde actuel est null/undefined!');
          console.log('   Cela empêchera la création de mouvements financiers.');
        } else if (session.soldeActuel < 5000) {
          console.log(`\n⚠️  ATTENTION: Solde faible (${session.soldeActuel} FCFA)`);
          console.log('   Les paiements supérieurs à ce montant échoueront.');
        } else {
          console.log('\n✅ Solde suffisant pour les paiements');
        }
      } else {
        console.log('❌ Aucune session active');
      }
    } catch (error) {
      console.error('❌ Erreur:', error.response?.data || error.message);
    }
    
  } catch (error) {
    console.error('❌ Erreur:', error.message);
  }
}

checkSession();
