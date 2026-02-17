const bcrypt = require('bcryptjs');
const { PrismaClient } = require('@prisma/client');

async function testAdminLogin() {
  const prisma = new PrismaClient();
  
  try {
    console.log('🔍 Recherche de l\'utilisateur admin...');
    
    const user = await prisma.utilisateur.findFirst({
      where: { nomUtilisateur: 'admin' },
      include: { role: true }
    });
    
    if (!user) {
      console.log('❌ Utilisateur admin non trouvé');
      return;
    }
    
    console.log('✅ Utilisateur trouvé:');
    console.log('   - ID:', user.id);
    console.log('   - Nom d\'utilisateur:', user.nomUtilisateur);
    console.log('   - Email:', user.email);
    console.log('   - Rôle:', user.role?.displayName);
    console.log('   - Hash du mot de passe:', user.motDePasseHash.substring(0, 20) + '...');
    
    console.log('\n🔐 Test du mot de passe "admin123"...');
    const match = await bcrypt.compare('admin123', user.motDePasseHash);
    
    if (match) {
      console.log('✅ Mot de passe correct !');
    } else {
      console.log('❌ Mot de passe incorrect');
      
      // Tester d'autres mots de passe possibles
      console.log('\n🔍 Test d\'autres mots de passe...');
      const testPasswords = ['Admin123', 'ADMIN123', 'admin', 'password'];
      
      for (const pwd of testPasswords) {
        const testMatch = await bcrypt.compare(pwd, user.motDePasseHash);
        if (testMatch) {
          console.log(`✅ Le mot de passe correct est: "${pwd}"`);
          break;
        }
      }
    }
    
  } catch (error) {
    console.error('❌ Erreur:', error);
  } finally {
    await prisma.$disconnect();
  }
}

testAdminLogin();
