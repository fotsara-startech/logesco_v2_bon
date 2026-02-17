/**
 * Affiche l'aide rapide pour les scripts de seed
 */

const fs = require('fs');
const path = require('path');

const helpFile = path.join(__dirname, 'QUICK_START_SEED.txt');

try {
  const content = fs.readFileSync(helpFile, 'utf8');
  console.log(content);
} catch (error) {
  console.error('Erreur lors de la lecture du fichier d\'aide:', error.message);
}
