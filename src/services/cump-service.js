/**
 * Service CUMP - Cout Unitaire Moyen Pondere
 *
 * Formule correcte : CUMP = Somme(quantite x prix_achat) / Somme(quantite)
 */

async function recalculerCump(prisma, produitId) {
  const rows = await prisma.$queryRawUnsafe(
    'SELECT prix_achat, COALESCE(quantite, 1) as quantite FROM historique_prix_achat WHERE produit_id = ?',
    produitId
  );

  if (!rows || rows.length === 0) return null;

  const totalQte  = rows.reduce((s, r) => s + (r.quantite || 1), 0);
  const totalCout = rows.reduce((s, r) => s + ((r.prix_achat || 0) * (r.quantite || 1)), 0);

  if (totalQte === 0) return null;

  const cump = totalCout / totalQte;

  await prisma.$executeRawUnsafe(
    'UPDATE produits SET cump = ? WHERE id = ?',
    cump,
    produitId
  );

  return cump;
}

async function enregistrerPrixAchatEtRecalculerCump(prisma, produitId, prixAchat, source, referenceId, quantite) {
  if (!prixAchat || prixAchat <= 0) return null;

  const qte = (quantite && quantite > 0) ? quantite : 1;

  await prisma.$executeRawUnsafe(
    'INSERT INTO historique_prix_achat (produit_id, prix_achat, quantite, source, reference_id) VALUES (?, ?, ?, ?, ?)',
    produitId,
    prixAchat,
    qte,
    source || 'manuel',
    referenceId || null
  );

  return await recalculerCump(prisma, produitId);
}

module.exports = { recalculerCump, enregistrerPrixAchatEtRecalculerCump };
