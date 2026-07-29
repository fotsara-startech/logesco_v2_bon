const { PrismaClient } = require('@prisma/client');

async function verify() {
  const prisma = new PrismaClient();
  try {
    const cols = await prisma.$queryRaw`PRAGMA table_info(stock_boutiques)`;
    console.log('Colonnes de stock_boutiques:');
    cols.forEach(col => console.log(`  - ${col.name} (${col.type})`));
  } finally {
    await prisma.$disconnect();
  }
}

verify();
