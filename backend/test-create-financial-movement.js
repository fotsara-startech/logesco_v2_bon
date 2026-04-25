/**
 * Test creating a financial movement with sessionId
 * Run: node test-create-financial-movement.js
 */

require('dotenv').config();
const { PrismaClient } = require('@prisma/client');
const FinancialMovementService = require('./src/services/financial-movement');

const prisma = new PrismaClient();

async function test() {
  try {
    console.log('🧪 Testing Financial Movement Creation...\n');

    // Initialize the service (without syncService for now)
    const service = new FinancialMovementService(prisma, null);

    // Find an active session
    console.log('Step 1: Finding active session...');
    const activeSession = await prisma.cashSession.findFirst({
      where: {
        isActive: true,
        dateFermeture: null,
        boutiqueId: 7
      }
    });

    if (!activeSession) {
      console.log('❌ No active session found. Creating one...');
      
      // Find a cash register
      const cashRegister = await prisma.cashRegister.findFirst({
        where: { boutiqueId: 7, isActive: true }
      });

      if (!cashRegister) {
        console.log('❌ No cash register found for boutique 7');
        return;
      }

      // Create a session
      const newSession = await prisma.cashSession.create({
        data: {
          caisseId: cashRegister.id,
          utilisateurId: 1,
          boutiqueId: 7,
          soldeOuverture: 50000,
          soldeAttendu: 50000,
          isActive: true
        }
      });
      console.log(`✅ Created session: ID ${newSession.id}`);
    } else {
      console.log(`✅ Found active session: ID ${activeSession.id}`);
    }

    // Find a category
    console.log('\nStep 2: Finding movement category...');
    const category = await prisma.movementCategory.findFirst({
      where: { isActive: true }
    });

    if (!category) {
      console.log('❌ No active category found');
      return;
    }
    console.log(`✅ Found category: ${category.nom} (ID ${category.id})`);

    // Create the movement
    console.log('\nStep 3: Creating financial movement...');
    const movementData = {
      montant: 500,
      categorieId: category.id,
      description: 'TEST - Script de vérification sessionId',
      date: new Date(),
      utilisateurId: 1,
      boutiqueId: 7,
      notes: 'Test automatique'
    };

    console.log('Data:', JSON.stringify(movementData, null, 2));

    const movement = await service.createMovement(movementData);

    console.log('\n✅ Movement created successfully!');
    console.log(`   ID: ${movement.id}`);
    console.log(`   Reference: ${movement.reference}`);
    console.log(`   Session ID: ${movement.sessionId || 'NULL ❌'}`);
    console.log(`   Boutique ID: ${movement.boutiqueId}`);
    console.log(`   Montant: ${movement.montant} FCFA`);

    // Verify in database
    console.log('\nStep 4: Verifying in database...');
    const verif = await prisma.$queryRawUnsafe(`
      SELECT id, reference, session_id, boutique_id, montant
      FROM financial_movements
      WHERE id = ?
    `, movement.id);

    if (verif.length > 0) {
      const dbRecord = verif[0];
      console.log('Database record:');
      console.log(`   ID: ${dbRecord.id}`);
      console.log(`   Reference: ${dbRecord.reference}`);
      console.log(`   Session ID: ${dbRecord.session_id || 'NULL ❌'}`);
      console.log(`   Boutique ID: ${dbRecord.boutique_id}`);
      console.log(`   Montant: ${dbRecord.montant} FCFA`);

      if (dbRecord.session_id) {
        console.log('\n🎉 SUCCESS! sessionId is correctly saved in the database!');
      } else {
        console.log('\n❌ PROBLEM: sessionId is NULL in the database');
        console.log('   The service returned sessionId but it was not saved.');
      }
    }

  } catch (error) {
    console.error('❌ Error:', error.message);
    console.error(error.stack);
  } finally {
    await prisma.$disconnect();
  }
}

test();
