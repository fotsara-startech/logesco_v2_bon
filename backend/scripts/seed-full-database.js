/**
 * Script de remplissage complet de la base de données avec des données de test
 * Utilisation: node backend/scripts/seed-full-database.js
 */

const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcrypt');

const prisma = new PrismaClient();

// Fonction utilitaire pour générer des dates aléatoires
function randomDate(start, end) {
  return new Date(start.getTime() + Math.random() * (end.getTime() - start.getTime()));
}

// Fonction pour générer un numéro de référence unique
function generateReference(prefix) {
  const timestamp = Date.now();
  const random = Math.floor(Math.random() * 1000).toString().padStart(3, '0');
  return `${prefix}-${timestamp}-${random}`;
}

async function main() {
  console.log('🚀 Début du remplissage de la base de données...\n');

  try {
    // 1. Créer les rôles utilisateur
    console.log('📋 Création des rôles utilisateur...');
    const roles = await createUserRoles();
    console.log(`✅ ${roles.length} rôles créés\n`);

    // 2. Créer les utilisateurs
    console.log('👥 Création des utilisateurs...');
    const users = await createUsers(roles);
    console.log(`✅ ${users.length} utilisateurs créés\n`);

    // 3. Créer les paramètres entreprise
    console.log('🏢 Création des paramètres entreprise...');
    await createCompanySettings();
    console.log('✅ Paramètres entreprise créés\n');

    // 4. Créer les catégories de produits
    console.log('📦 Création des catégories...');
    const categories = await createCategories();
    console.log(`✅ ${categories.length} catégories créées\n`);

    // 5. Créer les produits
    console.log('🛍️ Création des produits...');
    const products = await createProducts(categories);
    console.log(`✅ ${products.length} produits créés\n`);

    // 6. Créer les fournisseurs
    console.log('🚚 Création des fournisseurs...');
    const suppliers = await createSuppliers();
    console.log(`✅ ${suppliers.length} fournisseurs créés\n`);

    // 7. Créer les clients
    console.log('👤 Création des clients...');
    const clients = await createClients();
    console.log(`✅ ${clients.length} clients créés\n`);

    // 8. Créer les commandes d'approvisionnement
    console.log('📋 Création des commandes d\'approvisionnement...');
    const orders = await createSupplyOrders(suppliers, products);
    console.log(`✅ ${orders.length} commandes créées\n`);

    // 9. Créer les ventes
    console.log('💰 Création des ventes...');
    const sales = await createSales(clients, products, users);
    console.log(`✅ ${sales.length} ventes créées\n`);

    // 10. Créer les caisses
    console.log('💵 Création des caisses...');
    const cashRegisters = await createCashRegisters(users);
    console.log(`✅ ${cashRegisters.length} caisses créées\n`);

    // 11. Créer les catégories de mouvements financiers
    console.log('💸 Création des catégories de mouvements financiers...');
    const movementCategories = await createMovementCategories();
    console.log(`✅ ${movementCategories.length} catégories créées\n`);

    // 12. Créer les mouvements financiers
    console.log('📊 Création des mouvements financiers...');
    const movements = await createFinancialMovements(movementCategories, users);
    console.log(`✅ ${movements.length} mouvements créés\n`);

    // 13. Créer les inventaires
    console.log('📝 Création des inventaires...');
    const inventories = await createInventories(categories, products, users);
    console.log(`✅ ${inventories.length} inventaires créés\n`);

    console.log('\n🎉 Base de données remplie avec succès !');
    console.log('\n📊 Résumé:');
    console.log(`   - ${roles.length} rôles`);
    console.log(`   - ${users.length} utilisateurs`);
    console.log(`   - ${categories.length} catégories`);
    console.log(`   - ${products.length} produits`);
    console.log(`   - ${suppliers.length} fournisseurs`);
    console.log(`   - ${clients.length} clients`);
    console.log(`   - ${orders.length} commandes`);
    console.log(`   - ${sales.length} ventes`);
    console.log(`   - ${cashRegisters.length} caisses`);
    console.log(`   - ${movementCategories.length} catégories de mouvements`);
    console.log(`   - ${movements.length} mouvements financiers`);
    console.log(`   - ${inventories.length} inventaires`);

  } catch (error) {
    console.error('❌ Erreur lors du remplissage:', error);
    throw error;
  } finally {
    await prisma.$disconnect();
  }
}

// ============================================
// FONCTIONS DE CRÉATION DES DONNÉES
// ============================================

async function createUserRoles() {
  const rolesData = [
    {
      nom: 'admin',
      displayName: 'Administrateur',
      isAdmin: true,
      privileges: JSON.stringify({
        users: { create: true, read: true, update: true, delete: true },
        products: { create: true, read: true, update: true, delete: true },
        sales: { create: true, read: true, update: true, delete: true },
        inventory: { create: true, read: true, update: true, delete: true },
        reports: { create: true, read: true, update: true, delete: true },
        settings: { create: true, read: true, update: true, delete: true }
      })
    },
    {
      nom: 'manager',
      displayName: 'Gérant',
      isAdmin: false,
      privileges: JSON.stringify({
        users: { create: false, read: true, update: false, delete: false },
        products: { create: true, read: true, update: true, delete: false },
        sales: { create: true, read: true, update: true, delete: false },
        inventory: { create: true, read: true, update: true, delete: false },
        reports: { create: true, read: true, update: false, delete: false },
        settings: { create: false, read: true, update: false, delete: false }
      })
    },
    {
      nom: 'cashier',
      displayName: 'Caissier',
      isAdmin: false,
      privileges: JSON.stringify({
        users: { create: false, read: false, update: false, delete: false },
        products: { create: false, read: true, update: false, delete: false },
        sales: { create: true, read: true, update: false, delete: false },
        inventory: { create: false, read: true, update: false, delete: false },
        reports: { create: false, read: true, update: false, delete: false },
        settings: { create: false, read: false, update: false, delete: false }
      })
    },
    {
      nom: 'stock_manager',
      displayName: 'Gestionnaire de Stock',
      isAdmin: false,
      privileges: JSON.stringify({
        users: { create: false, read: false, update: false, delete: false },
        products: { create: true, read: true, update: true, delete: false },
        sales: { create: false, read: true, update: false, delete: false },
        inventory: { create: true, read: true, update: true, delete: false },
        reports: { create: false, read: true, update: false, delete: false },
        settings: { create: false, read: false, update: false, delete: false }
      })
    }
  ];

  const roles = [];
  for (const roleData of rolesData) {
    const role = await prisma.userRole.upsert({
      where: { nom: roleData.nom },
      update: roleData,
      create: roleData
    });
    roles.push(role);
  }

  return roles;
}

async function createUsers(roles) {
  const hashedPassword = await bcrypt.hash('admin123', 10);
  
  const usersData = [
    {
      nomUtilisateur: 'admin',
      email: 'admin@logesco.com',
      motDePasseHash: hashedPassword,
      roleId: roles.find(r => r.nom === 'admin').id,
      isActive: true
    },
    {
      nomUtilisateur: 'gerant',
      email: 'gerant@logesco.com',
      motDePasseHash: hashedPassword,
      roleId: roles.find(r => r.nom === 'manager').id,
      isActive: true
    },
    {
      nomUtilisateur: 'caissier1',
      email: 'caissier1@logesco.com',
      motDePasseHash: hashedPassword,
      roleId: roles.find(r => r.nom === 'cashier').id,
      isActive: true
    },
    {
      nomUtilisateur: 'caissier2',
      email: 'caissier2@logesco.com',
      motDePasseHash: hashedPassword,
      roleId: roles.find(r => r.nom === 'cashier').id,
      isActive: true
    },
    {
      nomUtilisateur: 'stock_manager',
      email: 'stock@logesco.com',
      motDePasseHash: hashedPassword,
      roleId: roles.find(r => r.nom === 'stock_manager').id,
      isActive: true
    }
  ];

  const users = [];
  for (const userData of usersData) {
    const user = await prisma.utilisateur.upsert({
      where: { email: userData.email },
      update: userData,
      create: userData
    });
    users.push(user);
  }

  return users;
}

async function createCompanySettings() {
  return await prisma.parametresEntreprise.upsert({
    where: { id: 1 },
    update: {
      nomEntreprise: 'LOGESCO SARL',
      adresse: '123 Avenue du Commerce, Kinshasa',
      localisation: 'Kinshasa, RDC',
      telephone: '+243 123 456 789',
      email: 'contact@logesco.com',
      nuiRccm: 'CD/KIN/RCCM/12-A-12345'
    },
    create: {
      nomEntreprise: 'LOGESCO SARL',
      adresse: '123 Avenue du Commerce, Kinshasa',
      localisation: 'Kinshasa, RDC',
      telephone: '+243 123 456 789',
      email: 'contact@logesco.com',
      nuiRccm: 'CD/KIN/RCCM/12-A-12345'
    }
  });
}

async function createCategories() {
  const categoriesData = [
    { nom: 'Boissons', description: 'Boissons gazeuses, jus, eau' },
    { nom: 'Alimentation', description: 'Produits alimentaires de base' },
    { nom: 'Hygiène', description: 'Produits d\'hygiène et de beauté' },
    { nom: 'Électronique', description: 'Appareils et accessoires électroniques' },
    { nom: 'Vêtements', description: 'Vêtements et accessoires' },
    { nom: 'Papeterie', description: 'Fournitures de bureau et scolaires' },
    { nom: 'Ménage', description: 'Produits d\'entretien ménager' },
    { nom: 'Boulangerie', description: 'Pain et pâtisseries' }
  ];

  const categories = [];
  for (const catData of categoriesData) {
    const category = await prisma.category.upsert({
      where: { nom: catData.nom },
      update: catData,
      create: catData
    });
    categories.push(category);
  }

  return categories;
}

async function createProducts(categories) {
  const productsData = [
    // Boissons
    { nom: 'Coca-Cola 33cl', reference: 'BV-001', prixUnitaire: 1.5, prixAchat: 0.8, categorieId: categories.find(c => c.nom === 'Boissons').id, codeBarre: '5449000000996', seuilStockMinimum: 50 },
    { nom: 'Fanta Orange 33cl', reference: 'BV-002', prixUnitaire: 1.5, prixAchat: 0.8, categorieId: categories.find(c => c.nom === 'Boissons').id, codeBarre: '5449000054227', seuilStockMinimum: 50 },
    { nom: 'Sprite 33cl', reference: 'BV-003', prixUnitaire: 1.5, prixAchat: 0.8, categorieId: categories.find(c => c.nom === 'Boissons').id, codeBarre: '5449000054234', seuilStockMinimum: 50 },
    { nom: 'Eau Minérale 1.5L', reference: 'BV-004', prixUnitaire: 1.0, prixAchat: 0.5, categorieId: categories.find(c => c.nom === 'Boissons').id, codeBarre: '3274080005003', seuilStockMinimum: 100 },
    { nom: 'Jus Tropical 1L', reference: 'BV-005', prixUnitaire: 2.5, prixAchat: 1.5, categorieId: categories.find(c => c.nom === 'Boissons').id, codeBarre: '3124480191502', seuilStockMinimum: 30 },
    
    // Alimentation
    { nom: 'Riz 1kg', reference: 'AL-001', prixUnitaire: 2.0, prixAchat: 1.2, categorieId: categories.find(c => c.nom === 'Alimentation').id, codeBarre: '8712566123456', seuilStockMinimum: 100 },
    { nom: 'Huile Végétale 1L', reference: 'AL-002', prixUnitaire: 3.5, prixAchat: 2.0, categorieId: categories.find(c => c.nom === 'Alimentation').id, codeBarre: '3017620401015', seuilStockMinimum: 50 },
    { nom: 'Sucre 1kg', reference: 'AL-003', prixUnitaire: 1.8, prixAchat: 1.0, categorieId: categories.find(c => c.nom === 'Alimentation').id, codeBarre: '3017620425004', seuilStockMinimum: 80 },
    { nom: 'Farine 1kg', reference: 'AL-004', prixUnitaire: 1.5, prixAchat: 0.9, categorieId: categories.find(c => c.nom === 'Alimentation').id, codeBarre: '3228857000050', seuilStockMinimum: 60 },
    { nom: 'Pâtes Alimentaires 500g', reference: 'AL-005', prixUnitaire: 1.2, prixAchat: 0.7, categorieId: categories.find(c => c.nom === 'Alimentation').id, codeBarre: '8076809513203', seuilStockMinimum: 70 },
    
    // Hygiène
    { nom: 'Savon de Marseille', reference: 'HY-001', prixUnitaire: 2.0, prixAchat: 1.0, categorieId: categories.find(c => c.nom === 'Hygiène').id, codeBarre: '3045140105502', seuilStockMinimum: 40 },
    { nom: 'Dentifrice 75ml', reference: 'HY-002', prixUnitaire: 2.5, prixAchat: 1.5, categorieId: categories.find(c => c.nom === 'Hygiène').id, codeBarre: '8714789939018', seuilStockMinimum: 50 },
    { nom: 'Shampoing 400ml', reference: 'HY-003', prixUnitaire: 4.0, prixAchat: 2.5, categorieId: categories.find(c => c.nom === 'Hygiène').id, codeBarre: '3600550284003', seuilStockMinimum: 30 },
    { nom: 'Papier Toilette x4', reference: 'HY-004', prixUnitaire: 3.0, prixAchat: 1.8, categorieId: categories.find(c => c.nom === 'Hygiène').id, codeBarre: '5410076881406', seuilStockMinimum: 60 },
    
    // Électronique
    { nom: 'Chargeur USB-C', reference: 'EL-001', prixUnitaire: 15.0, prixAchat: 8.0, categorieId: categories.find(c => c.nom === 'Électronique').id, codeBarre: '6942507310019', seuilStockMinimum: 20 },
    { nom: 'Écouteurs Bluetooth', reference: 'EL-002', prixUnitaire: 25.0, prixAchat: 15.0, categorieId: categories.find(c => c.nom === 'Électronique').id, codeBarre: '6942507310026', seuilStockMinimum: 15 },
    { nom: 'Câble HDMI 2m', reference: 'EL-003', prixUnitaire: 10.0, prixAchat: 5.0, categorieId: categories.find(c => c.nom === 'Électronique').id, codeBarre: '6942507310033', seuilStockMinimum: 25 },
    
    // Vêtements
    { nom: 'T-Shirt Coton M', reference: 'VT-001', prixUnitaire: 12.0, prixAchat: 6.0, categorieId: categories.find(c => c.nom === 'Vêtements').id, codeBarre: '5901234123457', seuilStockMinimum: 20 },
    { nom: 'Jean Homme 32', reference: 'VT-002', prixUnitaire: 35.0, prixAchat: 20.0, categorieId: categories.find(c => c.nom === 'Vêtements').id, codeBarre: '5901234123464', seuilStockMinimum: 10 },
    
    // Papeterie
    { nom: 'Cahier 100 pages', reference: 'PA-001', prixUnitaire: 1.5, prixAchat: 0.8, categorieId: categories.find(c => c.nom === 'Papeterie').id, codeBarre: '3086123456789', seuilStockMinimum: 100 },
    { nom: 'Stylo Bille Bleu', reference: 'PA-002', prixUnitaire: 0.5, prixAchat: 0.2, categorieId: categories.find(c => c.nom === 'Papeterie').id, codeBarre: '3086123456796', seuilStockMinimum: 200 },
    { nom: 'Crayon HB x12', reference: 'PA-003', prixUnitaire: 3.0, prixAchat: 1.5, categorieId: categories.find(c => c.nom === 'Papeterie').id, codeBarre: '3086123456802', seuilStockMinimum: 50 },
    
    // Ménage
    { nom: 'Javel 1L', reference: 'MN-001', prixUnitaire: 2.0, prixAchat: 1.0, categorieId: categories.find(c => c.nom === 'Ménage').id, codeBarre: '3228857000067', seuilStockMinimum: 40 },
    { nom: 'Éponge x3', reference: 'MN-002', prixUnitaire: 1.5, prixAchat: 0.8, categorieId: categories.find(c => c.nom === 'Ménage').id, codeBarre: '3228857000074', seuilStockMinimum: 60 },
    
    // Boulangerie
    { nom: 'Pain Blanc', reference: 'BL-001', prixUnitaire: 0.8, prixAchat: 0.4, categorieId: categories.find(c => c.nom === 'Boulangerie').id, codeBarre: '2000000000001', seuilStockMinimum: 50 },
    { nom: 'Croissant', reference: 'BL-002', prixUnitaire: 1.2, prixAchat: 0.6, categorieId: categories.find(c => c.nom === 'Boulangerie').id, codeBarre: '2000000000002', seuilStockMinimum: 30 }
  ];

  const products = [];
  for (const prodData of productsData) {
    const product = await prisma.produit.upsert({
      where: { reference: prodData.reference },
      update: prodData,
      create: prodData
    });

    // Créer le stock initial
    await prisma.stock.upsert({
      where: { produitId: product.id },
      update: { quantiteDisponible: Math.floor(Math.random() * 200) + 50 },
      create: {
        produitId: product.id,
        quantiteDisponible: Math.floor(Math.random() * 200) + 50,
        quantiteReservee: 0
      }
    });

    products.push(product);
  }

  return products;
}

async function createSuppliers() {
  const suppliersData = [
    {
      nom: 'Distributeur Boissons SA',
      personneContact: 'Jean Mukendi',
      telephone: '+243 812 345 678',
      email: 'contact@distrib-boissons.cd',
      adresse: 'Avenue Lumumba, Kinshasa'
    },
    {
      nom: 'Alimentation Générale SARL',
      personneContact: 'Marie Kabongo',
      telephone: '+243 823 456 789',
      email: 'info@alim-generale.cd',
      adresse: 'Boulevard du 30 Juin, Kinshasa'
    },
    {
      nom: 'Hygiène & Beauté Plus',
      personneContact: 'Paul Tshisekedi',
      telephone: '+243 834 567 890',
      email: 'contact@hygiene-beaute.cd',
      adresse: 'Avenue Kasavubu, Kinshasa'
    },
    {
      nom: 'Électronique Import',
      personneContact: 'Sophie Mbuyi',
      telephone: '+243 845 678 901',
      email: 'info@electro-import.cd',
      adresse: 'Marché Central, Kinshasa'
    },
    {
      nom: 'Textile & Mode',
      personneContact: 'André Kalala',
      telephone: '+243 856 789 012',
      email: 'contact@textile-mode.cd',
      adresse: 'Avenue Victoire, Kinshasa'
    }
  ];

  const suppliers = [];
  for (const suppData of suppliersData) {
    const supplier = await prisma.fournisseur.create({
      data: suppData
    });

    // Créer un compte fournisseur
    await prisma.compteFournisseur.create({
      data: {
        fournisseurId: supplier.id,
        soldeActuel: -(Math.random() * 5000),
        limiteCredit: 10000
      }
    });

    suppliers.push(supplier);
  }

  return suppliers;
}

async function createClients() {
  const clientsData = [
    { nom: 'Mbala', prenom: 'Joseph', telephone: '+243 812 111 111', email: 'joseph.mbala@email.cd', adresse: 'Gombe, Kinshasa' },
    { nom: 'Nkulu', prenom: 'Grace', telephone: '+243 823 222 222', email: 'grace.nkulu@email.cd', adresse: 'Lemba, Kinshasa' },
    { nom: 'Kasongo', prenom: 'Pierre', telephone: '+243 834 333 333', email: 'pierre.kasongo@email.cd', adresse: 'Ngaliema, Kinshasa' },
    { nom: 'Mwamba', prenom: 'Christine', telephone: '+243 845 444 444', email: 'christine.mwamba@email.cd', adresse: 'Bandalungwa, Kinshasa' },
    { nom: 'Ilunga', prenom: 'Daniel', telephone: '+243 856 555 555', email: 'daniel.ilunga@email.cd', adresse: 'Kalamu, Kinshasa' },
    { nom: 'Kabila', prenom: 'Françoise', telephone: '+243 867 666 666', email: 'francoise.kabila@email.cd', adresse: 'Limete, Kinshasa' },
    { nom: 'Tshombe', prenom: 'Albert', telephone: '+243 878 777 777', email: 'albert.tshombe@email.cd', adresse: 'Kintambo, Kinshasa' },
    { nom: 'Mulamba', prenom: 'Jeanne', telephone: '+243 889 888 888', email: 'jeanne.mulamba@email.cd', adresse: 'Matete, Kinshasa' },
    { nom: 'Kalonji', prenom: 'Robert', telephone: '+243 890 999 999', email: 'robert.kalonji@email.cd', adresse: 'Ngaba, Kinshasa' },
    { nom: 'Lukaku', prenom: 'Sarah', telephone: '+243 801 000 000', email: 'sarah.lukaku@email.cd', adresse: 'Selembao, Kinshasa' }
  ];

  const clients = [];
  for (const clientData of clientsData) {
    const client = await prisma.client.create({
      data: clientData
    });

    // Créer un compte client pour certains
    if (Math.random() > 0.5) {
      await prisma.compteClient.create({
        data: {
          clientId: client.id,
          soldeActuel: -(Math.random() * 1000),
          limiteCredit: 2000
        }
      });
    }

    clients.push(client);
  }

  return clients;
}

async function createSupplyOrders(suppliers, products) {
  const orders = [];
  const statuses = ['en_attente', 'confirmee', 'livree', 'annulee'];
  const startDate = new Date('2024-01-01');
  const endDate = new Date();

  for (let i = 0; i < 15; i++) {
    const supplier = suppliers[Math.floor(Math.random() * suppliers.length)];
    const status = statuses[Math.floor(Math.random() * statuses.length)];
    const orderDate = randomDate(startDate, endDate);
    
    const order = await prisma.commandeApprovisionnement.create({
      data: {
        numeroCommande: generateReference('CMD'),
        fournisseurId: supplier.id,
        statut: status,
        dateCommande: orderDate,
        dateLivraisonPrevue: new Date(orderDate.getTime() + 7 * 24 * 60 * 60 * 1000),
        modePaiement: Math.random() > 0.5 ? 'credit' : 'comptant',
        notes: `Commande ${i + 1} - ${supplier.nom}`
      }
    });

    // Ajouter des détails de commande
    const numProducts = Math.floor(Math.random() * 5) + 3;
    let montantTotal = 0;

    for (let j = 0; j < numProducts; j++) {
      const product = products[Math.floor(Math.random() * products.length)];
      const quantite = Math.floor(Math.random() * 100) + 20;
      const coutUnitaire = product.prixAchat || product.prixUnitaire * 0.6;

      await prisma.detailCommandeApprovisionnement.create({
        data: {
          commandeId: order.id,
          produitId: product.id,
          quantiteCommandee: quantite,
          quantiteRecue: status === 'livree' ? quantite : 0,
          coutUnitaire: coutUnitaire
        }
      });

      montantTotal += quantite * coutUnitaire;

      // Mettre à jour le stock si livré
      if (status === 'livree') {
        await prisma.stock.update({
          where: { produitId: product.id },
          data: {
            quantiteDisponible: {
              increment: quantite
            }
          }
        });

        // Créer un mouvement de stock
        await prisma.mouvementStock.create({
          data: {
            produitId: product.id,
            typeMouvement: 'entree',
            changementQuantite: quantite,
            referenceId: order.id,
            typeReference: 'commande',
            notes: `Réception commande ${order.numeroCommande}`
          }
        });
      }
    }

    // Mettre à jour le montant total
    await prisma.commandeApprovisionnement.update({
      where: { id: order.id },
      data: { montantTotal }
    });

    orders.push(order);
  }

  return orders;
}

async function createSales(clients, products, users) {
  const sales = [];
  const statuses = ['terminee', 'en_attente', 'annulee'];
  const paymentModes = ['comptant', 'credit', 'mobile_money', 'carte'];
  const startDate = new Date('2024-01-01');
  const endDate = new Date();

  for (let i = 0; i < 50; i++) {
    const client = Math.random() > 0.3 ? clients[Math.floor(Math.random() * clients.length)] : null;
    const vendeur = users[Math.floor(Math.random() * users.length)];
    const status = statuses[Math.floor(Math.random() * statuses.length)];
    const paymentMode = paymentModes[Math.floor(Math.random() * paymentModes.length)];
    const saleDate = randomDate(startDate, endDate);

    const sale = await prisma.vente.create({
      data: {
        numeroVente: generateReference('VTE'),
        clientId: client?.id,
        vendeurId: vendeur.id,
        dateVente: saleDate,
        sousTotal: 0,
        montantRemise: 0,
        montantTotal: 0,
        statut: status,
        modePaiement: paymentMode,
        montantPaye: 0,
        montantRestant: 0
      }
    });

    // Ajouter des détails de vente
    const numProducts = Math.floor(Math.random() * 5) + 1;
    let sousTotal = 0;
    let montantRemise = 0;

    for (let j = 0; j < numProducts; j++) {
      const product = products[Math.floor(Math.random() * products.length)];
      const quantite = Math.floor(Math.random() * 5) + 1;
      const remise = Math.random() > 0.7 ? Math.random() * 10 : 0;
      const prixUnitaire = product.prixUnitaire;
      const prixTotal = quantite * prixUnitaire * (1 - remise / 100);

      await prisma.detailVente.create({
        data: {
          venteId: sale.id,
          produitId: product.id,
          quantite: quantite,
          prixUnitaire: prixUnitaire,
          prixAffiche: prixUnitaire,
          remiseAppliquee: remise,
          justificationRemise: remise > 0 ? 'Promotion client fidèle' : null,
          prixTotal: prixTotal
        }
      });

      sousTotal += quantite * prixUnitaire;
      montantRemise += quantite * prixUnitaire * (remise / 100);

      // Mettre à jour le stock si vente terminée
      if (status === 'terminee') {
        await prisma.stock.update({
          where: { produitId: product.id },
          data: {
            quantiteDisponible: {
              decrement: quantite
            }
          }
        });

        // Créer un mouvement de stock
        await prisma.mouvementStock.create({
          data: {
            produitId: product.id,
            typeMouvement: 'sortie',
            changementQuantite: -quantite,
            referenceId: sale.id,
            typeReference: 'vente',
            notes: `Vente ${sale.numeroVente}`
          }
        });
      }
    }

    const montantTotal = sousTotal - montantRemise;
    const montantPaye = paymentMode === 'comptant' ? montantTotal : (Math.random() > 0.5 ? montantTotal : montantTotal * 0.5);
    const montantRestant = montantTotal - montantPaye;

    // Mettre à jour la vente
    await prisma.vente.update({
      where: { id: sale.id },
      data: {
        sousTotal,
        montantRemise,
        montantTotal,
        montantPaye,
        montantRestant
      }
    });

    // Créer un reçu pour les ventes terminées
    if (status === 'terminee') {
      await prisma.historiqueRecu.create({
        data: {
          venteId: sale.id,
          numeroRecu: generateReference('RCU'),
          formatImpression: Math.random() > 0.5 ? 'thermal' : 'a4',
          contenuRecu: JSON.stringify({
            vente: sale.numeroVente,
            date: saleDate,
            montant: montantTotal
          }),
          utilisateurId: vendeur.id
        }
      });
    }

    sales.push(sale);
  }

  return sales;
}

async function createCashRegisters(users) {
  const cashRegistersData = [
    { nom: 'Caisse Principale', description: 'Caisse principale du magasin', soldeInitial: 1000, utilisateurId: users.find(u => u.nomUtilisateur === 'caissier1')?.id },
    { nom: 'Caisse Secondaire', description: 'Caisse secondaire', soldeInitial: 500, utilisateurId: users.find(u => u.nomUtilisateur === 'caissier2')?.id },
    { nom: 'Caisse Express', description: 'Caisse pour paiements rapides', soldeInitial: 300, utilisateurId: users.find(u => u.nomUtilisateur === 'caissier1')?.id }
  ];

  const cashRegisters = [];
  for (const cashData of cashRegistersData) {
    const cashRegister = await prisma.cashRegister.create({
      data: {
        ...cashData,
        soldeActuel: cashData.soldeInitial + Math.random() * 2000,
        isActive: true,
        dateOuverture: new Date()
      }
    });

    // Créer des mouvements de caisse
    const movementTypes = ['ouverture', 'entree', 'sortie', 'vente'];
    for (let i = 0; i < 10; i++) {
      const type = movementTypes[Math.floor(Math.random() * movementTypes.length)];
      const montant = type === 'sortie' ? -(Math.random() * 100) : Math.random() * 200;

      await prisma.cashMovement.create({
        data: {
          caisseId: cashRegister.id,
          type: type,
          montant: montant,
          description: `Mouvement ${type} - ${new Date().toLocaleDateString()}`,
          utilisateurId: cashData.utilisateurId,
          metadata: JSON.stringify({ source: 'seed' })
        }
      });
    }

    cashRegisters.push(cashRegister);
  }

  return cashRegisters;
}

async function createMovementCategories() {
  const categoriesData = [
    { nom: 'salaires', displayName: 'Salaires', color: '#EF4444', icon: 'people', isDefault: true },
    { nom: 'loyer', displayName: 'Loyer', color: '#F59E0B', icon: 'home', isDefault: true },
    { nom: 'electricite', displayName: 'Électricité', color: '#10B981', icon: 'flash', isDefault: true },
    { nom: 'eau', displayName: 'Eau', color: '#3B82F6', icon: 'water', isDefault: true },
    { nom: 'transport', displayName: 'Transport', color: '#8B5CF6', icon: 'car', isDefault: false },
    { nom: 'fournitures', displayName: 'Fournitures', color: '#EC4899', icon: 'cart', isDefault: false },
    { nom: 'maintenance', displayName: 'Maintenance', color: '#6B7280', icon: 'construct', isDefault: false },
    { nom: 'marketing', displayName: 'Marketing', color: '#14B8A6', icon: 'megaphone', isDefault: false },
    { nom: 'autres', displayName: 'Autres dépenses', color: '#64748B', icon: 'ellipsis-horizontal', isDefault: false }
  ];

  const categories = [];
  for (const catData of categoriesData) {
    const category = await prisma.movementCategory.upsert({
      where: { nom: catData.nom },
      update: catData,
      create: catData
    });
    categories.push(category);
  }

  return categories;
}

async function createFinancialMovements(categories, users) {
  const movements = [];
  const startDate = new Date('2024-01-01');
  const endDate = new Date();

  for (let i = 0; i < 30; i++) {
    const category = categories[Math.floor(Math.random() * categories.length)];
    const user = users[Math.floor(Math.random() * users.length)];
    const date = randomDate(startDate, endDate);
    const montant = Math.random() * 1000 + 50;

    const movement = await prisma.financialMovement.create({
      data: {
        reference: generateReference('MVT'),
        montant: montant,
        categorieId: category.id,
        description: `Paiement ${category.displayName} - ${date.toLocaleDateString()}`,
        date: date,
        utilisateurId: user.id,
        notes: `Mouvement financier créé automatiquement`
      }
    });

    movements.push(movement);
  }

  return movements;
}

async function createInventories(categories, products, users) {
  const inventories = [];
  const statuses = ['BROUILLON', 'EN_COURS', 'TERMINE', 'CLOTURE'];
  const types = ['PARTIEL', 'TOTAL'];

  for (let i = 0; i < 5; i++) {
    const type = types[Math.floor(Math.random() * types.length)];
    const status = statuses[Math.floor(Math.random() * statuses.length)];
    const category = type === 'PARTIEL' ? categories[Math.floor(Math.random() * categories.length)] : null;
    const user = users[Math.floor(Math.random() * users.length)];

    const inventory = await prisma.stockInventory.create({
      data: {
        nom: `Inventaire ${type} ${i + 1}`,
        description: `Inventaire ${type.toLowerCase()} du ${new Date().toLocaleDateString()}`,
        type: type,
        status: status,
        categorieId: category?.id,
        utilisateurId: user.id,
        dateDebut: status !== 'BROUILLON' ? new Date() : null,
        dateFin: status === 'TERMINE' || status === 'CLOTURE' ? new Date() : null
      }
    });

    // Ajouter des items d'inventaire
    const productsToInventory = type === 'PARTIEL' && category
      ? products.filter(p => p.categorieId === category.id)
      : products;

    const numItems = Math.min(Math.floor(Math.random() * 15) + 5, productsToInventory.length);

    for (let j = 0; j < numItems; j++) {
      const product = productsToInventory[j];
      const stock = await prisma.stock.findUnique({
        where: { produitId: product.id }
      });

      const quantiteSysteme = stock?.quantiteDisponible || 0;
      const quantiteComptee = status !== 'BROUILLON' ? quantiteSysteme + Math.floor(Math.random() * 20) - 10 : null;
      const ecart = quantiteComptee !== null ? quantiteComptee - quantiteSysteme : null;

      await prisma.inventoryItem.create({
        data: {
          inventaireId: inventory.id,
          produitId: product.id,
          quantiteSysteme: quantiteSysteme,
          quantiteComptee: quantiteComptee,
          ecart: ecart,
          prixUnitaire: product.prixUnitaire,
          prixAchat: product.prixAchat,
          commentaire: ecart && Math.abs(ecart) > 5 ? 'Écart significatif détecté' : null,
          dateComptage: status !== 'BROUILLON' ? new Date() : null,
          utilisateurComptageId: status !== 'BROUILLON' ? user.id : null
        }
      });

      // Ajuster le stock si l'inventaire est clôturé
      if (status === 'CLOTURE' && ecart !== null && ecart !== 0) {
        await prisma.stock.update({
          where: { produitId: product.id },
          data: {
            quantiteDisponible: quantiteComptee
          }
        });

        // Créer un mouvement de stock
        await prisma.mouvementStock.create({
          data: {
            produitId: product.id,
            typeMouvement: ecart > 0 ? 'ajustement_positif' : 'ajustement_negatif',
            changementQuantite: ecart,
            referenceId: inventory.id,
            typeReference: 'inventaire',
            notes: `Ajustement suite à inventaire ${inventory.nom}`
          }
        });
      }
    }

    inventories.push(inventory);
  }

  return inventories;
}

// Exécuter le script
main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  });
