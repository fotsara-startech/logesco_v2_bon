#!/usr/bin/env node

/**
 * Migration simple pour rendre l'email optionnel
 */

const { PrismaClient } = require('./src/config/prisma-client.js');
const prisma = new PrismaClient();

async function simpleEmailMigration() {
  try {
    console.log('🔄 [Migration] Début de la migration email optionnel...');

    // Désactiver les contraintes de clés étrangères temporairement
    await prisma.$executeRaw`PRAGMA foreign_keys = OFF;`;
    console.log('🔓 [Migration] Contraintes FK désactivées');

    // Vérifier la structure actuelle
    console.log('🔍 [Migration] Structure actuelle de la table utilisateurs:');
    const currentStructure = await prisma.$queryRaw`PRAGMA table_info(utilisateurs);`;
    console.log(currentStructure);

    // Créer une nouvelle table avec la structure correcte
    console.log('📝 [Migration] Création de la nouvelle table...');
    await prisma.$executeRaw`
      CREATE TABLE utilisateurs_new (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom_utilisateur TEXT UNIQUE NOT NULL,
        email TEXT,
        mot_de_passe_hash TEXT NOT NULL,
        role_id INTEGER,
        is_active BOOLEAN DEFAULT 1 NOT NULL,
        date_creation DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
        date_modification DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
        date_derniere_connexion DATETIME,
        FOREIGN KEY (role_id) REFERENCES user_roles (id)
      );
    `;

    // Copier toutes les données
    console.log('📋 [Migration] Copie des données...');
    await prisma.$executeRaw`
      INSERT INTO utilisateurs_new (
        id, nom_utilisateur, email, mot_de_passe_hash, role_id, 
        is_active, date_creation, date_modification, date_derniere_connexion
      )
      SELECT 
        id, nom_utilisateur, email, mot_de_passe_hash, role_id,
        is_active, date_creation, date_modification, date_derniere_connexion
      FROM utilisateurs;
    `;

    // Supprimer l'ancienne table
    console.log('🗑️ [Migration] Suppression de l\'ancienne table...');
    await prisma.$executeRaw`DROP TABLE utilisateurs;`;

    // Renommer la nouvelle table
    console.log('🔄 [Migration] Renommage de la nouvelle table...');
    await prisma.$executeRaw`ALTER TABLE utilisateurs_new RENAME TO utilisateurs;`;

    // Recréer les index
    console.log('📊 [Migration] Recréation des index...');
    await prisma.$executeRaw`CREATE INDEX idx_utilisateurs_nom ON utilisateurs(nom_utilisateur);`;
    await prisma.$executeRaw`CREATE INDEX idx_utilisateurs_role ON utilisateurs(role_id);`;

    // Réactiver les contraintes FK
    await prisma.$executeRaw`PRAGMA foreign_keys = ON;`;
    console.log('🔒 [Migration] Contraintes FK réactivées');

    // Vérifier la nouvelle structure
    console.log('🔍 [Migration] Nouvelle structure de la table utilisateurs:');
    const newStructure = await prisma.$queryRaw`PRAGMA table_info(utilisateurs);`;
    console.log(newStructure);

    // Test rapide
    console.log('🧪 [Migration] Test de la nouvelle structure...');
    const userCount = await prisma.$queryRaw`SELECT COUNT(*) as count FROM utilisateurs;`;
    console.log('👥 [Migration] Nombre d\'utilisateurs après migration:', userCount);

    console.log('✅ [Migration] Migration terminée avec succès !');
    console.log('ℹ️ [Migration] L\'email est maintenant optionnel pour les utilisateurs');

  } catch (error) {
    console.error('❌ [Migration] Erreur lors de la migration:', error);
    
    // En cas d'erreur, essayer de nettoyer
    try {
      await prisma.$executeRaw`DROP TABLE IF EXISTS utilisateurs_new;`;
      await prisma.$executeRaw`PRAGMA foreign_keys = ON;`;
    } catch (cleanupError) {
      console.error('❌ [Migration] Erreur lors du nettoyage:', cleanupError);
    }
    
    throw error;
  } finally {
    await prisma.$disconnect();
  }
}

// Exécuter la migration
simpleEmailMigration()
  .then(() => {
    console.log('🎉 Migration email optionnel terminée !');
    process.exit(0);
  })
  .catch((error) => {
    console.error('💥 Échec de la migration:', error);
    process.exit(1);
  });