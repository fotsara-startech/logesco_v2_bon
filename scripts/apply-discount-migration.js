/**
 * Script pour appliquer la migration du système de remises
 * LOGESCO v2 - Système de remises sécurisées
 */

const { PrismaClient } = require('@prisma/client');
const fs = require('fs');
const path = require('path');

const prisma = new PrismaClient();

async function applyDiscountMigration() {
  console.log('🚀 Application de la migration du système de remises...');
  console.log('=' .repeat(60));

  try {
    // Lire le fichier de migration SQL
    const migrationPath = path.join(__dirname, '..', 'backend', 'prisma', 'migrations', 'add_discount_system', 'migration.sql');
    
    if (!fs.existsSync(migrationPath)) {
      console.log('📝 Création du fichier de migration...');
      
      const migrationSQL = `
-- Migration pour ajouter le système de remises sécurisées

-- Ajouter la colonne remise_max_autorisee à la table produits
ALTER TABLE produits ADD COLUMN remise_max_autorisee REAL DEFAULT 0 NOT NULL;

-- Ajouter les colonnes de remise à la table details_ventes
ALTER TABLE details_ventes ADD COLUMN prix_affiche REAL NOT NULL DEFAULT 0;
ALTER TABLE details_ventes ADD COLUMN remise_appliquee REAL DEFAULT 0 NOT NULL;
ALTER TABLE details_ventes ADD COLUMN justification_remise TEXT;

-- Ajouter la colonne vendeur_id à la table ventes
ALTER TABLE ventes ADD COLUMN vendeur_id INTEGER;

-- Créer l'index pour les ventes par vendeur
CREATE INDEX idx_ventes_vendeur_date ON ventes(vendeur_id, date_vente);

-- Mettre à jour les données existantes
-- Copier prix_unitaire vers prix_affiche pour les enregistrements existants
UPDATE details_ventes SET prix_affiche = prix_unitaire WHERE prix_affiche = 0;

-- Commentaire pour la documentation
-- Cette migration ajoute :
-- 1. remise_max_autorisee : montant maximum de remise autorisé par produit (en FCFA)
-- 2. prix_affiche : prix de base du produit avant remise
-- 3. remise_appliquee : montant de la remise appliquée (en FCFA)
-- 4. justification_remise : justification textuelle optionnelle
-- 5. vendeur_id : référence vers l'utilisateur qui a effectué la vente
      `.trim();
      
      // Créer le répertoire de migration s'il n'existe pas
      const migrationDir = path.dirname(migrationPath);
      if (!fs.existsSync(migrationDir)) {
        fs.mkdirSync(migrationDir, { recursive: true });
      }
      
      fs.writeFileSync(migrationPath, migrationSQL);
      console.log('✅ Fichier de migration créé');
    }

    console.log('📊 Vérification de l\'état actuel de la base de données...');

    // Vérifier si les colonnes existent déjà
    const tableInfo = await prisma.$queryRaw`PRAGMA table_info(produits);`;
    const hasRemiseColumn = tableInfo.some(col => col.name === 'remise_max_autorisee');

    if (hasRemiseColumn) {
      console.log('✅ La migration semble déjà appliquée');
      
      // Vérifier quelques données
      const productsWithDiscount = await prisma.produit.count({
        where: {
          remiseMaxAutorisee: {
            gt: 0
          }
        }
      });
      
      console.log(`📈 Produits avec remise configurée: ${productsWithDiscount}`);
      return;
    }

    console.log('🔧 Application des modifications de schéma...');

    // Appliquer les modifications une par une pour éviter les erreurs
    try {
      console.log('  - Ajout de remise_max_autorisee à produits...');
      await prisma.$executeRaw`ALTER TABLE produits ADD COLUMN remise_max_autorisee REAL DEFAULT 0 NOT NULL;`;
    } catch (error) {
      if (!error.message.includes('duplicate column name')) {
        throw error;
      }
      console.log('    ⚠️  Colonne déjà existante');
    }

    try {
      console.log('  - Ajout de prix_affiche à details_ventes...');
      await prisma.$executeRaw`ALTER TABLE details_ventes ADD COLUMN prix_affiche REAL NOT NULL DEFAULT 0;`;
    } catch (error) {
      if (!error.message.includes('duplicate column name')) {
        throw error;
      }
      console.log('    ⚠️  Colonne déjà existante');
    }

    try {
      console.log('  - Ajout de remise_appliquee à details_ventes...');
      await prisma.$executeRaw`ALTER TABLE details_ventes ADD COLUMN remise_appliquee REAL DEFAULT 0 NOT NULL;`;
    } catch (error) {
      if (!error.message.includes('duplicate column name')) {
        throw error;
      }
      console.log('    ⚠️  Colonne déjà existante');
    }

    try {
      console.log('  - Ajout de justification_remise à details_ventes...');
      await prisma.$executeRaw`ALTER TABLE details_ventes ADD COLUMN justification_remise TEXT;`;
    } catch (error) {
      if (!error.message.includes('duplicate column name')) {
        throw error;
      }
      console.log('    ⚠️  Colonne déjà existante');
    }

    try {
      console.log('  - Ajout de vendeur_id à ventes...');
      await prisma.$executeRaw`ALTER TABLE ventes ADD COLUMN vendeur_id INTEGER;`;
    } catch (error) {
      if (!error.message.includes('duplicate column name')) {
        throw error;
      }
      console.log('    ⚠️  Colonne déjà existante');
    }

    try {
      console.log('  - Création de l\'index vendeur_date...');
      await prisma.$executeRaw`CREATE INDEX IF NOT EXISTS idx_ventes_vendeur_date ON ventes(vendeur_id, date_vente);`;
    } catch (error) {
      console.log('    ⚠️  Index déjà existant ou erreur:', error.message);
    }

    console.log('🔄 Mise à jour des données existantes...');
    
    // Mettre à jour prix_affiche pour les enregistrements existants
    const updateResult = await prisma.$executeRaw`
      UPDATE details_ventes 
      SET prix_affiche = prix_unitaire 
      WHERE prix_affiche = 0;
    `;
    
    console.log(`  - ${updateResult} enregistrements mis à jour`);

    console.log('🧪 Test de la nouvelle structure...');
    
    // Tester la création d'un produit avec remise
    const testProduct = await prisma.produit.create({
      data: {
        reference: 'TEST-MIGRATION-001',
        nom: 'Test Migration Remise',
        prixUnitaire: 1000,
        remiseMaxAutorisee: 100,
        estActif: true
      }
    });
    
    console.log(`  - Produit test créé: ${testProduct.reference}`);
    
    // Supprimer le produit test
    await prisma.produit.delete({
      where: { id: testProduct.id }
    });
    
    console.log('  - Produit test supprimé');

    console.log('✅ Migration appliquée avec succès !');
    console.log('');
    console.log('📋 Résumé des modifications:');
    console.log('  • Colonne remise_max_autorisee ajoutée aux produits');
    console.log('  • Colonnes prix_affiche, remise_appliquee, justification_remise ajoutées aux détails de vente');
    console.log('  • Colonne vendeur_id ajoutée aux ventes');
    console.log('  • Index sur vendeur_id et date_vente créé');
    console.log('  • Données existantes mises à jour');

  } catch (error) {
    console.error('❌ Erreur lors de l\'application de la migration:', error);
    throw error;
  } finally {
    await prisma.$disconnect();
  }
}

// Exécuter la migration si le script est appelé directement
if (require.main === module) {
  applyDiscountMigration()
    .then(() => {
      console.log('🎉 Migration terminée avec succès !');
      process.exit(0);
    })
    .catch((error) => {
      console.error('💥 Échec de la migration:', error);
      process.exit(1);
    });
}

module.exports = { applyDiscountMigration };