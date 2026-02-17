const bcrypt = require('bcryptjs');
const { PrismaClient } = require('@prisma/client');

async function resetAdminPassword() {
  const prisma = new PrismaClient();
  
  try {
    console.log('🔍 Recherche de l\'utilisateur admin...');
    
    const user = await prisma.utilisateur.findFirst({
      where: { nomUtilisateur: 'admin' }
    });
    
    if (!user) {
      console.log('❌ Utilisateur admin non trouvé');
      return;
    }
    
    console.log('✅ Utilisateur trouvé:', user.nomUtilisateur);
    
    console.log('\n🔐 Réinitialisation du mot de passe...');
    const newPassword = 'admin123';
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    
    await prisma.utilisateur.update({
      where: { id: user.id },
      data: { motDePasseHash: hashedPassword }
    });
    
    console.log('✅ Mot de passe réinitialisé avec succès !');
    console.log('\n📋 Identifiants de connexion:');
    console.log('   - Nom d\'utilisateur: admin');
    console.log('   - Mot de passe: admin123');
    console.log('   - Email: admin@logesco.com');
    
    // Vérifier que ça fonctionne
    console.log('\n🧪 Vérification...');
    const updatedUser = await prisma.utilisateur.findUnique({
      where: { id: user.id }
    });
    
    const match = await bcrypt.compare(newPassword, updatedUser.motDePasseHash);
    if (match) {
      console.log('✅ Vérification réussie - le mot de passe fonctionne !');
    } else {
      console.log('❌ Erreur - le mot de passe ne fonctionne pas');
    }
    
  } catch (error) {
    console.error('❌ Erreur:', error);
  } finally {
    await prisma.$disconnect();
  }
}

resetAdminPassword();
