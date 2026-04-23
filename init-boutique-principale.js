/**
 * Script pour créer la boutique principale et assigner tous les utilisateurs existants
 * À exécuter une seule fois sur les bases existantes
 */
process.env.DATABASE_URL = process.env.DATABASE_URL || 'file:./database/logesco.db';
const { getPrismaClient } = require('./src/config/prisma-client');
const prisma = getPrismaClient();

async function main() {
  console.log('🏪 Initialisation de la boutique principale...');

  // Vérifier si une boutique principale existe déjà
  const existing = await prisma.boutique.findFirst({ where: { estPrincipale: true } });
  if (existing) {
    console.log('✅ Boutique principale déjà existante:', existing.nom);
  } else {
    // Créer la boutique principale
    const boutique = await prisma.boutique.create({
      data: {
        nom: 'Boutique Principale',
        description: 'Boutique principale du système',
        estPrincipale: true,
        isActive: true
      }
    });
    console.log('✅ Boutique principale créée:', boutique.nom, '(id:', boutique.id, ')');

    // Assigner tous les utilisateurs existants à la boutique principale avec leur rôle actuel
    const utilisateurs = await prisma.utilisateur.findMany({
      where: { isActive: true },
      include: { role: true }
    });

    for (const user of utilisateurs) {
      try {
        await prisma.userBoutiqueAssignment.upsert({
          where: { utilisateurId_boutiqueId: { utilisateurId: user.id, boutiqueId: boutique.id } },
          update: { isActive: true },
          create: {
            utilisateurId: user.id,
            boutiqueId: boutique.id,
            roleId: user.roleId,
            isActive: true
          }
        });
        console.log(`  ✅ ${user.nomUtilisateur} assigné à la boutique principale`);
      } catch (e) {
        console.warn(`  ⚠️ Erreur pour ${user.nomUtilisateur}:`, e.message);
      }
    }
  }

  // Afficher l'état final
  const boutiques = await prisma.boutique.findMany({
    include: { _count: { select: { utilisateurs: true } } }
  });
  console.log('\n📊 État des boutiques:');
  boutiques.forEach(b => {
    console.log(`  - ${b.nom} (id:${b.id}) | principale:${b.estPrincipale} | users:${b._count.utilisateurs}`);
  });

  await prisma.$disconnect();
}

main().catch(e => {
  console.error('❌ Erreur:', e.message);
  process.exit(1);
});
