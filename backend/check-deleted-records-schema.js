const { PrismaClient } = require('@prisma/client');

async function checkSchema() {
  const prisma = new PrismaClient();
  try {
    const info = await prisma.$queryRaw`PRAGMA table_info(deleted_records)`;
    console.log('deleted_records table schema:');
    console.log(JSON.stringify(info, null, 2));
  } catch (e) {
    console.error('Error:', e.message);
  } finally {
    await prisma.$disconnect();
  }
}

checkSchema();