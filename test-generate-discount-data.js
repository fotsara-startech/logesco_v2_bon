/**
 * Script pour générer des données de test avec remises - LOGESCO v2
 * Crée des produits avec remises et des ventes pour tester les rapports
 */

const axios = require('axios');

const API_BASE_URL = 'http://localhost:8080/api/v1';
let authToken = '';

// Configuration de test
const testConfig = {
  adminCredentials: {
    nomUtilisateur: 'admin',
    motDePasse: 'admin123'
  },
  testProducts: [
    {
      reference: 'SMARTPHONE001',
      nom: 'Smartphone Galaxy S24',
      description: 'Smartphone haut de gamme',
      prixUnitaire: 800000,
      prixAchat: 600000,
      remiseMaxAutorisee: 50000, // 50,000 FCFA max
      seuilStockMinimum: 5,
      estActif: true,
      estService: false
    },
    {
      reference: 'LAPTOP001',
      nom: 'Ordinateur Portable HP',
      description: 'Laptop professionnel',
      prixUnitaire: 1200000,
      prixAchat: 900000,
      remiseMaxAutorisee: 100000, // 100,000 FCFA max
      seuilStockMinimum: 3,
      estActif: true,
      estService: false
    },
    {
      reference: 'TABLET001',
      nom: 'Tablette iPad Air',
      description: 'Tablette Apple',
      prixUnitaire: 600000,
      prixAchat: 450000,
      remiseMaxAutorisee: 30000, // 30,000 FCFA max
      seuilStockMinimum: 5,
      estActif: true,
      estService: false
    }
  ],
  testSales: [
    {
      productRef: 'SMARTPHONE001',
      quantity: 1,
      discount: 40000,
      justification: 'Client VIP - remise fidélité'
    },
    {
      productRef: 'LAPTOP001',
      quantity: 1,
      discount: 80000,
      justification: 'Promotion Black Friday'
    },
    {
      productRef: 'TABLET001',
      quantity: 2,
      discount: 25000,
      justification: 'Achat en lot'
    },
    {
      productRef: 'SMARTPHONE001',
      quantity: 1,
      discount: 30000,
      justification: 'Négociation client'
    },
    {
      productRef: 'LAPTOP001',
      quantity: 1,
      discount: 60000,
      justification: 'Client entreprise'
    }
  ]
};

/**
 * Utilitaires
 */
function log(message, data = null) {
  console.log(`[${new Date().toISOString()}] ${message}`);
  if (data) {
    console.log(JSON.stringify(data, null, 2));
  }
}

function logError(message, error) {
  console.error(`[${new Date().toISOString()}] ❌ ${message}`);
  if (error.response) {
    console.error('Status:', error.response.status);
    console.error('Data:', error.response.data);
  } else {
    console.error('Error:', error.message);
  }
}

function logSuccess(message, data = null) {
  console.log(`[${new Date().toISOString()}] ✅ ${message}`);
  if (data) {
    console.log(JSON.stringify(data, null, 2));
  }
}

/**
 * Authentification
 */
async function authenticate() {
  try {
    log('🔐 Authentification...');
    
    const response = await axios.post(`${API_BASE_URL}/auth/login`, testConfig.adminCredentials);
    
    if (response.data.success && response.data.data.accessToken) {
      authToken = response.data.data.accessToken;
      logSuccess('Authentification réussie');
      return true;
    } else {
      logError('Échec de l\'authentification', new Error('Token non reçu'));
      return false;
    }
  } catch (error) {
    logError('Erreur d\'authentification', error);
    return false;
  }
}

/**
 * Configuration des headers avec authentification
 */
function getAuthHeaders() {
  return {
    'Authorization': `Bearer ${authToken}`,
    'Content-Type': 'application/json'
  };
}

/**
 * Créer les produits de test
 */
async function createTestProducts() {
  log('📦 Création des produits de test...');
  const createdProducts = [];

  for (const productData of testConfig.testProducts) {
    try {
      // Vérifier si le produit existe déjà
      const checkResponse = await axios.get(
        `${API_BASE_URL}/products/check-reference?reference=${productData.reference}`,
        { headers: getAuthHeaders() }
      );

      if (!checkResponse.data.data.is_unique) {
        log(`⚠️ Produit ${productData.reference} existe déjà, on passe au suivant`);
        continue;
      }

      const response = await axios.post(
        `${API_BASE_URL}/products`,
        productData,
        { headers: getAuthHeaders() }
      );

      if (response.data.success) {
        const product = response.data.data;
        createdProducts.push(product);
        logSuccess(`Produit créé: ${product.reference} - ${product.nom}`);
      }
    } catch (error) {
      logError(`Erreur création produit ${productData.reference}`, error);
    }
  }

  return createdProducts;
}

/**
 * Créer du stock pour les produits
 */
async function createStock(products) {
  log('📊 Création du stock pour les produits...');

  for (const product of products) {
    try {
      // Ajouter du stock via un ajustement
      const stockData = {
        produitId: product.id,
        changementQuantite: 50, // Ajouter 50 unités
        notes: `Stock initial pour tests de remises`
      };

      const response = await axios.post(
        `${API_BASE_URL}/inventory/adjustment`,
        stockData,
        { headers: getAuthHeaders() }
      );

      if (response.data.success) {
        logSuccess(`Stock créé pour ${product.reference}: 50 unités`);
      }
    } catch (error) {
      logError(`Erreur création stock pour ${product.reference}`, error);
    }
  }
}

/**
 * Créer les ventes avec remises
 */
async function createTestSales(products) {
  log('💰 Création des ventes avec remises...');
  const createdSales = [];

  for (const saleData of testConfig.testSales) {
    try {
      // Trouver le produit correspondant
      const product = products.find(p => p.reference === saleData.productRef);
      if (!product) {
        log(`⚠️ Produit ${saleData.productRef} non trouvé, on passe au suivant`);
        continue;
      }

      // Calculer les prix
      const prixAffiche = product.prixUnitaire;
      const remiseAppliquee = saleData.discount;
      const prixUnitaire = prixAffiche - remiseAppliquee;

      const saleRequest = {
        clientId: null, // Vente sans client
        modePaiement: 'comptant',
        montantRemise: 0,
        montantPaye: prixUnitaire * saleData.quantity,
        details: [
          {
            produitId: product.id,
            quantite: saleData.quantity,
            prixUnitaire: prixUnitaire,
            prixAffiche: prixAffiche,
            remiseAppliquee: remiseAppliquee,
            justificationRemise: saleData.justification
          }
        ]
      };

      const response = await axios.post(
        `${API_BASE_URL}/sales`,
        saleRequest,
        { headers: getAuthHeaders() }
      );

      if (response.data.success) {
        const sale = response.data.data;
        createdSales.push(sale);
        logSuccess(`Vente créée: ${sale.numeroVente} - Remise: ${remiseAppliquee} FCFA`);
      }
    } catch (error) {
      logError(`Erreur création vente pour ${saleData.productRef}`, error);
    }
  }

  return createdSales;
}

/**
 * Tester les rapports de remises
 */
async function testDiscountReports() {
  log('📊 Test des rapports de remises...');

  try {
    // Test du résumé des remises
    const summaryResponse = await axios.get(
      `${API_BASE_URL}/discount-reports/summary?groupBy=vendeur`,
      { headers: getAuthHeaders() }
    );

    if (summaryResponse.data.success) {
      logSuccess('Résumé des remises récupéré', {
        totalRemises: summaryResponse.data.data.totaux.totalRemises,
        nombreRemises: summaryResponse.data.data.totaux.nombreRemises,
        nombreGroupes: summaryResponse.data.data.groupes.length
      });
    }

    // Test du rapport par vendeur
    const vendorResponse = await axios.get(
      `${API_BASE_URL}/discount-reports/by-vendor`,
      { headers: getAuthHeaders() }
    );

    if (vendorResponse.data.success) {
      logSuccess('Rapport par vendeur récupéré', {
        nombreVentes: vendorResponse.data.data.ventes.length,
        nombreStats: vendorResponse.data.data.statistiques.length
      });
    }

    // Test du top des remises
    const topResponse = await axios.get(
      `${API_BASE_URL}/discount-reports/top-discounts?limit=5`,
      { headers: getAuthHeaders() }
    );

    if (topResponse.data.success) {
      logSuccess('Top des remises récupéré', {
        nombreRemises: topResponse.data.data.length
      });
    }

  } catch (error) {
    logError('Erreur test rapports', error);
  }
}

/**
 * Fonction principale
 */
async function generateDiscountTestData() {
  console.log('🚀 Génération des données de test pour les remises');
  console.log('=' .repeat(60));

  // Authentification
  if (!(await authenticate())) {
    console.log('❌ Impossible de continuer sans authentification');
    return;
  }

  try {
    // Créer les produits
    const products = await createTestProducts();
    if (products.length === 0) {
      log('⚠️ Aucun nouveau produit créé, utilisation des produits existants');
      
      // Récupérer les produits existants
      const existingResponse = await axios.get(
        `${API_BASE_URL}/products?limit=10`,
        { headers: getAuthHeaders() }
      );
      
      if (existingResponse.data.success) {
        products.push(...existingResponse.data.data.filter(p => 
          testConfig.testProducts.some(tp => tp.reference === p.reference)
        ));
      }
    }

    if (products.length === 0) {
      log('❌ Aucun produit disponible pour créer des ventes');
      return;
    }

    // Créer du stock
    await createStock(products);

    // Attendre un peu pour que le stock soit bien créé
    await new Promise(resolve => setTimeout(resolve, 2000));

    // Créer les ventes avec remises
    const sales = await createTestSales(products);

    // Tester les rapports
    await testDiscountReports();

    console.log('=' .repeat(60));
    console.log('✅ GÉNÉRATION TERMINÉE AVEC SUCCÈS !');
    console.log('=' .repeat(60));
    console.log(`📦 Produits créés/utilisés: ${products.length}`);
    console.log(`💰 Ventes avec remises créées: ${sales.length}`);
    console.log('');
    console.log('🎯 Vous pouvez maintenant tester la page de rapports de remises !');
    console.log('   Accédez à: Menu > Rapports > Rapports de Remises');

  } catch (error) {
    logError('Erreur générale', error);
  }
}

// Exécuter le script
if (require.main === module) {
  generateDiscountTestData().catch(error => {
    console.error('Erreur fatale:', error);
    process.exit(1);
  });
}

module.exports = { generateDiscountTestData };