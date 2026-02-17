/**
 * Script pour appliquer les index de performance
 * Supporte SQLite et PostgreSQL
 */

const { PrismaClient } = require('@prisma/client');
const fs = require('fs');
const path = require('path');
const environment = require('../src/config/environment');

async function applyPerformanceIndexes() {
  const prisma = new PrismaClient();
  
  try {
    console.log('🔧 Application des index de performance...');
    console.log(`📊 Base de données: ${environment.databaseConfig.provider}`);

    // Lire le fichier SQL des index
    const indexesPath = path.join(__dirname, '../prisma/migrations/add_performance_indexes.sql');
    const indexesSql = fs.readFileSync(indexesPath, 'utf8');

    // Diviser les commandes SQL
    const commands = indexesSql
      .split(';')
      .map(cmd => cmd.trim())
      .filter(cmd => cmd.length > 0 && !cmd.startsWith('--'));

    console.log(`📝 ${commands.length} index à créer...`);

    // Exécuter chaque commande d'index
    for (let i = 0; i < commands.length; i++) {
      const command = commands[i];
      try {
        console.log(`⚡ Création index ${i + 1}/${commands.length}...`);
        
        if (environment.databaseConfig.provider === 'postgresql') {
          // Adapter la syntaxe pour PostgreSQL
          const pgCommand = command.replace(/IF NOT EXISTS/g, '');
          await prisma.$executeRawUnsafe(pgCommand);
        } else {
          // SQLite
          await prisma.$executeRawUnsafe(command);
        }
      } catch (error) {
        if (error.message.includes('already exists') || error.message.includes('duplicate')) {
          console.log(`⚠️  Index ${i + 1} existe déjà, ignoré`);
        } else {
          console.error(`❌ Erreur index ${i + 1}:`, error.message);
        }
      }
    }

    console.log('✅ Index de performance appliqués avec succès');

    // Vérifier les index créés
    if (environment.databaseConfig.provider === 'sqlite') {
      const indexes = await prisma.$queryRaw`
        SELECT name, sql FROM sqlite_master 
        WHERE type = 'index' AND name LIKE 'idx_%'
        ORDER BY name
      `;
      console.log(`📊 ${indexes.length} index personnalisés trouvés`);
    } else {
      const indexes = await prisma.$queryRaw`
        SELECT indexname, tablename 
        FROM pg_indexes 
        WHERE indexname LIKE 'idx_%'
        ORDER BY indexname
      `;
      console.log(`📊 ${indexes.length} index personnalisés trouvés`);
    }

  } catch (error) {
    console.error('❌ Erreur lors de l\'application des index:', error);
    throw error;
  } finally {
    await prisma.$disconnect();
  }
}

// Exécuter si appelé directement
if (require.main === module) {
  applyPerformanceIndexes()
    .then(() => {
      console.log('🎉 Script terminé avec succès');
      process.exit(0);
    })
    .catch((error) => {
      console.error('💥 Échec du script:', error);
      process.exit(1);
    });
}

module.exports = { applyPerformanceIndexes };