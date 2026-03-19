/**
 * Script simple pour vérifier la base de données
 * Sans utiliser Prisma Client
 */

const sqlite3 = require('sqlite3');
const path = require('path');

async function checkDatabase() {
  console.log('🔍 Vérification directe de la base de données...');
  
  const dbPath = path.join(__dirname, '../../database/logesco.db');
  console.log('📁 Chemin DB:', dbPath);
  
  return new Promise((resolve, reject) => {
    const db = new sqlite3.Database(dbPath, (err) => {
      if (err) {
        console.error('❌ Erreur connexion:', err.message);
        reject(err);
        return;
      }
      
      console.log('✅ Connexion SQLite réussie');
      
      // Lister toutes les tables
      db.all("SELECT name FROM sqlite_master WHERE type='table'", (err, tables) => {
        if (err) {
          console.error('❌ Erreur requête tables:', err.message);
          reject(err);
          return;
        }
        
        console.log('📊 Tables trouvées:');
        tables.forEach(table => {
          console.log(`  - ${table.name}`);
        });
        
        // Vérifier spécifiquement la table utilisateurs
        db.get("SELECT COUNT(*) as count FROM utilisateurs", (err, result) => {
          if (err) {
            console.error('❌ Erreur table utilisateurs:', err.message);
          } else {
            console.log(`✅ Table utilisateurs: ${result.count} enregistrements`);
          }
          
          // Vérifier la table produits
          db.get("SELECT COUNT(*) as count FROM produits", (err, result) => {
            if (err) {
              console.error('❌ Erreur table produits:', err.message);
            } else {
              console.log(`✅ Table produits: ${result.count} enregistrements`);
            }
            
            db.close((err) => {
              if (err) {
                console.error('❌ Erreur fermeture:', err.message);
              } else {
                console.log('🔌 Base de données fermée');
              }
              resolve();
            });
          });
        });
      });
    });
  });
}

// Exécuter si appelé directement
if (require.main === module) {
  checkDatabase()
    .then(() => {
      console.log('🎉 Vérification terminée');
      process.exit(0);
    })
    .catch((error) => {
      console.error('💥 Échec vérification:', error);
      process.exit(1);
    });
}

module.exports = { checkDatabase };