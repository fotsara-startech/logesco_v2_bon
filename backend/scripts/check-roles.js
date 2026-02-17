const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function checkRoles() {
  try {
    console.log('🔍 Vérification des rôles en base de données...');
    
    const roles = await prisma.userRole.findMany();
    
    console.log(`📊 Nombre de rôles trouvés: ${roles.length}`);
    
    if (roles.length > 0) {
      console.log('\n📋 Rôles en base:');
      roles.forEach((role, index) => {
        console.log(`${index + 1}. ${role.displayName} (${role.nom})`);
        console.log(`   - ID: ${role.id}`);
        console.log(`   - Admin: ${role.isAdmin}`);
        console.log(`   - Privilèges: ${role.privileges}`);
        console.log('');
      });
    } else {
      console.log('✅ Aucun rôle en base de données');
    }
    
  } catch (error) {
    console.error('❌ Erreur:', error);
  } finally {
    await prisma.$disconnect();
  }
}

checkRoles();