/**
 * Générateurs de charge locale pour les scénarios réseau : produits, stock, ventes créés par l'API du poste.
 * (Les écritures sont locales et rapides : c'est la synchronisation qui souffre de la liaison.)
 */
const admin = require('./cloud-admin');

/** Crée n produits sur le poste. Rend les identifiants. */
async function creerProduits(station, n, prefixe, { stock = 0 } = {}) {
  const ids = [];
  for (let i = 1; i <= n; i++) {
    const r = await station.api('POST', '/products', { reference: `${prefixe}-${String(i).padStart(3, '0')}`, nom: `Produit ${prefixe} ${i}`, prixUnitaire: 1000, prixAchat: 500, seuilStockMinimum: 1 });
    if (r.statut !== 201) throw new Error(`création produit ${prefixe}-${i} : ${r.statut} ${JSON.stringify(r.corps).slice(0, 200)}`);
    ids.push(r.corps.data.id);
    if (stock) {
      const a = await station.api('POST', '/inventory/adjust', { produitId: r.corps.data.id, changementQuantite: stock });
      if (a.statut !== 200) throw new Error(`stock produit ${prefixe}-${i} : ${a.statut}`);
    }
  }
  return ids;
}

/** Crée n ventes comptant d'une ligne (les produits doivent avoir du stock). */
async function creerVentes(station, produitIds, n) {
  const numeros = [];
  for (let i = 0; i < n; i++) {
    const id = produitIds[i % produitIds.length];
    const r = await station.api('POST', '/sales', { modePaiement: 'comptant', montantPaye: 1000, details: [{ produitId: id, quantite: 1, prixUnitaire: 1000, prixAffiche: 1000 }] });
    if (r.statut !== 201) throw new Error(`création vente ${i} : ${r.statut} ${JSON.stringify(r.corps).slice(0, 200)}`);
    numeros.push(r.corps.data.numeroVente);
  }
  return numeros;
}

/** Nombre de lignes d'une table dans le cloud de test */
async function compterCloud(cloudUrl, table, where = '') {
  return Number((await admin.requete(cloudUrl, `SELECT COUNT(*) n FROM "${table}" ${where}`))[0].n);
}

module.exports = { creerProduits, creerVentes, compterCloud };
