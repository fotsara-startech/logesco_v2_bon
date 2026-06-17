const { PrismaClient } = require('@prisma/client');

async function checkTableStructure() {
  const prisma = new PrismaClient();
  try {
    // Check if table exists
    const tables = await prisma.$queryRaw`
      SELECT name FROM sqlite_master WHERE type='table' AND name='deleted_records'
    `;
    console.log('Tables matching deleted_records:', tables);

    if (tables.length > 0) {
      // Get table structure
      const structure = await prisma.$queryRaw`
        SELECT sql FROM sqlite_master WHERE type='table' AND name='deleted_records'
      `;
      console.log('Table structure:');
      console.log(structure[0]?.sql);
    }
  } catch (e) {
    console.error('Error:', e.message);
  } finally {
    await prisma.$disconnect();
  }
}

checkTableStructure();