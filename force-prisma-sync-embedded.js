/**
 * Force Prisma DB push sur la base embarquée
 * Crée toutes les tables manquantes
 */

const { execSync } = require('child_process');
const path = require('path');
const fs = require('fs');

const embeddedDbPath = path.join(process.env.LOCALAPPDATA, 'LOGESCO', 'backend', 'database', 'logesco.db');
const databaseUrl = `file:${embeddedDbPath}`;

console.log('📂 Base de données:', embeddedDbPath);
console.log('🔗 DATABASE_URL:', databaseUrl);

const backendDir = path.join(__dirname);
const schemaPath = path.join(backendDir, 'prisma', 'schema.prisma');

if (!fs.existsSync(schemaPath)) {
  console.error('❌ schema.prisma introuvable');
  process.exit(1);
}

if (!fs.existsSync(embeddedDbPath)) {
  console.error('❌ Base de données embarquée introuvable');
  process.exit(1);
}

console.log('\n🔄 Application de prisma db push...\n');

try {
  const cmd = `npx prisma db push --accept-data-loss --schema="${schemaPath}"`;
  
  execSync(cmd, {
    stdio: 'inherit',
    cwd: backendDir,
    env: { ...process.env, DATABASE_URL: databaseUrl }
  });
  
  console.log('\n✅ Prisma db push terminé avec succès !');
  console.log('📋 Toutes les tables sont maintenant synchronisées avec le schéma');
  
} catch (error) {
  console.error('\n❌ Erreur lors du push:', error.message);
  process.exit(1);
}
