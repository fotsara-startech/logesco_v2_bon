process.env.DATABASE_URL = 'file:./database/logesco.db';
const { getPrismaClient } = require('./src/config/prisma-client');
const p = getPrismaClient();

async function main() {
  try {
    const tables = await p.$queryRawUnsafe("SELECT name FROM sqlite_master WHERE type='table'");
    console.log('Tables existantes:', tables.map(t => t.name).join(', '));
    
    const hasBoutiques = tables.some(t => t.name === 'boutiques');
    const hasStockBoutique = tables.some(t => t.name === 'stock_boutiques');
    const hasTransfert = tables.some(t => t.name === 'transferts_stock');
    const hasAssignment = tables.some(t => t.name === 'user_boutique_assignments');
    
    console.log('\nTables multi-boutique:');
    console.log('  boutiques:', hasBoutiques ? '✅' : '❌ MANQUANTE');
    console.log('  stock_boutiques:', hasStockBoutique ? '✅' : '❌ MANQUANTE');
    console.log('  transferts_stock:', hasTransfert ? '✅' : '❌ MANQUANTE');
    console.log('  user_boutique_assignments:', hasAssignment ? '✅' : '❌ MANQUANTE');
    
    // Vérifier aussi les colonnes boutique_id sur les tables existantes
    const ventesCols = await p.$queryRawUnsafe("PRAGMA table_info(ventes)");
    const hasBoutiqueIdVentes = ventesCols.some(c => c.name === 'boutique_id');
    console.log('\n  ventes.boutique_id:', hasBoutiqueIdVentes ? '✅' : '❌ MANQUANTE');
    
    const cashCols = await p.$queryRawUnsafe("PRAGMA table_info(cash_registers)");
    const hasBoutiqueIdCash = cashCols.some(c => c.name === 'boutique_id');
    console.log('  cash_registers.boutique_id:', hasBoutiqueIdCash ? '✅' : '❌ MANQUANTE');
    
  } catch(e) {
    console.error('Erreur:', e.message);
  } finally {
    await p.$disconnect();
    process.exit(0);
  }
}

main();
