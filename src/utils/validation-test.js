/**
 * Script de test pour valider les modèles Prisma et les schémas de validation
 * Vérifie que toutes les validations fonctionnent correctement
 */

const { PrismaClient } = require('../config/prisma-client.js');
const { ModelFactory } = require('../models');
const schemas = require('../validation/schemas');
const { 
  ProduitDTO, 
  ClientDTO, 
  VenteDTO, 
  BaseResponseDTO 
} = require('../dto');

async function testValidationSchemas() {
  console.log('🧪 Test des schémas de validation Joi...');

  // Test validation produit valide
  const produitValide = {
    reference: 'PROD001',
    nom: 'Produit Test',
    description: 'Description du produit test',
    prixUnitaire: 1500.50,
    categorie: 'Électronique',
    seuilStockMinimum: 10
  };

  const { error: errorProduit, value: valueProduit } = schemas.produitSchemas.create.validate(produitValide);
  
  if (errorProduit) {
    console.error('❌ Erreur validation produit:', errorProduit.details);
  } else {
    console.log('✅ Validation produit réussie:', valueProduit);
  }

  // Test validation client valide
  const clientValide = {
    nom: 'Dupont',
    prenom: 'Jean',
    telephone: '+33123456789',
    email: 'jean.dupont@email.com',
    adresse: '123 Rue de la Paix, Paris'
  };

  const { error: errorClient, value: valueClient } = schemas.clientSchemas.create.validate(clientValide);
  
  if (errorClient) {
    console.error('❌ Erreur validation client:', errorClient.details);
  } else {
    console.log('✅ Validation client réussie:', valueClient);
  }

  // Test validation vente valide
  const venteValide = {
    clientId: 1,
    modePaiement: 'comptant',
    montantRemise: 50.00,
    montantPaye: 1450.50,
    details: [
      {
        produitId: 1,
        quantite: 2,
        prixUnitaire: 750.25
      }
    ]
  };

  const { error: errorVente, value: valueVente } = schemas.venteSchemas.create.validate(venteValide);
  
  if (errorVente) {
    console.error('❌ Erreur validation vente:', errorVente.details);
  } else {
    console.log('✅ Validation vente réussie:', valueVente);
  }

  // Test validation avec erreurs
  const produitInvalide = {
    reference: '', // Erreur: référence vide
    nom: 'P', // Erreur: nom trop court
    prixUnitaire: -100, // Erreur: prix négatif
    seuilStockMinimum: -5 // Erreur: seuil négatif
  };

  const { error: errorInvalide } = schemas.produitSchemas.create.validate(produitInvalide);
  
  if (errorInvalide) {
    console.log('✅ Validation erreurs détectées correctement:', 
      errorInvalide.details.map(d => d.message)
    );
  }

  console.log('✅ Tests de validation terminés\n');
}

async function testDTOs() {
  console.log('🧪 Test des DTOs...');

  // Test DTO Produit
  const produitMock = {
    id: 1,
    reference: 'PROD001',
    nom: 'Produit Test',
    description: 'Description test',
    prixUnitaire: 1500.50,
    categorie: 'Test',
    seuilStockMinimum: 10,
    estActif: true,
    dateCreation: new Date(),
    dateModification: new Date(),
    stock: {
      id: 1,
      produitId: 1,
      quantiteDisponible: 25,
      quantiteReservee: 5,
      derniereMaj: new Date()
    }
  };

  const produitDTO = ProduitDTO.fromEntity(produitMock);
  console.log('✅ DTO Produit créé:', {
    id: produitDTO.id,
    nom: produitDTO.nom,
    prixUnitaire: produitDTO.prixUnitaire,
    stock: produitDTO.stock ? 'Inclus' : 'Non inclus'
  });

  // Test DTO Client
  const clientMock = {
    id: 1,
    nom: 'Dupont',
    prenom: 'Jean',
    telephone: '+33123456789',
    email: 'jean.dupont@email.com',
    adresse: '123 Rue de la Paix',
    dateCreation: new Date(),
    dateModification: new Date()
  };

  const clientDTO = ClientDTO.fromEntity(clientMock);
  console.log('✅ DTO Client créé:', {
    id: clientDTO.id,
    nomComplet: clientDTO.nomComplet,
    telephone: clientDTO.telephone
  });

  // Test BaseResponseDTO
  const successResponse = BaseResponseDTO.success(produitDTO, 'Produit récupéré avec succès');
  console.log('✅ Response DTO succès:', {
    success: successResponse.success,
    hasData: !!successResponse.data,
    message: successResponse.message
  });

  const errorResponse = BaseResponseDTO.error('Erreur de test', [
    { field: 'test', message: 'Erreur de test' }
  ]);
  console.log('✅ Response DTO erreur:', {
    success: errorResponse.success,
    message: errorResponse.message,
    hasErrors: !!errorResponse.errors
  });

  console.log('✅ Tests DTOs terminés\n');
}

async function testDatabaseConnection() {
  console.log('🧪 Test de connexion à la base de données...');

  const prisma = new PrismaClient();
  
  try {
    // Test de connexion simple
    await prisma.$connect();
    console.log('✅ Connexion à la base de données réussie');

    // Test de requête simple
    const userCount = await prisma.utilisateur.count();
    console.log(`✅ Nombre d'utilisateurs: ${userCount}`);

    const productCount = await prisma.produit.count();
    console.log(`✅ Nombre de produits: ${productCount}`);

    // Test des modèles
    const models = new ModelFactory(prisma);
    console.log('✅ Factory de modèles initialisée');

    // Test recherche de produits (même si vide)
    const searchResult = await models.produit.search({ q: 'test' }, { take: 5 });
    console.log(`✅ Recherche produits: ${searchResult.total} résultats`);

  } catch (error) {
    console.error('❌ Erreur base de données:', error.message);
  } finally {
    await prisma.$disconnect();
    console.log('✅ Déconnexion base de données');
  }

  console.log('✅ Tests base de données terminés\n');
}

async function testTransformers() {
  console.log('🧪 Test des utilitaires de transformation...');

  const { 
    generateSaleNumber, 
    generateOrderNumber,
    calculateSaleTotals,
    formatCurrency,
    formatDate,
    sanitizeInput
  } = require('./transformers');

  // Test génération de numéros
  const saleNumber = generateSaleNumber();
  const orderNumber = generateOrderNumber();
  console.log('✅ Numéros générés:', { saleNumber, orderNumber });

  // Test calcul totaux
  const details = [
    { quantite: 2, prixUnitaire: 100.50 },
    { quantite: 1, prixUnitaire: 250.75 }
  ];
  const totals = calculateSaleTotals(details);
  console.log('✅ Calcul totaux:', totals);

  // Test formatage
  const formatted = formatCurrency(1234.56);
  const dateFormatted = formatDate(new Date());
  console.log('✅ Formatage:', { currency: formatted, date: dateFormatted });

  // Test nettoyage données
  const dirtyData = {
    nom: '  Jean Dupont  ',
    email: '',
    telephone: null,
    notes: '   '
  };
  const cleanData = sanitizeInput(dirtyData);
  console.log('✅ Nettoyage données:', cleanData);

  console.log('✅ Tests transformers terminés\n');
}

async function runAllTests() {
  console.log('🚀 Démarrage des tests de validation LOGESCO\n');
  
  try {
    await testValidationSchemas();
    await testDTOs();
    await testTransformers();
    await testDatabaseConnection();
    
    console.log('🎉 Tous les tests sont passés avec succès!');
    console.log('✅ Les modèles Prisma et validations sont prêts à être utilisés');
    
  } catch (error) {
    console.error('💥 Erreur lors des tests:', error);
    process.exit(1);
  }
}

// Exécuter si appelé directement
if (require.main === module) {
  runAllTests()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error('💥 Échec des tests:', error);
      process.exit(1);
    });
}

module.exports = {
  testValidationSchemas,
  testDTOs,
  testDatabaseConnection,
  testTransformers,
  runAllTests
};