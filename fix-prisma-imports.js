/**
 * Script pour remplacer les imports de @prisma/client par notre wrapper compatible pkg
 */

const fs = require('fs');
const path = require('path');

const srcDir = path.join(__dirname, 'backend', 'src');

// Pattern à rechercher et remplacer
const oldPattern = /const\s+{\s*PrismaClient\s*}\s*=\s*require\(['"]@prisma\/client['"]\);?/g;
const newImport = "const { PrismaClient } = require('./config/prisma-client');";

// Fonction pour traiter un fichier
function processFile(filePath) {
  const content = fs.readFileSync(filePath, 'utf8');
  
  // Vérifier si le fichier contient l'ancien pattern
  if (oldPattern.test(content)) {
    // Calculer le chemin relatif vers config/prisma-client.js
    const fileDir = path.dirname(filePath);
    const relativePath = path.relative(fileDir, path.join(srcDir, 'config', 'prisma-client.js'));
    const normalizedPath = relativePath.replace(/\\/g, '/');
    
    // Remplacer l'import
    const newContent = content.replace(
      oldPattern,
      `const { PrismaClient } = require('${normalizedPath}');`
    );
    
    fs.writeFileSync(filePath, newContent, 'utf8');
    console.log(`✓ Mis à jour: ${path.relative(__dirname, filePath)}`);
    return true;
  }
  
  return false;
}

// Fonction pour parcourir récursivement les fichiers
function processDirectory(dir) {
  let count = 0;
  
  const files = fs.readdirSync(dir);
  
  for (const file of files) {
    const filePath = path.join(dir, file);
    const stat = fs.statSync(filePath);
    
    if (stat.isDirectory()) {
      // Ignorer node_modules
      if (file !== 'node_modules') {
        count += processDirectory(filePath);
      }
    } else if (file.endsWith('.js')) {
      if (processFile(filePath)) {
        count++;
      }
    }
  }
  
  return count;
}

console.log('🔧 Remplacement des imports @prisma/client...\n');

const count = processDirectory(srcDir);

console.log(`\n✅ ${count} fichier(s) mis à jour`);

if (count > 0) {
  console.log('\nProchaine étape: Reconstruire le backend');
  console.log('  Exécutez: rebuild-backend-production.bat');
}
