#!/usr/bin/env node

/**
 * Script simple pour vérifier la structure de la base de données
 */

const { PrismaClient } = require('@prisma/client');

async function checkDatabaseStructure() {
  console.log('🔍 Vérification de la structure de la base de données...');
  
  try {
    // Utiliser une requête SQL brute pour vérifier la structure
    const { execSync } = require('child_process');
    const path = require('path');
    
    // Vérifier si la colonne boutiqueId existe
    console.log('📋 Vérification de la table dates_peremption...');
    
    // Créer une connexion Prisma simple
    const prisma = new PrismaClient();
    
    try {
      // Essayer de faire une requête simple sur la table
      const result = await prisma.$queryRaw`SELECT sql FROM sqlite_master WHERE type='table' AND name='dates_peremption'`;
      console.log('✅ Structure de la table dates_peremption:');
      console.log(result[0]?.sql || 'Table non trouvée');
      
      // Vérifier s'il y a des dates de péremption
      const count = await prisma.$queryRaw`SELECT COUNT(*) as count FROM dates_peremption`;
      console.log(`📊 Nombre de dates de péremption: ${count[0].count}`);
      
      // Essayer de voir les colonnes
      const columns = await prisma.$queryRaw`PRAGMA table_info(dates_peremption)`;
      console.log('📋 Colonnes de la table:');
      columns.forEach(col => {
        console.log(`   - ${col.name} (${col.type}) ${col.notnull ? 'NOT NULL' : ''} ${col.pk ? 'PRIMARY KEY' : ''}`);
      });
      
    } catch (error) {
      console.error('❌ Erreur lors de la vérification:', error.message);
    } finally {
      await prisma.$disconnect();
    }
    
  } catch (error) {
    console.error('💥 Erreur:', error);
  }
}

// Exécuter la vérification
if (require.main === module) {
  checkDatabaseStructure()
    .then(() => {
      console.log('✅ Vérification terminée');
      process.exit(0);
    })
    .catch((error) => {
      console.error('💥 Échec:', error);
      process.exit(1);
    });
}

module.exports = { checkDatabaseStructure };