/**
 * Tests pour les endpoints des produits
 * Teste les routes CRUD des produits
 */

const axios = require('axios');

const BASE_URL = 'http://localhost:8080/api/v1';

class ProductsAPITester {
  constructor() {
    this.authToken = null;
    this.testProducts = [];
  }

  /**
   * Authentification pour les tests
   */
  async authenticate() {
    console.log('🔐 Authentification pour les tests...');
    
    try {
      // Créer un utilisateur de test
      const registerResponse = await axios.post(`${BASE_URL}/auth/register`, {
        nomUtilisateur: 'products_tester',
        email: 'products@logesco.com',
        motDePasse: 'password123'
      });

      this.authToken = registerResponse.data.data.accessToken;
      console.log('✅ Authentification réussie');
      return true;

    } catch (error) {
      // Si l'utilisateur existe déjà, essayer de se connecter
      try {
        const loginResponse = await axios.post(`${BASE_URL}/auth/login`, {
          nomUtilisateur: 'products_tester',
          motDePasse: 'password123'
        });

        this.authToken = loginResponse.data.data.accessToken;
        console.log('✅ Connexion réussie');
        return true;

      } catch (loginError) {
        console.error('❌ Erreur authentification:', loginError.response?.data || loginError.message);
        return false;
      }
    }
  }

  /**
   * Headers d'authentification
   */
  getAuthHeaders() {
    return {
      'Authorization': `Bearer ${this.authToken}`,
      'Content-Type': 'application/json'
    };
  }

  /**
   * Test création de produit
   */
  async testCreateProduct() {
    console.log('\n📝 Test: Création de produit');
    
    try {
      const produitData = {
        reference: 'TEST001',
        nom: 'Produit Test API',
        description: 'Description du produit test',
        prixUnitaire: 150.75,
        categorie: 'Test',
        seuilStockMinimum: 10
      };

      const response = await axios.post(
        `${BASE_URL}/products`,
        produitData,
        { headers: this.getAuthHeaders() }
      );

      console.log('✅ Produit créé:', {
        id: response.data.data.id,
        reference: response.data.data.reference,
        nom: response.data.data.nom,
        status: response.status
      });

      this.testProducts.push(response.data.data);
      return true;

    } catch (error) {
      console.error('❌ Erreur création produit:', error.response?.data || error.message);
      return false;
    }
  }

  /**
   * Test récupération de produit
   */
  async testGetProduct() {
    console.log('\n🔍 Test: Récupération de produit');
    
    if (this.testProducts.length === 0) {
      console.log('⚠️  Aucun produit de test disponible');
      return false;
    }

    try {
      const productId = this.testProducts[0].id;
      const response = await axios.get(`${BASE_URL}/products/${productId}`);

      console.log('✅ Produit récupéré:', {
        id: response.data.data.id,
        nom: response.data.data.nom,
        hasStock: !!response.data.data.stock
      });

      return true;

    } catch (error) {
      console.error('❌ Erreur récupération produit:', error.response?.data || error.message);
      return false;
    }
  }

  /**
   * Test liste des produits
   */
  async testListProducts() {
    console.log('\n📋 Test: Liste des produits');
    
    try {
      const response = await axios.get(`${BASE_URL}/products?page=1&limit=10`);

      console.log('✅ Liste récupérée:', {
        count: response.data.data.length,
        pagination: response.data.pagination,
        status: response.status
      });

      return true;

    } catch (error) {
      console.error('❌ Erreur liste produits:', error.response?.data || error.message);
      return false;
    }
  }

  /**
   * Test recherche de produits
   */
  async testSearchProducts() {
    console.log('\n🔎 Test: Recherche de produits');
    
    try {
      const response = await axios.get(`${BASE_URL}/products?q=Test&page=1&limit=5`);

      console.log('✅ Recherche réussie:', {
        query: 'Test',
        results: response.data.data.length,
        total: response.data.pagination?.total || 0
      });

      return true;

    } catch (error) {
      console.error('❌ Erreur recherche produits:', error.response?.data || error.message);
      return false;
    }
  }

  /**
   * Test mise à jour de produit
   */
  async testUpdateProduct() {
    console.log('\n✏️ Test: Mise à jour de produit');
    
    if (this.testProducts.length === 0) {
      console.log('⚠️  Aucun produit de test disponible');
      return false;
    }

    try {
      const productId = this.testProducts[0].id;
      const updateData = {
        nom: 'Produit Test API Modifié',
        prixUnitaire: 200.00,
        description: 'Description mise à jour'
      };

      const response = await axios.put(
        `${BASE_URL}/products/${productId}`,
        updateData,
        { headers: this.getAuthHeaders() }
      );

      console.log('✅ Produit mis à jour:', {
        id: response.data.data.id,
        nouveauNom: response.data.data.nom,
        nouveauPrix: response.data.data.prixUnitaire
      });

      return true;

    } catch (error) {
      console.error('❌ Erreur mise à jour produit:', error.response?.data || error.message);
      return false;
    }
  }

  /**
   * Test suggestions de recherche
   */
  async testSearchSuggestions() {
    console.log('\n💡 Test: Suggestions de recherche');
    
    try {
      const response = await axios.get(`${BASE_URL}/products/search/suggestions?q=Te`);

      console.log('✅ Suggestions récupérées:', {
        query: 'Te',
        suggestions: response.data.data.length
      });

      return true;

    } catch (error) {
      console.error('❌ Erreur suggestions:', error.response?.data || error.message);
      return false;
    }
  }

  /**
   * Test catégories
   */
  async testGetCategories() {
    console.log('\n🏷️ Test: Récupération des catégories');
    
    try {
      const response = await axios.get(`${BASE_URL}/products/categories`);

      console.log('✅ Catégories récupérées:', {
        count: response.data.data.length,
        categories: response.data.data
      });

      return true;

    } catch (error) {
      console.error('❌ Erreur catégories:', error.response?.data || error.message);
      return false;
    }
  }

  /**
   * Test validation des erreurs
   */
  async testValidationErrors() {
    console.log('\n❌ Test: Validation des erreurs');
    
    try {
      // Test avec données invalides
      const invalidData = {
        reference: '', // Erreur: référence vide
        nom: 'P', // Erreur: nom trop court
        prixUnitaire: -100 // Erreur: prix négatif
      };

      await axios.post(
        `${BASE_URL}/products`,
        invalidData,
        { headers: this.getAuthHeaders() }
      );

      console.log('❌ Ce test aurait dû échouer');
      return false;

    } catch (error) {
      if (error.response?.status === 400) {
        console.log('✅ Validation des erreurs fonctionne:', error.response.data.message);
        return true;
      } else {
        console.error('❌ Erreur inattendue:', error.response?.data || error.message);
        return false;
      }
    }
  }

  /**
   * Test suppression de produit
   */
  async testDeleteProduct() {
    console.log('\n🗑️ Test: Suppression de produit');
    
    if (this.testProducts.length === 0) {
      console.log('⚠️  Aucun produit de test disponible');
      return false;
    }

    try {
      const productId = this.testProducts[0].id;
      const response = await axios.delete(
        `${BASE_URL}/products/${productId}`,
        { headers: this.getAuthHeaders() }
      );

      console.log('✅ Produit supprimé:', {
        id: productId,
        message: response.data.message
      });

      return true;

    } catch (error) {
      console.error('❌ Erreur suppression produit:', error.response?.data || error.message);
      return false;
    }
  }

  /**
   * Nettoyage des données de test
   */
  async cleanup() {
    console.log('\n🧹 Nettoyage des données de test...');
    
    // Les produits de test seront nettoyés par le script de nettoyage général
    console.log('✅ Nettoyage terminé');
  }

  /**
   * Exécute tous les tests
   */
  async runAllTests() {
    console.log('🚀 Tests des endpoints produits LOGESCO v2\n');
    
    try {
      // Authentification
      const authenticated = await this.authenticate();
      if (!authenticated) {
        throw new Error('Échec de l\'authentification');
      }

      const tests = [
        { name: 'Création produit', fn: () => this.testCreateProduct() },
        { name: 'Récupération produit', fn: () => this.testGetProduct() },
        { name: 'Liste produits', fn: () => this.testListProducts() },
        { name: 'Recherche produits', fn: () => this.testSearchProducts() },
        { name: 'Mise à jour produit', fn: () => this.testUpdateProduct() },
        { name: 'Suggestions recherche', fn: () => this.testSearchSuggestions() },
        { name: 'Catégories', fn: () => this.testGetCategories() },
        { name: 'Validation erreurs', fn: () => this.testValidationErrors() },
        { name: 'Suppression produit', fn: () => this.testDeleteProduct() }
      ];

      let passed = 0;
      let failed = 0;

      for (const test of tests) {
        try {
          const result = await test.fn();
          if (result) {
            passed++;
          } else {
            failed++;
          }
        } catch (error) {
          console.error(`💥 Erreur test ${test.name}:`, error.message);
          failed++;
        }
      }

      await this.cleanup();

      console.log('\n📊 Résultats des tests produits:');
      console.log(`✅ Tests réussis: ${passed}`);
      console.log(`❌ Tests échoués: ${failed}`);
      console.log(`📈 Taux de réussite: ${Math.round((passed / (passed + failed)) * 100)}%`);

      if (failed === 0) {
        console.log('\n🎉 Tous les tests des endpoints produits sont passés!');
        return true;
      } else {
        console.log('\n⚠️  Certains tests ont échoué');
        return false;
      }

    } catch (error) {
      console.error('💥 Erreur lors des tests:', error.message);
      console.log('🔧 Assurez-vous que le serveur est démarré sur le port 8080');
      return false;
    }
  }
}

// Exécuter si appelé directement
if (require.main === module) {
  const tester = new ProductsAPITester();
  tester.runAllTests()
    .then((success) => {
      process.exit(success ? 0 : 1);
    })
    .catch((error) => {
      console.error('💥 Échec des tests produits:', error);
      process.exit(1);
    });
}

module.exports = ProductsAPITester;