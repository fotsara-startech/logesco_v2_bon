const sqlite3 = require('sqlite3').verbose();
const path = require('path');

async function checkDatabaseTransactions() {
  console.log('🔍 DIAGNOSTIC: Vérification directe en base de données');
  console.log('====================================================');
  
  // Chemin vers la base de données SQLite
  const dbPath = path.join(__dirname, 'backend', 'database', 'logesco.db');
  
  return new Promise((resolve, reject) => {
    const db = new sqlite3.Database(dbPath, (err) => {
      if (err) {
        console.error('❌ Erreur connexion base de données:', err.message);
        reject(err);
        return;
      }
      console.log('✅ Connexion à la base de données réussie');
    });
    
    // Étape 1: Vérifier le compte client #30
    console.log('\n📋 Étape 1: Vérification du compte client ID #30...');
    
    db.get(`
      SELECT * FROM CompteClient WHERE clientId = 30
    `, (err, compte) => {
      if (err) {
        console.error('❌ Erreur requête compte:', err.message);
        db.close();
        reject(err);
        return;
      }
      
      if (compte) {
        console.log('✅ Compte trouvé:');
        console.log(`  - ID: ${compte.id}`);
        console.log(`  - Client ID: ${compte.clientId}`);
        console.log(`  - Solde actuel: ${compte.soldeActuel} FCFA`);
        console.log(`  - Limite crédit: ${compte.limiteCredit} FCFA`);
        
        // Étape 2: Vérifier toutes les transactions de ce compte
        console.log('\n📋 Étape 2: Vérification des transactions...');
        
        db.all(`
          SELECT * FROM TransactionCompte 
          WHERE compteId = ? OR compteId = ?
          ORDER BY dateTransaction DESC
        `, [compte.id, 30], (err, transactions) => {
          if (err) {
            console.error('❌ Erreur requête transactions:', err.message);
            db.close();
            reject(err);
            return;
          }
          
          console.log(`✅ Transactions trouvées: ${transactions.length}`);
          
          if (transactions.length > 0) {
            console.log('\n📊 DÉTAIL DES TRANSACTIONS:');
            transactions.forEach((transaction, index) => {
              console.log(`  ${index + 1}. Transaction ID: ${transaction.id}`);
              console.log(`     - Compte ID: ${transaction.compteId} (attendu: ${compte.id})`);
              console.log(`     - Type compte: ${transaction.typeCompte}`);
              console.log(`     - Type transaction: ${transaction.typeTransaction}`);
              console.log(`     - Montant: ${transaction.montant} FCFA`);
              console.log(`     - Description: ${transaction.description}`);
              console.log(`     - Date: ${transaction.dateTransaction}`);
              console.log(`     - Solde après: ${transaction.soldeApres} FCFA`);
              console.log(`     - Référence: ${transaction.referenceType} #${transaction.referenceId}`);
              console.log('');
            });
            
            // Analyser le problème
            const transactionsAvecBonCompteId = transactions.filter(t => t.compteId === compte.id);
            const transactionsAvecMauvaisCompteId = transactions.filter(t => t.compteId === 30);
            
            console.log('🔍 ANALYSE DU PROBLÈME:');
            console.log(`  - Transactions avec bon compteId (${compte.id}): ${transactionsAvecBonCompteId.length}`);
            console.log(`  - Transactions avec mauvais compteId (30): ${transactionsAvecMauvaisCompteId.length}`);
            
            if (transactionsAvecMauvaisCompteId.length > 0) {
              console.log('\n❌ PROBLÈME IDENTIFIÉ:');
              console.log('   Les transactions ont été créées avec compteId = clientId (30)');
              console.log(`   au lieu de compteId = compte.id (${compte.id})`);
              console.log('   C\'est exactement le bug que nous avons corrigé !');
              
              console.log('\n🔧 SOLUTION:');
              console.log('   1. Corriger les transactions existantes en base');
              console.log('   2. Ou recréer les transactions avec le bon compteId');
              console.log('   3. Les nouvelles ventes utiliseront le code corrigé');
            }
            
          } else {
            console.log('❌ Aucune transaction trouvée en base de données');
            console.log('   Le problème est ailleurs...');
          }
          
          // Étape 3: Vérifier la requête utilisée par l'API
          console.log('\n📋 Étape 3: Test de la requête API...');
          
          db.all(`
            SELECT * FROM TransactionCompte 
            WHERE typeCompte = 'client' AND compteId = ?
            ORDER BY dateTransaction DESC
          `, [compte.id], (err, apiTransactions) => {
            if (err) {
              console.error('❌ Erreur requête API:', err.message);
            } else {
              console.log(`✅ Requête API retourne: ${apiTransactions.length} transactions`);
              console.log('   (C\'est ce que l\'API devrait retourner)');
            }
            
            db.close();
            resolve();
          });
        });
        
      } else {
        console.log('❌ Aucun compte trouvé pour le client ID #30');
        db.close();
        resolve();
      }
    });
  });
}

// Vérifier si sqlite3 est disponible
try {
  checkDatabaseTransactions().catch(console.error);
} catch (error) {
  console.log('❌ Module sqlite3 non disponible:', error.message);
  console.log('💡 Pour installer: npm install sqlite3');
  console.log('💡 Alternative: Vérifier directement via l\'interface de base de données');
}