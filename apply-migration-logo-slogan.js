/**
 * Script de migration pour ajouter les champs logo et slogan
 * aux paramètres d'entreprise
 */

const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function applyMigration() {
  console.log('========================================');
  console.log('Migration: Ajout logo et slogan');
  console.log('========================================');
  console.log('');

  try {
    console.log('📊 Ajout de la colonne "logo"...');
    
    try {
      await prisma.$executeRawUnsafe('ALTER TABLE parametres_entreprise ADD COLUMN logo TEXT');
      console.log('✅ Colonne "logo" ajoutée avec succès');
    } catch (error) {
      if (error.message.includes('duplicate column name')) {
        console.log('⚠️  Colonne "logo" déjà existante, ignorée');
      } else {
        throw error;
      }
    }

    console.log('');
    console.log('📊 Ajout de la colonne "slogan"...');
    
    try {
      await prisma.$executeRawUnsafe('ALTER TABLE parametres_entreprise ADD COLUMN slogan TEXT');
      console.log('✅ Colonne "slogan" ajoutée avec succès');
    } catch (error) {
      if (error.message.includes('duplicate column name')) {
        console.log('⚠️  Colonne "slogan" déjà existante, ignorée');
      } else {
        throw error;
      }
    }

    console.log('');
    console.log('========================================');
    console.log('✅ Migration appliquée avec succès!');
    console.log('========================================');
    console.log('');
    console.log('Les champs suivants ont été ajoutés:');
    console.log('- logo: Chemin vers le fichier logo (optionnel)');
    console.log('- slogan: Slogan de l\'entreprise (optionnel)');
    console.log('');

    // Vérifier que les colonnes ont été ajoutées
    console.log('Vérification de la structure de la table...');
    const result = await prisma.$queryRaw`PRAGMA table_info(parametres_entreprise)`;
    
    const hasLogo = result.some(col => col.name === 'logo');
    const hasSlogan = result.some(col => col.name === 'slogan');

    console.log('');
    if (hasLogo && hasSlogan) {
      console.log('✅ Colonnes logo et slogan confirmées dans la base de données');
      console.log('');
      console.log('Structure de la table parametres_entreprise:');
      result.forEach(col => {
        console.log(`   - ${col.name}: ${col.type}${col.notnull ? ' NOT NULL' : ''}`);
      });
    } else {
      console.log('⚠️  Attention: Colonnes non trouvées');
      if (!hasLogo) console.log('   - logo: MANQUANTE');
      if (!hasSlogan) console.log('   - slogan: MANQUANTE');
    }

  } catch (error) {
    console.error('');
    console.error('========================================');
    console.error('❌ ERREUR lors de la migration');
    console.error('========================================');
    console.error('');
    console.error('Message d\'erreur:', error.message);
    console.error('');
    if (error.stack) {
      console.error('Stack trace:', error.stack);
    }
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

// Exécuter la migration
applyMigration()
  .then(() => {
    console.log('');
    console.log('Prochaines étapes:');
    console.log('1. Générer le client Prisma: npx prisma generate');
    console.log('2. Redémarrer le backend');
    console.log('3. Régénérer le modèle Flutter: regenerer-modele-flutter.bat');
    console.log('');
    process.exit(0);
  })
  .catch((error) => {
    console.error('Erreur fatale:', error);
    process.exit(1);
  });

