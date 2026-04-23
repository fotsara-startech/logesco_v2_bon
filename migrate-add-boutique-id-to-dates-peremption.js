#!/usr/bin/env node

/**
 * Migration pour ajouter le champ boutiqueId à la table DatePeremption
 * et migrer les données existantes vers la boutique principale
 */

const { PrismaClient } = require('@prisma/client');
const { execSync } = require('child_process');
const path = require('path');

const prisma = new PrismaClient();

async function main() {
  console.log('🚀 Début de la migration: Ajout boutiqueId à DatePeremption');

  try {
    // 1. Vérifier s'il y a une boutique principale
    console.log('📋 Vérification de la boutique principale...');
    let boutiquePrincipale = await prisma.boutique.findFirst({
      where: { estPrincipale: true }
    });

    if (!boutiquePrincipale) {
      console.log('⚠️  Aucune boutique principale trouvée, création d\'une boutique par défaut...');
      boutiquePrincipale = await prisma.boutique.create({
        data: {
          nom: 'Boutique Principale',
          estPrincipale: true,
          isActive: true
        }
      });
      console.log(`✅ Boutique principale créée avec l'ID: ${boutiquePrincipale.id}`);
    } else {
      console.log(`✅ Boutique principale trouvée: ${boutiquePrincipale.nom} (ID: ${boutiquePrincipale.id})`);
    }

    // 2. Vérifier si la colonne boutiqueId existe déjà
    console.log('🔍 Vérification de la structure de la table DatePeremption...');
    
    try {
      // Tenter de lire une date de péremption avec boutiqueId
      await prisma.$queryRaw`SELECT boutiqueId FROM dates_peremption LIMIT 1`;
      console.log('✅ La colonne boutiqueId existe déjà dans la table DatePeremption');
      
      // Vérifier s'il y a des enregistrements sans boutiqueId
      const countWithoutBoutique = await prisma.$queryRaw`
        SELECT COUNT(*) as count FROM dates_peremption WHERE boutique_id IS NULL
      `;
      
      if (countWithoutBoutique[0].count > 0) {
        console.log(`📝 Mise à jour de ${countWithoutBoutique[0].count} enregistrements sans boutiqueId...`);
        
        await prisma.$executeRaw`
          UPDATE dates_peremption 
          SET boutique_id = ${boutiquePrincipale.id}
          WHERE boutique_id IS NULL
        `;
        
        console.log('✅ Enregistrements mis à jour avec succès');
      } else {
        console.log('✅ Tous les enregistrements ont déjà un boutiqueId');
      }
      
    } catch (error) {
      console.log('📝 La colonne boutiqueId n\'existe pas encore, génération de la migration...');
      
      // 3. Générer et appliquer la migration Prisma
      console.log('🔄 Génération de la migration Prisma...');
      
      try {
        execSync('npx prisma migrate dev --name add_boutique_id_to_dates_peremption --create-only', {
          cwd: __dirname,
          stdio: 'inherit'
        });
        console.log('✅ Migration générée avec succès');
      } catch (migrateError) {
        console.log('⚠️  Erreur lors de la génération de la migration, tentative de migration manuelle...');
        
        // Migration manuelle si Prisma migrate échoue
        console.log('📝 Application de la migration manuelle...');
        
        // Ajouter la colonne
        await prisma.$executeRaw`ALTER TABLE dates_peremption ADD COLUMN boutique_id INTEGER`;
        
        // Mettre à jour les données existantes
        await prisma.$executeRaw`
          UPDATE dates_peremption 
          SET boutique_id = ${boutiquePrincipale.id}
          WHERE boutique_id IS NULL
        `;
        
        // Rendre la colonne NOT NULL
        await prisma.$executeRaw`
          UPDATE dates_peremption SET boutique_id = ${boutiquePrincipale.id} WHERE boutique_id IS NULL
        `;
        
        // Créer l'index
        await prisma.$executeRaw`CREATE INDEX idx_dates_peremption_boutique ON dates_peremption(boutique_id)`;
        await prisma.$executeRaw`CREATE INDEX idx_dates_peremption_boutique_date ON dates_peremption(boutique_id, date_peremption)`;
        
        console.log('✅ Migration manuelle appliquée avec succès');
      }
    }

    // 4. Vérification finale
    console.log('🔍 Vérification finale...');
    
    const totalDates = await prisma.datePeremption.count();
    const datesAvecBoutique = await prisma.datePeremption.count({
      where: { boutiqueId: { not: null } }
    });
    
    console.log(`📊 Statistiques finales:`);
    console.log(`   - Total dates de péremption: ${totalDates}`);
    console.log(`   - Dates avec boutiqueId: ${datesAvecBoutique}`);
    console.log(`   - Boutique principale ID: ${boutiquePrincipale.id}`);
    
    if (totalDates === datesAvecBoutique) {
      console.log('✅ Migration terminée avec succès! Toutes les dates ont un boutiqueId.');
    } else {
      console.log('⚠️  Attention: Certaines dates n\'ont pas de boutiqueId');
    }

    // 5. Régénérer le client Prisma
    console.log('🔄 Régénération du client Prisma...');
    try {
      execSync('npx prisma generate', {
        cwd: __dirname,
        stdio: 'inherit'
      });
      console.log('✅ Client Prisma régénéré avec succès');
    } catch (generateError) {
      console.log('⚠️  Erreur lors de la régénération du client Prisma:', generateError.message);
    }

  } catch (error) {
    console.error('❌ Erreur lors de la migration:', error);
    throw error;
  } finally {
    await prisma.$disconnect();
  }
}

// Exécuter la migration
if (require.main === module) {
  main()
    .then(() => {
      console.log('🎉 Migration terminée avec succès!');
      process.exit(0);
    })
    .catch((error) => {
      console.error('💥 Échec de la migration:', error);
      process.exit(1);
    });
}

module.exports = { main };