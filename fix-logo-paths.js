#!/usr/bin/env node

/**
 * Script pour nettoyer les chemins de logo dans la base de données
 * Extrait juste le nom du fichier des chemins complets
 */

const { PrismaClient } = require('./src/config/prisma-client.js');

const prisma = new PrismaClient();

async function fixLogoPaths() {
  try {
    console.log('🔧 Nettoyage des chemins de logo...\n');

    // Récupérer tous les paramètres d'entreprise
    const allSettings = await prisma.parametresEntreprise.findMany();

    console.log(`📊 Trouvé ${allSettings.length} enregistrement(s) de paramètres d'entreprise\n`);

    for (const settings of allSettings) {
      if (settings.logo && settings.logo.trim().length > 0) {
        // Extraire juste le nom du fichier
        const fileName = settings.logo.split(/[\\\/]/).pop();
        
        if (fileName !== settings.logo) {
          console.log(`📝 Mise à jour ID ${settings.id}:`);
          console.log(`   AVANT: ${settings.logo}`);
          console.log(`   APRÈS: ${fileName}\n`);

          // Mettre à jour
          await prisma.parametresEntreprise.update({
            where: { id: settings.id },
            data: { logo: fileName }
          });

          console.log(`✅ Mise à jour réussie\n`);
        } else {
          console.log(`⏭️  ID ${settings.id}: Chemin déjà correct (${fileName})\n`);
        }
      } else {
        console.log(`⏭️  ID ${settings.id}: Pas de logo\n`);
      }
    }

    console.log('✅ Nettoyage terminé!');

  } catch (error) {
    console.error('❌ Erreur:', error);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

fixLogoPaths();
