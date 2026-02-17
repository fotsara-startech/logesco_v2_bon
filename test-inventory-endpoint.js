const fetch = require('node-fetch');

async function testInventory() {
  try {
    console.log('🧪 Test endpoint /api/v1/inventory...\n');
    
    // Test sans pagination pour voir le total
    const response = await fetch('http://localhost:8080/api/v1/inventory?page=1&limit=1', {
      headers: {
        'Authorization': 'Bearer test'
      }
    });
    
    const json = await response.json();
    
    console.log('✅ Réponse reçue:');
    console.log(`   - Status: ${response.status}`);
    console.log(`   - Success: ${json.success}`);
    console.log(`   - Total produits: ${json.pagination?.total}`);
    console.log(`   - Data reçue: ${json.data?.length} produits sur page 1`);
    
    if (json.data && json.data.length > 0) {
      console.log('\n📦 Premier produit:');
      const prod = json.data[0];
      console.log(`   - Nom: ${prod.nom}`);
      console.log(`   - Stock initié: ${prod.stock ? 'Oui' : 'Non'}`);
      if (prod.stock) {
        console.log(`   - Quantité: ${prod.stock.quantiteDisponible}`);
      }
    }
    
  } catch (error) {
    console.error('❌ Erreur:', error.message);
  }
}

testInventory();
