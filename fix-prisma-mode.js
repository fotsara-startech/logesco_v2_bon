// Script pour corriger les occurrences de mode: 'insensitive' dans inventory.js

const fs = require('fs');
const path = require('path');

const filePath = path.join(__dirname, 'backend/src/routes/inventory.js');

try {
  let content = fs.readFileSync(filePath, 'utf8');
  
  // Remplacer toutes les occurrences de mode: 'insensitive'
  content = content.replace(/mode: 'insensitive'/g, '');
  
  // Nettoyer les virgules en trop
  content = content.replace(/,\s*}/g, ' }');
  
  fs.writeFileSync(filePath, content);
  
  console.log('✅ Fichier inventory.js corrigé avec succès');
  console.log('🔧 Toutes les occurrences de mode: \'insensitive\' ont été supprimées');
  
} catch (error) {
  console.error('❌ Erreur:', error.message);
}