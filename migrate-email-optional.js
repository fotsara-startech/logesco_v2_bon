#!/usr/bin/env node

/**
 * Migration pour rendre l'email optionnel dans la table utilisateurs
 */

const { PrismaClient } = require('./src/config/prisma-client.js');
const prisma = new PrismaClient();

async function migrateEmailOptional() {
  try {
    console.log('🔄 [Migration] Début de la migration email optionnel...');

    // 1. Supprimer la contrainte UNIQUE sur email (SQLite ne supporte pas ALTER COLUMN directement)
    console.log('📝 [Migration] Suppression de la contrainte unique sur email...');
    
    // Pour SQLite, on doit recréer la table
    await prisma.$executeRaw`
      -- Créer une table temporaire avec la nouvelle structure
      CREATE TABLE utilisateurs_temp (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom_utilisateur TEXT UNIQUE NOT NULL,
        email TEXT,
        mot_de_passe_hash TEXT NOT NULL,
        role_id INTEGER,
        is_active BOOLEAN DEFAULT 1 NOT NULL,
        date_creation DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
        date_modification DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
        date_derniere_connexion DATETIME
      );
    `;

    // 2. Copier les données existantes
    console.log('📋 [Migration] Copie des données existantes...');
    await prisma.$executeRaw`
      INSERT INTO utilisateurs_temp (
        id, nom_utilisateur, email, mot_de_passe_hash, role_id, 
        is_active, date_creation, date_modification, date_derniere_connexion
      )
      SELECT 
        id, nom_utilisateur, email, mot_de_passe_hash, role_id,
        is_active, date_creation, date_modification, date_derniere_connexion
      FROM utilisateurs;
    `;

    // 3. Supprimer l'ancienne table et renommer la nouvelle
    console.log('🔄 [Migration] Remplacement de la table...');
    await prisma.$executeRaw`DROP TABLE utilisateurs;`;
    await prisma.$executeRaw`ALTER TABLE utilisateurs_temp RENAME TO utilisateurs;`;

    // 4. Recréer les index
    console.log('📊 [Migration] Recréation des index...');
    await prisma.$executeRaw`CREATE INDEX idx_utilisateurs_nom ON utilisateurs(nom_utilisateur);`;
    await prisma.$executeRaw`CREATE INDEX idx_utilisateurs_role ON utilisateurs(role_id);`;

    console.log('✅ [Migration] Migration terminée avec succès !');
    console.log('ℹ️ [Migration] L\'email est maintenant optionnel pour les utilisateurs');

  } catch (error) {
    console.error('❌ [Migration] Erreur lors de la migration:', error);
    throw error;
  } finally {
    await prisma.$disconnect();
  }
}

// Exécuter la migration si le script est appelé directement
if (require.main === module) {
  migrateEmailOptional()
    .then(() => {
      console.log('🎉 Migration email optionnel terminée !');
      process.exit(0);
    })
    .catch((error) => {
      console.error('💥 Échec de la migration:', error);
      process.exit(1);
    });
}

module.exports = { migrateEmailOptional };