/**
 * Script pour tester les totaux d'entrées et de sorties dans les sessions
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

async function testSessionTotals() {
  try {
    await authenticate();
    
    console.log('\n📊 Test des totaux d\'entrées et de sorties...\n');
    
    // Récupérer l'historique des sessions
    const response = await axios.get(`${API_URL}/cash-sessions/history?limit=5`, {
      headers: { Authorization: `Bearer ${authToken}` }
    });
    
    if (response.data.success && response.data.data.length > 0) {
      console.log(`✅ ${response.data.data.length} session(s) trouvée(s)\n`);
      
      response.data.data.forEach((session, index) => {
        console.log(`📋 Session ${index + 1}:`);
        console.log(`   ID: ${session.id}`);
        console.log(`   Caisse: ${session.nomCaisse}`);
        console.log(`   Utilisateur: ${session.nomUtilisateur}`);
        console.log(`   Ouverture: ${new Date(session.dateOuverture).toLocaleString('fr-FR')}`);
        if (session.dateFermeture) {
          console.log(`   Fermeture: ${new Date(session.dateFermeture).toLocaleString('fr-FR')}`);
        }
        console.log(`   Statut: ${session.isActive ? 'Ouverte' : 'Fermée'}`);
        console.log(`   ─────────────────────────────────────`);
        console.log(`   Solde ouverture: ${session.soldeOuverture} FCFA`);
        if (session.soldeAttendu !== null) {
          console.log(`   Solde attendu: ${session.soldeAttendu} FCFA`);
        }
        if (session.soldeFermeture !== null) {
          console.log(`   Solde déclaré: ${session.soldeFermeture} FCFA`);
        }
        console.log(`   ─────────────────────────────────────`);
        console.log(`   💰 Total entrées: ${session.totalEntrees} FCFA`);
        console.log(`   💸 Total dépenses: ${session.totalSorties} FCFA`);
        console.log(`   📊 Net: ${session.totalEntrees - session.totalSorties} FCFA`);
        
        if (session.ecart !== null) {
          console.log(`   ─────────────────────────────────────`);
          const ecartSymbol = session.ecart >= 0 ? '✅' : '⚠️';
          console.log(`   ${ecartSymbol} Écart: ${session.ecart >= 0 ? '+' : ''}${session.ecart} FCFA`);
        }
        
        // Vérification de cohérence
        if (session.soldeAttendu !== null) {
          const calculatedSolde = session.soldeOuverture + session.totalEntrees - session.totalSorties;
          const difference = Math.abs(calculatedSolde - session.soldeAttendu);
          
          if (difference > 0.01) {
            console.log(`   ⚠️  INCOHÉRENCE DÉTECTÉE!`);
            console.log(`   Solde calculé: ${calculatedSolde} FCFA`);
            console.log(`   Solde attendu: ${session.soldeAttendu} FCFA`);
            console.log(`   Différence: ${difference} FCFA`);
          } else {
            console.log(`   ✅ Cohérence vérifiée`);
          }
        }
        
        console.log('');
      });
      
      // Statistiques globales
      const totalEntreesGlobal = response.data.data.reduce((sum, s) => sum + s.totalEntrees, 0);
      const totalSortiesGlobal = response.data.data.reduce((sum, s) => sum + s.totalSorties, 0);
      
      console.log('📊 STATISTIQUES GLOBALES:');
      console.log(`   Total entrées (toutes sessions): ${totalEntreesGlobal} FCFA`);
      console.log(`   Total dépenses (toutes sessions): ${totalSortiesGlobal} FCFA`);
      console.log(`   Net global: ${totalEntreesGlobal - totalSortiesGlobal} FCFA`);
      
    } else {
      console.log('❌ Aucune session trouvée');
    }
    
  } catch (error) {
    console.error('❌ Erreur:', error.response?.data || error.message);
  }
}

testSessionTotals();
