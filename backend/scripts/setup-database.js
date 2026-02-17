const { PrismaClient } = require('@prisma/client');
const fs = require('fs');
const path = require('path');

const prisma = new PrismaClient();

async function setupDatabase() {
  try {
    console.log('🔄 Configuration de la base de données...');

    // Vérifier si les nouvelles tables existent déjà
    const tablesExist = await checkTablesExist();
    
    if (!tablesExist) {
      console.log('📦 Application des migrations...');
      await applyMigrations();
    } else {
      console.log('✅ Les tables existent déjà');
    }

    // Vérifier et insérer les données par défaut
    await insertDefaultData();

    console.log('✅ Base de données configurée avec succès');
  } catch (error) {
    console.error('❌ Erreur lors de la configuration:', error);
    throw error;
  } finally {
    await prisma.$disconnect();
  }
}

async function checkTablesExist() {
  try {
    // Essayer de faire une requête sur une des nouvelles tables
    await prisma.$queryRaw`SELECT name FROM sqlite_master WHERE type='table' AND name='user_roles'`;
    return true;
  } catch (error) {
    return false;
  }
}

async function applyMigrations() {
  const migrationPath = path.join(__dirname, '..', 'prisma', 'migrations', '20241029_add_users_cash_inventory', 'migration.sql');
  
  if (fs.existsSync(migrationPath)) {
    const migrationSQL = fs.readFileSync(migrationPath, 'utf8');
    
    // Diviser le SQL en statements individuels
    const statements = migrationSQL
      .split(';')
      .map(stmt => stmt.trim())
      .filter(stmt => stmt.length > 0 && !stmt.startsWith('--'));

    for (const statement of statements) {
      if (statement.trim()) {
        try {
          await prisma.$executeRawUnsafe(statement);
        } catch (error) {
          // Ignorer les erreurs de tables qui existent déjà
          if (!error.message.includes('already exists')) {
            console.error('Erreur SQL:', statement);
            throw error;
          }
        }
      }
    }
  }
}

async function insertDefaultData() {
  try {
    // Ne plus créer de rôles par défaut - les utilisateurs doivent les créer via l'interface
    console.log('ℹ️  Aucun rôle par défaut créé - utilisez l\'interface de gestion des rôles');
    
    // Ne plus créer d'utilisateur admin par défaut non plus
    console.log('ℹ️  Aucun utilisateur par défaut créé - créez vos rôles et utilisateurs via l\'interface');

    // Vérifier si les caisses par défaut existent
    const cashRegistersCount = await prisma.$queryRaw`SELECT COUNT(*) as count FROM cash_registers`;
    
    if (cashRegistersCount[0].count === 0) {
      console.log('💰 Création des caisses par défaut...');
      
      await prisma.$executeRaw`
        INSERT INTO cash_registers (nom, description, is_active) VALUES
        ('Caisse Principale', 'Caisse principale du magasin', true),
        ('Caisse Secondaire', 'Caisse pour les périodes de pointe', true)
      `;
    }

  } catch (error) {
    console.error('Erreur lors de l\'insertion des données par défaut:', error);
    throw error;
  }
}

// Exécuter le script si appelé directement
if (require.main === module) {
  setupDatabase()
    .then(() => {
      console.log('🎉 Configuration terminée avec succès');
      process.exit(0);
    })
    .catch((error) => {
      console.error('💥 Échec de la configuration:', error);
      process.exit(1);
    });
}

module.exports = { setupDatabase };