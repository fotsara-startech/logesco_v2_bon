/**
 * Migration: ajouter la colonne quantite à historique_prix_achat
 * et recalculer les CUMP existants avec la vraie formule pondérée.
 */
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function run() {
  // 1. Ajouter la colonne quantite (défaut 1 pour les entrées existantes)
  try {
    await prisma.$executeRawUnsafe(
      'ALTER TABLE historique_prix_achat ADD COLUMN quantite REAL DEFAULT 1'
    );
    console.log('✅ Colonne quantite ajoutée');
  } catch(e) {
    console.log('⚠️  quantite déjà existante');
  }

  // 1b. Initialiser les NULL à 1
  await prisma.$executeRawUnsafe(
    'UPDATE historique_prix_achat SET quantite = 1 WHERE quantite IS NULL'
  );
  console.log('✅ Valeurs NULL initialisées à 1');

  // 2. Mettre à jour les entrées issues d'approvisionnements avec la vraie quantité reçue
  const updated = await prisma.$executeRawUnsafe(`
    UPDATE historique_prix_achat
    SET quantite = COALESCE(
      (
        SELECT d.quantite_recue
        FROM details_commandes_approvisionnement d
        WHERE d.id = historique_prix_achat.reference_id
          AND historique_prix_achat.source = 'approvisionnement'
          AND d.quantite_recue > 0
      ),
      1
    )
    WHERE source = 'approvisionnement'
  `);
  console.log('✅ Quantités mises à jour depuis les approvisionnements:', updated, 'lignes');

  // 3. Recalculer tous les CUMP avec la vraie formule pondérée
  const produits = await prisma.$queryRawUnsafe(
    'SELECT DISTINCT produit_id FROM historique_prix_achat'
  );

  let recalcules = 0;
  for (const { produit_id } of produits) {
    const rows = await prisma.$queryRawUnsafe(
      'SELECT prix_achat, quantite FROM historique_prix_achat WHERE produit_id = ?',
      produit_id
    );
    const totalQte = rows.reduce((s, r) => s + (r.quantite || 1), 0);
    const totalCout = rows.reduce((s, r) => s + (r.prix_achat * (r.quantite || 1)), 0);
    if (totalQte > 0) {
      const cump = totalCout / totalQte;
      await prisma.$executeRawUnsafe(
        'UPDATE produits SET cump = ? WHERE id = ?',
        cump,
        produit_id
      );
      recalcules++;
    }
  }
  console.log('✅ CUMP recalculés (formule pondérée):', recalcules, 'produits');

  // Vérification
  const check = await prisma.$queryRawUnsafe(
    'SELECT id, nom, prix_achat, cump FROM produits WHERE cump IS NOT NULL LIMIT 5'
  );
  console.log('\nVérification:');
  check.forEach(r => console.log(`  ${r.nom}: prix_achat=${r.prix_achat} | cump=${r.cump?.toFixed(2)}`));

  await prisma.$disconnect();
  console.log('\n🎉 Migration terminée!');
}

run().catch(e => { console.error(e.message); process.exit(1); });
