/**
 * Script de réparation : s'assure qu'une boutique principale existe
 * et que tous les utilisateurs y sont assignés.
 *
 * Usage : node scripts/fix-boutique-principale.js
 */

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log('🔍 Diagnostic de la boutique principale...\n');

  // ── 1. État actuel ────────────────────────────────────────────────────────
  const [toutesLesBoutiques, boutiquePrincipale, tousLesUsers] = await Promise.all([
    prisma.boutique.findMany({ orderBy: { id: 'asc' } }),
    prisma.boutique.findFirst({ where: { estPrincipale: true } }),
    prisma.utilisateur.findMany({ select: { id: true, nomUtilisateur: true } })
  ]);

  console.log(`   Boutiques trouvées : ${toutesLesBoutiques.length}`);
  toutesLesBoutiques.forEach(b =>
    console.log(`     - [${b.id}] ${b.nom} | principale=${b.estPrincipale} | active=${b.isActive}`)
  );
  console.log(`   Utilisateurs trouvés : ${tousLesUsers.length}`);
  console.log(`   Boutique principale : ${boutiquePrincipale ? `[${boutiquePrincipale.id}] ${boutiquePrincipale.nom}` : 'AUCUNE'}\n`);

  // ── 2. Résolution de la boutique principale ───────────────────────────────
  let boutique = boutiquePrincipale;

  if (!boutique) {
    if (toutesLesBoutiques.length > 0) {
      // Prendre la première boutique existante et la marquer principale
      boutique = toutesLesBoutiques[0];
      await prisma.boutique.update({
        where: { id: boutique.id },
        data: { estPrincipale: true, isActive: true }
      });
      console.log(`✅ Boutique [${boutique.id}] "${boutique.nom}" marquée comme principale`);
    } else {
      // Aucune boutique → en créer une
      boutique = await prisma.boutique.create({
        data: {
          nom: 'Boutique Principale',
          description: 'Boutique principale du système',
          estPrincipale: true,
          isActive: true
        }
      });
      console.log(`✅ Boutique principale créée (ID: ${boutique.id})`);
    }
  } else {
    console.log(`✅ Boutique principale déjà présente : [${boutique.id}] ${boutique.nom}`);
  }

  // ── 3. Vérifier/créer la caisse principale ────────────────────────────────
  let caisse = await prisma.cashRegister.findFirst({ where: { nom: 'Caisse Principale' } });
  if (!caisse) {
    caisse = await prisma.cashRegister.create({
      data: {
        nom: 'Caisse Principale',
        description: 'Caisse principale du système',
        isActive: true,
        soldeActuel: 0,
        soldeInitial: 0,
        boutiqueId: boutique.id
      }
    });
    console.log(`✅ Caisse principale créée (ID: ${caisse.id})`);
  } else if (!caisse.boutiqueId) {
    await prisma.cashRegister.update({
      where: { id: caisse.id },
      data: { boutiqueId: boutique.id }
    });
    console.log(`✅ Caisse principale liée à la boutique`);
  } else {
    console.log(`✅ Caisse principale OK (ID: ${caisse.id})`);
  }

  // ── 4. Assigner tous les utilisateurs à la boutique principale ────────────
  const adminRole = await prisma.userRole.findFirst({ where: { isAdmin: true } });
  let assignes = 0;

  for (const user of tousLesUsers) {
    const existing = await prisma.userBoutiqueAssignment.findFirst({
      where: { utilisateurId: user.id, boutiqueId: boutique.id }
    });
    if (!existing) {
      await prisma.userBoutiqueAssignment.create({
        data: {
          utilisateurId: user.id,
          boutiqueId: boutique.id,
          roleId: adminRole?.id || null,
          isActive: true
        }
      });
      assignes++;
      console.log(`   ✅ Utilisateur "${user.nomUtilisateur}" assigné à la boutique principale`);
    }
  }

  if (assignes === 0) {
    console.log(`   ✅ Tous les utilisateurs sont déjà assignés`);
  }

  // ── 5. Migrer les stocks orphelins vers la boutique principale ─────────────
  const stocksOrphelins = await prisma.stock.count();
  if (stocksOrphelins > 0) {
    // Vérifier combien sont déjà dans stock_boutique pour cette boutique
    const dejaMigres = await prisma.stockBoutique.count({ where: { boutiqueId: boutique.id } });
    if (dejaMigres === 0) {
      const stocks = await prisma.stock.findMany();
      let migres = 0;
      for (const s of stocks) {
        const exists = await prisma.stockBoutique.findUnique({
          where: { boutiqueId_produitId: { boutiqueId: boutique.id, produitId: s.produitId } }
        });
        if (!exists) {
          await prisma.stockBoutique.create({
            data: {
              boutiqueId: boutique.id,
              produitId: s.produitId,
              quantiteDisponible: s.quantiteDisponible,
              quantiteReservee: s.quantiteReservee
            }
          });
          migres++;
        }
      }
      if (migres > 0) console.log(`✅ ${migres} stocks migrés vers la boutique principale`);
    } else {
      console.log(`✅ Stocks boutique déjà en place (${dejaMigres} entrées)`);
    }
  }

  console.log('\n🎉 Réparation terminée. Redémarre le backend.');
}

main()
  .catch(e => {
    console.error('❌ Erreur:', e.message);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
