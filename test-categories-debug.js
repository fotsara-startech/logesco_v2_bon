/**
 * Script de debug pour analyser le problème des catégories de produits
 */

const axios = require('axios');

const BASE_URL = 'http://localhost:3002/api/v1';

async function testCategoriesAPI() {
  console.log('🔍 === TEST API CATÉGORIES ===');
  
  try {
    // Test 1: Récupérer les catégories
    console.log('\n1. Test récupération des catégories...');
    const categoriesResponse = await axios.get(`${BASE_URL}/categories`);
    console.log('✅ Statut:', categoriesResponse.status);
    console.log('📋 Catégories trouvées:', categoriesResponse.data.data.length);
    
    categoriesResponse.data.data.forEach((cat, index) => {
      console.log(`   ${index + 1}. ID: ${cat.id}, Nom: "${cat.nom}", Produits: ${cat._count?.produits || 0}`);
    });

    // Test 2: Récupérer les produits
    console.log('\n2. Test récupération des produits...');
    const productsResponse = await axios.get(`${BASE_URL}/products`);
    console.log('✅ Statut:', productsResponse.status);
    console.log('📦 Produits trouvés:', productsResponse.data.data.length);
    
    // Analyser les catégories des produits
    const products = productsResponse.data.data;
    const categoryAnalysis = {};
    
    products.forEach((product, index) => {
      const categoryInfo = {
        categorieId: product.categorieId,
        categorie: product.categorie
      };
      
      if (index < 5) { // Afficher les 5 premiers pour debug
        console.log(`   Produit ${index + 1}: "${product.nom}"`);
        console.log(`     - categorieId: ${categoryInfo.categorieId}`);
        console.log(`     - categorie: "${categoryInfo.categorie}"`);
      }
      
      // Compter les catégories
      const key = `ID:${categoryInfo.categorieId}|Nom:${categoryInfo.categorie}`;
      categoryAnalysis[key] = (categoryAnalysis[key] || 0) + 1;
    });
    
    console.log('\n📊 Analyse des catégories dans les produits:');
    Object.entries(categoryAnalysis).forEach(([key, count]) => {
      console.log(`   ${key} → ${count} produit(s)`);
    });

    // Test 3: Vérifier la cohérence
    console.log('\n3. Vérification de la cohérence...');
    const categoriesMap = {};
    categoriesResponse.data.data.forEach(cat => {
      categoriesMap[cat.id] = cat.nom;
    });
    
    let inconsistencies = 0;
    products.forEach(product => {
      if (product.categorieId && !product.categorie) {
        console.log(`⚠️  Produit "${product.nom}" a categorieId=${product.categorieId} mais categorie=null`);
        const expectedName = categoriesMap[product.categorieId];
        if (expectedName) {
          console.log(`   → Devrait avoir categorie="${expectedName}"`);
        }
        inconsistencies++;
      }
    });
    
    if (inconsistencies === 0) {
      console.log('✅ Aucune incohérence détectée');
    } else {
      console.log(`❌ ${inconsistencies} incohérence(s) détectée(s)`);
    }

  } catch (error) {
    console.error('❌ Erreur lors du test:', error.message);
    if (error.response) {
      console.error('   Statut:', error.response.status);
      console.error('   Données:', error.response.data);
    }
  }
}

async function testProductsWithCategories() {
  console.log('\n🔍 === TEST PRODUITS AVEC CATÉGORIES ===');
  
  try {
    // Test avec filtre par catégorie
    const categoriesResponse = await axios.get(`${BASE_URL}/categories`);
    const categories = categoriesResponse.data.data;
    
    if (categories.length > 0) {
      const firstCategory = categories[0];
      console.log(`\nTest avec catégorie: "${firstCategory.nom}"`);
      
      const filteredResponse = await axios.get(`${BASE_URL}/products?categorie=${encodeURIComponent(firstCategory.nom)}`);
      console.log('✅ Produits filtrés:', filteredResponse.data.data.length);
      
      filteredResponse.data.data.slice(0, 3).forEach((product, index) => {
        console.log(`   ${index + 1}. "${product.nom}" - categorie: "${product.categorie}"`);
      });
    }
    
  } catch (error) {
    console.error('❌ Erreur test filtrage:', error.message);
  }
}

// Exécuter les tests
async function runAllTests() {
  await testCategoriesAPI();
  await testProductsWithCategories();
  console.log('\n🏁 Tests terminés');
}

runAllTests().catch(console.error);