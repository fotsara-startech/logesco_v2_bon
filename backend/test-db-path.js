const { PrismaClient } = require('@prisma/client');
const p = new PrismaClient();

// Afficher le chemin de la base de données utilisée
console.log('DATABASE_URL:', process.env.DATABASE_URL);
console.log('__dirname:', __dirname);

p.$queryRawUnsafe('PRAGMA database_list').then(r => {
  console.log('Database files:', r.map(x => String(x.file || x.name)));
  return p.$disconnect();
});
