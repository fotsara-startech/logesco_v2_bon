/**
 * Garde-fous « produit service » / stock.
 *
 * Un produit marqué « service » n'a pas de stock : la vente ne crée aucun mouvement et ne
 * diminue rien. Mais rien n'empêchait d'y RECEVOIR du stock (réception de commande, ajustement,
 * mouvement) : le stock montait sans jamais redescendre, et 130 unités vendues n'ont jamais
 * quitté le stock d'un client. Ces fonctions bloquent l'incohérence à la source et la détectent.
 */

/** Message à afficher quand on tente d'ajouter du stock à un service. */
function messageProduitService(noms) {
  const liste = (Array.isArray(noms) ? noms : [noms]).filter(Boolean);
  const sujet = liste.length > 1
    ? `Les produits ${liste.map((n) => `« ${n} »`).join(', ')} sont marqués « service »`
    : `Le produit « ${liste[0] || 'sélectionné'} » est marqué « service »`;
  const possessif = liste.length > 1 ? 'leur' : 'son';
  const stock = `${possessif} stock n'est pas géré, une vente ne le diminuerait jamais`;
  return `${sujet} : ${stock}. `
    + `Si c'est bien un produit physique, décochez « service » dans sa fiche puis recommencez.`;
}

/** Quantité totale en stock d'un produit (stock global + stocks par boutique). */
async function stockTotalProduit(prisma, produitId) {
  const id = Number(produitId);
  const [boutiques, global] = await Promise.all([
    prisma.stockBoutique.aggregate({ where: { produitId: id }, _sum: { quantiteDisponible: true } }),
    prisma.stock.findUnique({ where: { produitId: id }, select: { quantiteDisponible: true } }),
  ]);
  return Number((boutiques._sum && boutiques._sum.quantiteDisponible) || 0) + Number((global && global.quantiteDisponible) || 0);
}

/**
 * Produits marqués « service » qui ont pourtant reçu du stock : très probablement des produits
 * physiques mal marqués. Pour chacun : quantités reçues, vendues, stock affiché.
 */
async function produitsServiceAvecStock(prisma) {
  const services = await prisma.produit.findMany({
    where: { estService: true },
    select: { id: true, reference: true, nom: true },
    orderBy: { id: 'asc' },
  });
  if (services.length === 0) return [];
  const ids = services.map((p) => p.id);

  const [recus, boutiques, globaux, vendus] = await Promise.all([
    prisma.mouvementStock.groupBy({ by: ['produitId'], where: { produitId: { in: ids }, typeMouvement: 'achat' }, _sum: { changementQuantite: true }, _count: { _all: true } }),
    prisma.stockBoutique.groupBy({ by: ['produitId'], where: { produitId: { in: ids } }, _sum: { quantiteDisponible: true } }),
    prisma.stock.findMany({ where: { produitId: { in: ids } }, select: { produitId: true, quantiteDisponible: true } }),
    prisma.detailVente.groupBy({ by: ['produitId'], where: { produitId: { in: ids }, vente: { statut: { not: 'annulee' } } }, _sum: { quantite: true } }),
  ]);
  const parId = (rows, lire) => new Map(rows.map((r) => [r.produitId, lire(r)]));
  const recu = parId(recus, (r) => Number(r._sum.changementQuantite || 0));
  const nbReceptions = parId(recus, (r) => Number(r._count._all || 0));
  const enBoutique = parId(boutiques, (r) => Number(r._sum.quantiteDisponible || 0));
  const global = parId(globaux, (r) => Number(r.quantiteDisponible || 0));
  const vendu = parId(vendus, (r) => Number(r._sum.quantite || 0));

  return services
    .map((p) => ({
      id: p.id,
      reference: p.reference,
      nom: p.nom,
      quantiteRecue: recu.get(p.id) || 0,
      nbReceptions: nbReceptions.get(p.id) || 0,
      quantiteVendue: vendu.get(p.id) || 0,
      stockAffiche: (enBoutique.get(p.id) || 0) + (global.get(p.id) || 0),
    }))
    // « a eu du stock » = au moins une réception, ou une quantité en stock
    .filter((p) => p.nbReceptions > 0 || p.stockAffiche !== 0)
    .map((p) => ({ ...p, ventesSansSortieDeStock: p.quantiteVendue }));
}

module.exports = { messageProduitService, stockTotalProduit, produitsServiceAvecStock };
