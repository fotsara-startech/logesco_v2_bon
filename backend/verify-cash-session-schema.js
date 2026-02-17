const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function verifySchema() {
  console.log('🔍 Vérification du schéma de la table cash_sessions\n');

  try {
    // Vérifier les colonnes de la table
    const columns = await prisma.$queryRaw`PRAGMA table_info(cash_sessions)`;
    
    console.log('📋 Colonnes de la table cash_sessions:');
    console.log('─'.repeat(80));
    
    const requiredColumns = ['solde_attendu', 'ecart'];
    const foundColumns = {};
    
    columns.forEach(col => {
      const marker = requiredColumns.includes(col.name) ? '✅' : '  ';
      console.log(`${marker} ${col.name.padEnd(20)} | Type: ${col.type.padEnd(10)} | Null: ${col.notnull === 0 ? 'YES' : 'NO'}`);
      
      if (requiredColumns.includes(col.name)) {
        foundColumns[col.name] = true;
      }
    });
    
    console.log('─'.repeat(80));
    console.log('\n📊 Vérification des colonnes requises:');
    
    requiredColumns.forEach(colName => {
      if (foundColumns[colName]) {
        console.log(`✅ ${colName} - Présente`);
      } else {
        console.log(`❌ ${colName} - MANQUANTE`);
      }
    });
    
    // Vérifier s'il y a des sessions actives
    console.log('\n🔍 Vérification des sessions actives:');
    const activeSessions = await prisma.cashSession.findMany({
      where: {
        isActive: true,
        dateFermeture: null
      },
      select: {
        id: true,
        soldeOuverture: true,
        soldeAttendu: true,
        dateOuverture: true
      }
    });
    
    if (activeSessions.length === 0) {
      console.log('ℹ️  Aucune session active');
    } else {
      console.log(`📌 ${activeSessions.length} session(s) active(s):`);
      activeSessions.forEach(session => {
        console.log(`   - ID: ${session.id}`);
        console.log(`     Solde ouverture: ${session.soldeOuverture} FCFA`);
        console.log(`     Solde attendu: ${session.soldeAttendu || 'NULL'} FCFA`);
        console.log(`     Date: ${session.dateOuverture}`);
      });
    }
    
    // Vérifier les dernières sessions fermées
    console.log('\n🔍 Dernières sessions fermées:');
    const closedSessions = await prisma.cashSession.findMany({
      where: {
        isActive: false,
        dateFermeture: { not: null }
      },
      orderBy: {
        dateFermeture: 'desc'
      },
      take: 3,
      select: {
        id: true,
        soldeOuverture: true,
        soldeAttendu: true,
        soldeFermeture: true,
        ecart: true,
        dateFermeture: true
      }
    });
    
    if (closedSessions.length === 0) {
      console.log('ℹ️  Aucune session fermée');
    } else {
      closedSessions.forEach(session => {
        console.log(`\n   Session ID: ${session.id}`);
        console.log(`   ├─ Solde ouverture: ${session.soldeOuverture} FCFA`);
        console.log(`   ├─ Solde attendu: ${session.soldeAttendu || 'NULL'} FCFA`);
        console.log(`   ├─ Solde fermeture: ${session.soldeFermeture || 'NULL'} FCFA`);
        console.log(`   ├─ Écart: ${session.ecart !== null ? session.ecart + ' FCFA' : 'NULL'}`);
        console.log(`   └─ Date fermeture: ${session.dateFermeture}`);
      });
    }
    
    console.log('\n✅ Vérification terminée');
    
  } catch (error) {
    console.error('❌ Erreur lors de la vérification:', error);
  } finally {
    await prisma.$disconnect();
  }
}

verifySchema();
