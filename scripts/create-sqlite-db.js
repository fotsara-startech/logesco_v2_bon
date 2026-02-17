const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

console.log('========================================');
console.log('LOGESCO v2 - Create SQLite Database');
console.log('========================================');

const dbDir = path.join(__dirname, '..', 'dist', 'database');
const dbPath = path.join(dbDir, 'logesco.db');
const backendDir = path.join(__dirname, '..', 'backend');

// Create database directory
if (!fs.existsSync(dbDir)) {
    fs.mkdirSync(dbDir, { recursive: true });
    console.log('Created database directory');
}

// Change to backend directory
process.chdir(backendDir);

// Set environment for SQLite
process.env.DATABASE_URL = `file:${dbPath}`;
process.env.NODE_ENV = 'local';

try {
    console.log('Generating Prisma client...');
    execSync('npx prisma generate', { stdio: 'inherit' });
    
    console.log('Running database migrations...');
    execSync('npx prisma migrate deploy', { stdio: 'inherit' });
    
    console.log('Applying database indexes...');
    if (fs.existsSync('scripts/apply-indexes.js')) {
        execSync('node scripts/apply-indexes.js', { stdio: 'inherit' });
    }
    
    console.log('SQLite database created successfully!');
    console.log(`Database location: ${dbPath}`);
    
} catch (error) {
    console.error('Error creating SQLite database:', error.message);
    process.exit(1);
}