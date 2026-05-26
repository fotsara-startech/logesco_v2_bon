/**
 * Service CUMP - Cout Unitaire Moyen Pondere
 *
 * Formule correcte : CUMP = Somme(quantite x prix_achat) / Somme(quantite)
 */

async function recalculerCump(prisma, produitId) {
  const rows = await prisma.historiquePrixAchat.findMany({
    where: { produitId: produitId },
    select: { prixAchat: true, quantite: true }
  });

  if (!rows || rows.length === 0) return null;

  const totalQte  = rows.reduce((s, r) => s + (r.quantite || 1), 0);
  const totalCout = rows.reduce((s, r) => s + ((r.prixAchat || 0) * (r.quantite || 1)), 0);

  if (totalQte === 0) return null;

  const cump = totalCout / totalQte;

  // Utiliser Prisma ORM pour que le hook de sync soit déclenché
  await prisma.produit.update({
    where: { id: produitId },
    data: { cump: cump }
  });

  return cump;
}

async function enregistrerPrixAchatEtRecalculerCump(prisma, produitId, prixAchat, source, referenceId, quantite) {
  if (!prixAchat || prixAchat <= 0) return null;

  const qte = (quantite && quantite > 0) ? quantite : 1;

  // Utiliser Prisma ORM pour que le hook de sync soit déclenché
  await prisma.historiquePrixAchat.create({
    data: {
      produitId: produitId,
      prixAchat: prixAchat,
      quantite: qte,
      source: source || 'manuel',
      referenceId: referenceId || null
    }
  });

  return await recalculerCump(prisma, produitId);
}

module.exports = { recalculerCump, enregistrerPrixAchatEtRecalculerCump };
