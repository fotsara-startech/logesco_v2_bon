/**
 * Script pour vérifier que les modifications backend sont actives
 */

const fs = require('fs');
const path = require('path');

console.log('═══════════════════════════════════════════════════════');
console.log('   VÉRIFICATION DES MODIFICATIONS BACKEND');
console.log('═══════════════════════════════════════════════════════\n');

// 1. Vérifier le schéma de validation
console.log('1️⃣  Vérification du schéma de validation...');
const schemaPath = path.join(__dirname, 'backend', 'src', 'validation', 'schemas.js');
const schemaContent = fs.readFileSync(schemaPath, 'utf8');

if (schemaContent.includes('modePaiement: baseSchemas.modePaiement.optional()')) {
  console.log('   ✅ Schéma de validation OK - modePaiement accepté\n');
} else {
  console.log('   ❌ ERREUR: modePaiement manquant dans le schéma de réception\n');
  console.log('   Action requise: Ajouter dans schemas.js:');
  console.log('   reception: Joi.object({');
  console.log('     details: [...],');
  console.log('     modePaiement: baseSchemas.modePaiement.optional()');
  console.log('   }),\n');
}

// 2. Vérifier la route de réception
console.log('2️⃣  Vérification de la route de réception...');
const routePath = path.join