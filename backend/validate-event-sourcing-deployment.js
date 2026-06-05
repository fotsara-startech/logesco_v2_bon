/**
 * Validation Script — Event Sourcing V2 Pre-Deployment Checks
 * Run this before deploying to production
 */

const fs = require('fs');
const path = require('path');
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

const checks = [];

async function runChecks() {
  console.log('\n' + '═'.repeat(70));
  console.log('🔍 EVENT SOURCING V2 — PRE-DEPLOYMENT VALIDATION');
  console.log('═'.repeat(70) + '\n');

  try {
    // 1. Check Prisma schema
    await checkPrismaSchema();

    // 2. Check sync-service.js exists
    await checkSyncServiceFile();

    // 3. Check database connection
    await checkDatabaseConnection();

    // 4. Check operation_log table exists
    await checkOperationLogTable();

    // 5. Check required columns
    await checkOperationLogColumns();

    // 6. Check indexes
    await checkIndexes();

    // 7. Check env variables
    await checkEnvironment();

    // 8. Check no enqueue() calls remain (except in V1 backup)
    await checkNoOldEnqueue();

    // Print summary
    printSummary();

  } catch (error) {
    console.error('\n❌ VALIDATION FAILED:', error.message);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

async function checkPrismaSchema() {
  console.log('📋 Check 1: Prisma schema...');
  const schemaPath = path.join(__dirname, 'prisma/schema.prisma');
  
  if (!fs.existsSync(schemaPath)) {
    throw new Error('schema.prisma not found');
  }
  
  const schema = fs.readFileSync(schemaPath, 'utf-8');
  if (!schema.includes('model OperationLog')) {
    throw new Error('OperationLog model not found in schema');
  }
  
  if (!schema.includes('operationId')) {
    throw new Error('operationId field not found in OperationLog');
  }
  
  console.log('  ✅ Prisma schema valid\n');
  checks.push({ name: 'Prisma Schema', status: '✅' });
}

async function checkSyncServiceFile() {
  console.log('📋 Check 2: SyncService V2 file...');
  const servicePath = path.join(__dirname, 'src/services/sync-service.js');
  
  if (!fs.existsSync(servicePath)) {
    throw new Error('sync-service.js not found');
  }
  
  const service = fs.readFileSync(servicePath, 'utf-8');
  if (!service.includes('logOperation')) {
    throw new Error('logOperation method not found in sync-service.js');
  }
  
  if (!service.includes('_replayPendingOperations')) {
    throw new Error('_replayPendingOperations method not found');
  }
  
  if (!service.includes('_pullDeltaFromNeon')) {
    throw new Error('_pullDeltaFromNeon method not found');
  }
  
  console.log('  ✅ SyncService V2 valid\n');
  checks.push({ name: 'SyncService V2', status: '✅' });
}

async function checkDatabaseConnection() {
  console.log('📋 Check 3: Database connection...');
  
  try {
    await prisma.$queryRawUnsafe('SELECT 1');
    console.log('  ✅ Database connected\n');
    checks.push({ name: 'Database Connection', status: '✅' });
  } catch (e) {
    throw new Error(`Database connection failed: ${e.message}`);
  }
}

async function checkOperationLogTable() {
  console.log('📋 Check 4: operation_log table...');
  
  try {
    const result = await prisma.$queryRawUnsafe(
      `SELECT COUNT(*) as count FROM sqlite_master WHERE type='table' AND name='operation_log'`
    );
    
    if (result[0].count === 0) {
      throw new Error('operation_log table does not exist');
    }
    
    console.log('  ✅ operation_log table exists\n');
    checks.push({ name: 'operation_log Table', status: '✅' });
  } catch (e) {
    if (e.message.includes('no such table')) {
      console.log('  ⚠️  operation_log table not yet created (will be created on first migrate)\n');
      checks.push({ name: 'operation_log Table', status: '⚠️ PENDING MIGRATION' });
    } else {
      throw e;
    }
  }
}

async function checkOperationLogColumns() {
  console.log('📋 Check 5: operation_log columns...');
  
  const requiredColumns = [
    'id', 'operation_id', 'operation_type', 'table_name', 
    'record_id', 'data', 'timestamp', 'synced_at', 'status'
  ];
  
  try {
    const result = await prisma.$queryRawUnsafe(
      `PRAGMA table_info(operation_log)`
    );
    
    const existingColumns = result.map(r => r.name);
    const missing = requiredColumns.filter(col => !existingColumns.includes(col));
    
    if (missing.length > 0) {
      throw new Error(`Missing columns: ${missing.join(', ')}`);
    }
    
    console.log('  ✅ All required columns present\n');
    checks.push({ name: 'operation_log Columns', status: '✅' });
  } catch (e) {
    if (e.message.includes('no such table')) {
      console.log('  ⚠️  Table not yet created (OK - will be created on migrate)\n');
      checks.push({ name: 'operation_log Columns', status: '⚠️ PENDING' });
    } else {
      throw e;
    }
  }
}

async function checkIndexes() {
  console.log('📋 Check 6: Indexes...');
  
  try {
    const result = await prisma.$queryRawUnsafe(
      `SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='operation_log'`
    );
    
    const indexNames = result.map(r => r.name);
    const hasStatusIndex = indexNames.some(i => i.includes('status'));
    const hasTableIndex = indexNames.some(i => i.includes('table'));
    
    if (!hasStatusIndex && !hasTableIndex) {
      console.log('  ⚠️  Indexes not yet created (OK - will be on migrate)\n');
      checks.push({ name: 'Indexes', status: '⚠️ PENDING' });
    } else {
      console.log('  ✅ Indexes present\n');
      checks.push({ name: 'Indexes', status: '✅' });
    }
  } catch (e) {
    if (e.message.includes('no such table')) {
      console.log('  ⚠️  Table not yet created (OK)\n');
      checks.push({ name: 'Indexes', status: '⚠️ PENDING' });
    } else {
      throw e;
    }
  }
}

async function checkEnvironment() {
  console.log('📋 Check 7: Environment variables...');
  
  const requiredEnvs = ['DATABASE_URL'];
  const missing = requiredEnvs.filter(env => !process.env[env]);
  
  if (missing.length > 0) {
    throw new Error(`Missing env vars: ${missing.join(', ')}`);
  }
  
  console.log('  ✅ DATABASE_URL defined');
  
  if (process.env.CLOUD_DB_URL) {
    console.log('  ✅ CLOUD_DB_URL defined (hybrid mode)\n');
    checks.push({ name: 'Environment', status: '✅' });
  } else {
    console.log('  ⚠️  CLOUD_DB_URL not defined (local-only mode)\n');
    checks.push({ name: 'Environment', status: '⚠️ LOCAL-ONLY' });
  }
}

async function checkNoOldEnqueue() {
  console.log('📋 Check 8: No old enqueue() calls...');
  
  const routesDir = path.join(__dirname, 'src/routes');
  const files = fs.readdirSync(routesDir).filter(f => f.endsWith('.js'));
  
  let enqueueCalls = 0;
  for (const file of files) {
    const content = fs.readFileSync(path.join(routesDir, file), 'utf-8');
    const matches = content.match(/syncService\.enqueue\(/g);
    if (matches) {
      enqueueCalls += matches.length;
      console.log(`  ⚠️  Found ${matches.length} enqueue() calls in ${file}`);
    }
  }
  
  if (enqueueCalls > 0) {
    console.log(`\n  ⚠️  Total: ${enqueueCalls} enqueue() calls to migrate\n`);
    checks.push({ name: 'Route Migration', status: `⚠️ ${enqueueCalls} calls` });
  } else {
    console.log('  ✅ No old enqueue() calls found\n');
    checks.push({ name: 'Route Migration', status: '✅' });
  }
}

function printSummary() {
  console.log('═'.repeat(70));
  console.log('\n📊 VALIDATION SUMMARY\n');
  
  const allPass = checks.every(c => c.status === '✅');
  
  checks.forEach(check => {
    const icon = check.status.includes('✅') ? '✅' : '⚠️ ';
    console.log(`${icon} ${check.name.padEnd(30)} ${check.status}`);
  });
  
  console.log('\n' + '═'.repeat(70) + '\n');
  
  if (allPass) {
    console.log('🎉 ALL CHECKS PASSED — Ready for deployment\n');
    process.exit(0);
  } else {
    const pending = checks.filter(c => c.status.includes('PENDING')).length;
    const warnings = checks.filter(c => c.status.includes('⚠️')).length;
    
    console.log(`⚠️  ${warnings} warning(s), ${pending} pending action(s)`);
    console.log('\nNext steps:');
    console.log('1. Run: npx prisma migrate deploy');
    console.log('2. Migrate remaining routes from enqueue() to logOperation()');
    console.log('3. Run this script again\n');
    process.exit(0);
  }
}

// Run all checks
runChecks().catch(error => {
  console.error('\n❌ VALIDATION ERROR:', error.message);
  process.exit(1);
});
