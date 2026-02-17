const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function ensureBaseData() {
  try {
    console.log('🔍 Vérification des données de base...');

    // 1. Créer des catégories de base si elles n'existent pas
    const categoryCount = await prisma.category.count();
    
    if (categoryCount === 0) {
      console.log('📝 Création des catégories de base...');
      
      const baseCategories = [
        {
          nom: 'Électronique',
          description: 'Appareils électroniques et accessoires'
        },
        {
          nom: 'Vêtements',
          description: 'Vêtements et accessoires de mode'
        },
        {
          nom: 'Alimentation',
          description: 'Produits alimentaires et boissons'
        },
        {
          nom: 'Maison & Jardin',
          description: 'Articles pour la maison et le jardin'
        },
        {
          nom: 'Sport & Loisirs',
          description: 'Articles de sport et de loisirs'
        }
      ];

      for (const category of baseCategories) {
        await prisma.category.create({
          data: category
        });
        console.log(`✓ Catégorie créée: ${category.nom}`);
      }
      
      console.log('✅ Catégories de base créées');
    } else {
      console.log(`✅ ${categoryCount} catégories existantes trouvées`);
    }

    // 2. Créer des catégories de mouvements financiers de base
    const movementCategoryCount = await prisma.movementCategory.count();
    
    if (movementCategoryCount === 0) {
      console.log('📝 Création des catégories de mouvements financiers...');
      
      const baseMovementCategories = [
        {
          nom: 'achat_marchandises',
          displayName: 'Achat de marchandises',
          color: '#EF4444',
          icon: 'shopping-cart',
          isDefault: true
        },
        {
          nom: 'frais_generaux',
          displayName: 'Frais généraux',
          color: '#F59E0B',
          icon: 'receipt'
        },
        {
          nom: 'salaires',
          displayName: 'Salaires et charges',
          color: '#8B5CF6',
          icon: 'users'
        },
        {
          nom: 'loyer',
          displayName: 'Loyer et charges locatives',
          color: '#06B6D4',
          icon: 'home'
        },
        {
          nom: 'transport',
          displayName: 'Transport et déplacements',
          color: '#10B981',
          icon: 'truck'
        }
      ];

      for (const category of baseMovementCategories) {
        await prisma.movementCategory.create({
          data: category
        });
        console.log(`✓ Catégorie de mouvement créée: ${category.displayName}`);
      }
      
      console.log('✅ Catégories de mouvements financiers créées');
    } else {
      console.log(`✅ ${movementCategoryCount} catégories de mouvements existantes trouvées`);
    }

    // 3. Créer une caisse principale par défaut
    const cashRegisterCount = await prisma.cashRegister.count();
    
    if (cashRegisterCount === 0) {
      console.log('💵 Création de la caisse principale...');
      
      // Récupérer l'utilisateur admin pour l'assigner à la caisse
      const adminUser = await prisma.utilisateur.findFirst({
        where: { nomUtilisateur: 'admin' }
      });
      
      const caisseData = {
        nom: 'Caisse Principale',
        description: 'Caisse principale créée automatiquement',
        soldeInitial: 0.0,
        soldeActuel: 0.0,
        isActive: true,
        dateOuverture: new Date(),
        utilisateurId: adminUser?.id || null
      };
      
      const caisse = await prisma.cashRegister.create({
        data: caisseData
      });
      
      // Créer un mouvement d'ouverture
      await prisma.cashMovement.create({
        data: {
          caisseId: caisse.id,
          type: 'ouverture',
          montant: 0.0,
          description: 'Ouverture automatique de la caisse principale',
          utilisateurId: adminUser?.id || null,
          metadata: JSON.stringify({ 
            source: 'auto_creation',
            created_at: new Date().toISOString()
          })
        }
      });
      
      console.log(`✅ Caisse principale créée avec ID: ${caisse.id}`);
      console.log(`   - Nom: ${caisse.nom}`);
      console.log(`   - Solde initial: ${caisse.soldeInitial} FCFA`);
      console.log(`   - Assignée à: ${adminUser?.nomUtilisateur || 'Aucun utilisateur'}`);
    } else {
      console.log(`✅ ${cashRegisterCount} caisse(s) existante(s) trouvée(s)`);
    }

    console.log('🎉 Données de base vérifiées et créées si nécessaire !');

  } catch (error) {
    console.error('❌ Erreur lors de la vérification/création des données de base:', error);
    throw error;
  } finally {
    await prisma.$disconnect();
  }
}

// Exécuter le script si appelé directement
if (require.main === module) {
  ensureBaseData()
    .then(() => {
      console.log('✨ Vérification des données de base terminée');
      process.exit(0);
    })
    .catch((error) => {
      console.error('💥 Échec de la vérification des données de base:', error);
      process.exit(1);
    });
}

module.exports = { ensureBaseData };