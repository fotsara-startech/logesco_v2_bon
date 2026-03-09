/**
 * Script de seed pour initialiser une base de données propre
 * Crée uniquement les données essentielles pour le fonctionnement du système
 * NOTE: La suppression est gérée par --force-reset, ce script crée uniquement
 */

const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Initialisation de la base de données...\n');

  // 1. Créer le rôle admin
  console.log('[1/4] Création rôle administrateur...');
  const adminRole = await prisma.userRole.create({
    data: {
      nom: 'ADMIN',
      displayName: 'Administrateur',
      isAdmin: true,
      privileges: JSON.stringify({
        dashboard: { view: true },
        sales: { view: true, create: true, edit: true, delete: true },
        products: { view: true, create: true, edit: true, delete: true },
        inventory: { view: true, create: true, edit: true, delete: true },
        customers: { view: true, create: true, edit: true, delete: true },
        suppliers: { view: true, create: true, edit: true, delete: true },
        procurement: { view: true, create: true, edit: true, delete: true },
        expenses: { view: true, create: true, edit: true, delete: true },
        reports: { view: true, create: true, edit: true, delete: true },
        users: { view: true, create: true, edit: true, delete: true },
        roles: { view: true, create: true, edit: true, delete: true },
        settings: { view: true, create: true, edit: true, delete: true },
        cashRegister: { view: true, create: true, edit: true, delete: true },
        financialMovements: { view: true, create: true, edit: true, delete: true }
      })
    }
  });
  console.log(`✅ Rôle créé: ${adminRole.displayName}\n`);

  // 2. Créer l'utilisateur admin
  console.log('[2/4] Création utilisateur admin...');
  const hashedPassword = await bcrypt.hash('admin123', 10);
  
  const admin = await prisma.utilisateur.create({
    data: {
      nomUtilisateur: 'admin',
      motDePasseHash: hashedPassword,
      email: 'admin@logesco.local',
      roleId: adminRole.id,
      isActive: true
    }
  });
  console.log(`✅ Admin créé: ${admin.nomUtilisateur}\n`);

  // 3. Créer la caisse principale
  console.log('[3/4] Création caisse principale...');
  const mainCashRegister = await prisma.cashRegister.create({
    data: {
      nom: 'Caisse Principale',
      description: 'Caisse principale du système',
      isActive: true,
      soldeActuel: 0,
      soldeInitial: 0
    }
  });
  console.log(`✅ Caisse créée: ${mainCashRegister.nom}\n`);

  // 4. Créer les paramètres de l'entreprise par défaut
  console.log('[4/4] Création paramètres entreprise...');
  const companySettings = await prisma.parametresEntreprise.create({
    data: {
      nomEntreprise: 'Mon Entreprise',
      adresse: 'Adresse de l\'entreprise',
      telephone: '+000 00 00 00 00',
      email: 'contact@entreprise.com',
      nuiRccm: '',
      localisation: ''
    }
  });
  console.log(`✅ Paramètres créés: ${companySettings.nomEntreprise}\n`);

  console.log('========================================');
  console.log('✅ Base de données initialisée avec succès!');
  console.log('========================================\n');
  console.log('🔑 Identifiants par défaut:');
  console.log('   Utilisateur: admin');
  console.log('   Mot de passe: admin123\n');
  console.log('📊 Données créées:');
  console.log('   - 1 rôle administrateur');
  console.log('   - 1 utilisateur admin');
  console.log('   - 1 caisse principale');
  console.log('   - 1 configuration entreprise\n');
}

main()
  .catch((e) => {
    console.error('❌ Erreur lors du seed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
