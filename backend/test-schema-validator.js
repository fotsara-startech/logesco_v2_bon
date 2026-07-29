/**
 * Test du validateur de schéma
 */

const { PrismaClient } = require('@prisma/client');
const SchemaValidator = require('./src/utils/schema-validator');

const prisma = new PrismaClient();
const validator = new SchemaValidator(prisma);

async function test() {
  try {
    console.log('=== Test du validateur de schéma ===\n');
    
    const result = await validator.validateAndFix();
    
    console.log('\n=== Résultat ===');
    console.log(`Problèmes trouvés: ${result.issuesFound}`);
    console.log(`Problèmes corrigés: ${result.issuesFixed}`);
    console.log(`Succès: ${result.success ? 'Oui' : 'Non'}`);
    
  } catch (error) {
    console.error('Erreur:', error);
  } finally {
    await prisma.$disconnect();
  }
}

test();
