const fs = require('fs');

console.log('🔧 Test de l\'ordre des routes backend');
console.log('=' * 50);

// Lire le fichier des routes
const routesContent = fs.readFileSync('backend/src/routes/products.js', 'utf8');

// Trouver les positions des routes
const allRoutePos = routesContent.indexOf("router.get('/all'");
const idRoutePos = routesContent.indexOf("router.get('/:id'");
const importRoutePos = routesContent.indexOf("router.post('/import'");

console.log('\n📍 Positions des routes :');
console.log(`  /all : ${allRoutePos}`);
console.log(`  /:id : ${idRoutePos}`);
console.log(`  /import : ${importRoutePos}`);

// Vérifier l'ordre
if (allRoutePos < idRoutePos && allRoutePos !== -1) {
  console.log('\n✅ Route /all correctement placée AVANT /:id');
} else {
  console.log('\n❌ Problème d\'ordre : /all doit être AVANT /:id');
}

if (importRoutePos !== -1) {
  console.log('✅ Route /import trouvée');
} else {
  console.log('❌ Route /import manquante');
}

// Vérifier la syntaxe Prisma
if (routesContent.includes('models.produit.findMany') && routesContent.includes('models.produit.findFirst')) {
  console.log('✅ Syntaxe Prisma correcte');
} else {
  console.log('❌ Problème de syntaxe Prisma');
}

// Vérifier l'authentification
if (routesContent.includes('authenticateToken(models.authService)')) {
  console.log('✅ Authentification correcte');
} else {
  console.log('❌ Problème d\'authentification');
}

console.log('\n🎯 Routes prêtes pour les tests !');