/**
 * Centre de décisions : les cas où l'application ne peut pas trancher seule.
 *
 * Pour chaque cas, on montre les FAITS (stock affiché, ventes jamais déduites, réceptions
 * suspectes...), on propose des RÉSULTATS chiffrés (« stock 98 → 90 ») et c'est la personne qui
 * décide. Le choix est appliqué par un mouvement de correction tracé, jamais en réécrivant
 * l'historique, puis consigné dans le journal des décisions.
 *
 * Cas détectés (par produit et boutique) :
 *  - ventes sans mouvement de stock (typiquement un produit physique marqué « service ») ;
 *  - réceptions suspectes en double (même quantité, même stock de départ, chaîne de stock rompue) ;
 *  - stock affiché différent du dernier mouvement.
 */

const DEFAUT_PRIORITE = { service_avec_stock: 1, vente_sans_mouvement: 1, reception_en_double: 2, ecart_historique: 3 };

// ── Détection (fonction pure : testable sans base) ─────────────────────────────────────────

const ms = (d) => (d instanceof Date ? d.getTime() : Date.parse(d) || 0);

/**
 * @param {Object} data
 * @param {Array}  data.stocks      [{produitId, boutiqueId|null, quantite, produit:{id,nom,reference,estService}, boutiqueNom}]
 * @param {Array}  data.mouvements  [{id, produitId, boutiqueId, typeMouvement, changementQuantite, stockInitial, stockFinal, dateMouvement, referenceId, typeReference}]
 * @param {Array}  data.lignesVente [{venteId, numeroVente, dateVente, boutiqueId, produitId, quantite}]  (ventes non annulées)
 * @param {Object} [data.traites]   {ventes:Set<number>, mouvements:Set<number>, ecarts:Set<string>} déjà décidés
 */
function buildStockCases(data) {
  const traites = data.traites || { ventes: new Set(), mouvements: new Set(), ecarts: new Set() };
  const mvtParProduit = new Map();
  for (const m of data.mouvements) {
    if (!mvtParProduit.has(m.produitId)) mvtParProduit.set(m.produitId, []);
    mvtParProduit.get(m.produitId).push(m);
  }
  const lignesParProduit = new Map();
  for (const l of data.lignesVente) {
    if (!lignesParProduit.has(l.produitId)) lignesParProduit.set(l.produitId, []);
    lignesParProduit.get(l.produitId).push(l);
  }
  // Ventes qui ont bien leur mouvement de stock
  const ventesAvecMouvement = new Set(
    data.mouvements.filter((m) => m.typeMouvement === 'vente' && m.referenceId != null).map((m) => `${m.referenceId}:${m.produitId}`)
  );
  const pairesParProduit = new Map();
  for (const s of data.stocks) pairesParProduit.set(s.produitId, (pairesParProduit.get(s.produitId) || 0) + 1);

  const cas = [];
  for (const s of data.stocks) {
    const produit = s.produit;
    const bId = s.boutiqueId == null ? null : s.boutiqueId;
    const mvts = (mvtParProduit.get(produit.id) || [])
      .filter((m) => (m.boutiqueId == null ? null : m.boutiqueId) === bId)
      .sort((a, b) => ms(a.dateMouvement) - ms(b.dateMouvement) || a.id - b.id);

    const raisons = [];
    const stock = Number(s.quantite);

    // 1. Ventes qui n'ont jamais diminué le stock
    const ventes = (lignesParProduit.get(produit.id) || [])
      .filter((l) => !ventesAvecMouvement.has(`${l.venteId}:${l.produitId}`) && !traites.ventes.has(l.venteId))
      .filter((l) => (l.boutiqueId == null ? pairesParProduit.get(produit.id) === 1 : l.boutiqueId === bId))
      .map((l) => ({ venteId: l.venteId, numeroVente: l.numeroVente, date: l.dateVente, quantite: Number(l.quantite) }))
      .sort((a, b) => ms(a.date) - ms(b.date));
    const unitesVendues = ventes.reduce((t, v) => t + v.quantite, 0);
    if (unitesVendues > 0) {
      raisons.push({
        code: 'vente_sans_mouvement',
        titre: produit.estService
          ? `Produit marqué « service » : ${unitesVendues} unité(s) vendue(s) sans sortie de stock`
          : `${unitesVendues} unité(s) vendue(s) sans mouvement de stock`,
        detail: produit.estService
          ? 'Un service n\'a pas de stock : ces ventes n\'ont rien diminué alors que le produit a reçu de la marchandise.'
          : 'Ces ventes n\'ont créé aucun mouvement de stock : le stock affiché est probablement trop élevé.',
        unites: unitesVendues,
      });
    }

    // Produit « service » qui a du stock, sans vente non déduite à signaler : incohérence à lever
    if (produit.estService && stock !== 0 && !raisons.some((r) => r.code === 'vente_sans_mouvement')) {
      raisons.push({
        code: 'service_avec_stock',
        titre: `Produit marqué « service » mais il a ${stock} unité(s) en stock`,
        detail: "Un service n'a pas de stock : ses ventes ne le diminueraient jamais. Produit physique ou vrai service ?",
      });
    }

    // 2. Réceptions suspectes en double : même quantité, même stock de départ ET chaîne de stock
    //    rompue (un autre poste a saisi la même livraison sans connaître la première)
    const doublons = [];
    const vus = new Map();
    mvts.forEach((m, i) => {
      if (m.typeMouvement !== 'achat' || traites.mouvements.has(m.id)) return;
      const cle = `${m.changementQuantite}|${m.stockInitial}`;
      const precedent = i > 0 ? mvts[i - 1] : null;
      const chaineRompue = !precedent || precedent.stockFinal !== m.stockInitial;
      if (vus.has(cle) && chaineRompue) {
        const original = vus.get(cle);
        doublons.push({
          mouvementId: m.id, doublonDeId: original.id, quantite: Number(m.changementQuantite),
          date: m.dateMouvement, dateOriginal: original.dateMouvement,
        });
      } else if (!vus.has(cle)) {
        vus.set(cle, m);
      }
    });
    const unitesDoublon = doublons.reduce((t, d) => t + d.quantite, 0);
    if (doublons.length > 0) {
      raisons.push({
        code: 'reception_en_double',
        titre: `${doublons.length} réception(s) peut-être saisie(s) deux fois (${unitesDoublon} unité(s))`,
        detail: 'Une même quantité a été reçue deux fois à partir d\'un stock de 0, sans lien entre les deux saisies : '
          + 'même livraison enregistrée sur deux postes, ou deux vraies livraisons ?',
        unites: unitesDoublon,
      });
    }

    // 3. Stock affiché différent du dernier mouvement
    const dernier = mvts.length ? mvts[mvts.length - 1] : null;
    const signature = dernier ? `${bId == null ? 0 : bId}:${produit.id}:${stock}:${dernier.stockFinal}` : null;
    if (dernier && dernier.stockFinal !== stock && !traites.ecarts.has(signature)) {
      raisons.push({
        code: 'ecart_historique',
        titre: `Stock affiché (${stock}) différent du dernier mouvement (${dernier.stockFinal})`,
        detail: 'Le stock a bougé sans que l\'historique le reflète (ou l\'inverse).',
      });
    }

    if (raisons.length === 0) continue;

    // ── Options chiffrées ───────────────────────────────────────────────────────
    const estService = !!produit.estService;
    const options = [];
    // `brut` peut être négatif : l'option est alors contredite par les données (on ne la propose pas,
    // sauf pour les ventes à déduire, où l'on ramène à 0 en le signalant)
    const ajouter = (id, label, description, brut, extra = {}) => {
      if (brut < 0 && id !== 'apres_ventes') return;
      const cible = Math.max(0, Math.trunc(brut));
      const delta = cible - stock;
      options.push({
        id, label,
        description: brut < 0 ? `${description} (Les ventes dépassent le stock affiché : ramené à 0.)` : description,
        cible, delta,
        consequence: `Stock ${stock} → ${cible} (${delta >= 0 ? '+' : ''}${delta})`,
        // Un produit marqué « service » qui garde du stock redevient un produit physique
        marquePhysique: estService && id !== 'service_zero',
        ...extra,
      });
    };
    const prefixe = estService ? 'Produit physique : ' : '';
    ajouter('garder', `${prefixe}garder le stock affiché (${stock})`,
      estService ? 'Le produit redevient un produit physique, sans correction de quantité.' : 'Aucune correction de quantité.', stock);
    if (unitesVendues > 0) {
      ajouter('apres_ventes', `${prefixe}déduire les ${unitesVendues} unité(s) vendue(s) (${Math.max(0, stock - unitesVendues)})`,
        "Le stock affiché moins les ventes qui ne l'avaient pas diminué. À confirmer par un comptage.", stock - unitesVendues,
        { recommandee: true });
    }
    if (doublons.length > 0) {
      ajouter('sans_doublon', `${prefixe}annuler la réception en double (${stock - unitesDoublon})`,
        'Même livraison saisie deux fois : on retire la quantité en trop.', stock - unitesDoublon);
    }
    if (unitesVendues > 0 && doublons.length > 0) {
      ajouter('apres_ventes_et_doublon', `${prefixe}déduire les ventes ET annuler le doublon (${stock - unitesVendues - unitesDoublon})`,
        'Cumule les deux corrections.', stock - unitesVendues - unitesDoublon);
    }
    if (dernier && dernier.stockFinal !== stock) {
      ajouter('dernier_mouvement', `${prefixe}utiliser le dernier mouvement (${dernier.stockFinal})`,
        'Le stock redevient celui indiqué par le dernier mouvement.', dernier.stockFinal);
    }
    if (estService) {
      ajouter('service_zero', "C'est un vrai service : remettre son stock à 0",
        "Le produit reste un service et n'a plus de stock.", 0);
    }

    // Les options qui mènent à la même quantité sont regroupées : on garde la première et on
    // mentionne les autres (rien ne se perd dans l'explication)
    const uniques = [];
    for (const o of options) {
      const meme = o.id === 'service_zero' || o.id === 'garder'
        ? null
        : uniques.find((u) => u.cible === o.cible && u.id !== 'service_zero' && u.id !== 'garder');
      if (meme) {
        meme.description += ` Équivaut aussi à : ${o.label.replace(prefixe, '').toLowerCase()}.`;
      } else {
        uniques.push(o);
      }
    }

    cas.push({
      key: `stock:${produit.id}:${bId == null ? 0 : bId}`,
      type: 'stock',
      produit: { id: produit.id, nom: produit.nom, reference: produit.reference, estService: !!produit.estService },
      boutique: bId == null ? null : { id: bId, nom: s.boutiqueNom || `Boutique n° ${bId}` },
      stockAffiche: stock,
      dernierMouvementStock: dernier ? dernier.stockFinal : null,
      raisons,
      ventes,
      doublons,
      options: uniques,
      priorite: Math.min(...raisons.map((r) => DEFAUT_PRIORITE[r.code] || 9)),
      ecartSignature: signature,
    });
  }
  return cas.sort((a, b) => a.priorite - b.priorite || a.produit.nom.localeCompare(b.produit.nom));
}

/** Cible choisie pour une option donnée (ou une quantité saisie). null si l'option est inconnue. */
function resoudreCible(cas, optionId, cibleManuelle) {
  if (optionId === 'manuel') {
    const n = Number(cibleManuelle);
    return Number.isInteger(n) && n >= 0 ? n : null;
  }
  const o = cas.options.find((x) => x.id === optionId);
  return o ? o.cible : null;
}

// ── Accès aux données et application ───────────────────────────────────────────────────────

class DecisionCenter {
  /**
   * @param {{prisma:Object, syncService?:Object}} deps
   */
  constructor({ prisma, syncService = null }) {
    this.prisma = prisma;
    this.syncService = syncService;
    this._logPret = false;
  }

  get journalDisponible() {
    // Journal local (SQLite) : créé à la demande, comme les tables de suivi de la synchronisation
    return String(process.env.DATABASE_URL || '').startsWith('file:');
  }

  async _assurerJournal() {
    if (this._logPret || !this.journalDisponible) return;
    await this.prisma.$executeRawUnsafe(
      `CREATE TABLE IF NOT EXISTS "decision_log" (
         "id"          INTEGER PRIMARY KEY AUTOINCREMENT,
         "case_key"    TEXT NOT NULL,
         "type"        TEXT NOT NULL,
         "option_id"   TEXT NOT NULL,
         "status"      TEXT NOT NULL,
         "produit_id"  INTEGER,
         "boutique_id" INTEGER,
         "ancien"      INTEGER,
         "nouveau"     INTEGER,
         "user_id"     INTEGER,
         "details"     TEXT,
         "decided_at"  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
       )`
    );
    this._logPret = true;
  }

  async _traites() {
    const traites = { ventes: new Set(), mouvements: new Set(), ecarts: new Set() };
    if (!this.journalDisponible) return traites;
    await this._assurerJournal();
    const rows = await this.prisma.$queryRawUnsafe(`SELECT details FROM decision_log`);
    for (const r of rows) {
      try {
        const d = JSON.parse(r.details || '{}');
        (d.venteIds || []).forEach((id) => traites.ventes.add(Number(id)));
        (d.mouvementIds || []).forEach((id) => traites.mouvements.add(Number(id)));
        if (d.ecartSignature) traites.ecarts.add(d.ecartSignature);
      } catch (_) { /* ligne illisible : ignorée */ }
    }
    return traites;
  }

  async _charger() {
    const p = this.prisma;
    const stocksB = await p.stockBoutique.findMany({
      include: { produit: { select: { id: true, nom: true, reference: true, estService: true } }, boutique: { select: { id: true, nom: true } } },
    });
    const stocksG = await p.stock.findMany({
      include: { produit: { select: { id: true, nom: true, reference: true, estService: true } } },
    });
    // Le stock global ne compte que pour les produits sans stock par boutique (mode sans boutiques)
    const avecBoutique = new Set(stocksB.map((s) => s.produitId));
    const stocks = [
      ...stocksB.map((s) => ({ produitId: s.produitId, boutiqueId: s.boutiqueId, quantite: s.quantiteDisponible, produit: s.produit, boutiqueNom: s.boutique && s.boutique.nom })),
      ...stocksG.filter((s) => !avecBoutique.has(s.produitId)).map((s) => ({ produitId: s.produitId, boutiqueId: null, quantite: s.quantiteDisponible, produit: s.produit, boutiqueNom: null })),
    ];
    const ids = [...new Set(stocks.map((s) => s.produitId))];
    if (ids.length === 0) return { stocks, mouvements: [], lignesVente: [] };

    const mouvements = await p.mouvementStock.findMany({
      where: { produitId: { in: ids } },
      select: { id: true, produitId: true, boutiqueId: true, typeMouvement: true, changementQuantite: true, stockInitial: true, stockFinal: true, dateMouvement: true, referenceId: true, typeReference: true },
    });
    const details = await p.detailVente.findMany({
      where: { produitId: { in: ids }, vente: { statut: { not: 'annulee' } } },
      select: { venteId: true, produitId: true, quantite: true, vente: { select: { numeroVente: true, dateVente: true, boutiqueId: true } } },
    });
    const lignesVente = details.map((d) => ({
      venteId: d.venteId, numeroVente: d.vente.numeroVente, dateVente: d.vente.dateVente, boutiqueId: d.vente.boutiqueId,
      produitId: d.produitId, quantite: d.quantite,
    }));
    return { stocks, mouvements, lignesVente };
  }

  /** Cas à décider (hors ceux déjà traités ou laissés tels quels). */
  async listCases() {
    const data = await this._charger();
    data.traites = await this._traites();
    const cas = buildStockCases(data);
    return { cases: cas, total: cas.length };
  }

  /**
   * Applique la décision prise.
   * @param {{caseKey:string, optionId:string, cible?:number, marquerPhysique?:boolean, stockVu:number, userId?:number}} d
   */
  async apply({ caseKey, optionId, cible, marquerPhysique, stockVu, userId = null }) {
    const { cases } = await this.listCases();
    const cas = cases.find((c) => c.key === caseKey);
    if (!cas) {
      const e = new Error('Ce cas n\'existe plus (déjà traité ou résolu). Actualisez la liste.');
      e.status = 404;
      throw e;
    }
    if (Number(stockVu) !== cas.stockAffiche) {
      const e = new Error(`Le stock a changé depuis l'affichage (${stockVu} → ${cas.stockAffiche}). Actualisez la liste avant de décider.`);
      e.status = 409;
      throw e;
    }

    await this._assurerJournal();
    const detailsTraites = {
      venteIds: cas.ventes.map((v) => v.venteId),
      mouvementIds: cas.doublons.map((d) => d.mouvementId),
      ecartSignature: cas.ecartSignature,
    };
    const journaliser = async (statut, ancien, nouveau, extra = {}) => {
      if (!this.journalDisponible) return;
      await this.prisma.$executeRawUnsafe(
        `INSERT INTO decision_log (case_key, type, option_id, status, produit_id, boutique_id, ancien, nouveau, user_id, details)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        caseKey, cas.type, optionId, statut, cas.produit.id, cas.boutique ? cas.boutique.id : null, ancien, nouveau, userId,
        JSON.stringify({ ...detailsTraites, ...extra })
      );
    };

    // « Laisser tel quel » : on ne touche à rien et on ne remontre pas ce cas
    if (optionId === 'ignorer') {
      await journaliser('ignore', cas.stockAffiche, cas.stockAffiche);
      return { statut: 'ignore', cas: caseKey };
    }

    const nouveau = resoudreCible(cas, optionId, cible);
    if (nouveau === null) {
      const e = new Error('Option inconnue ou quantité invalide (entier positif ou nul attendu).');
      e.status = 400;
      throw e;
    }
    const option = cas.options.find((o) => o.id === optionId);
    const libelle = option ? option.label : `Quantité saisie : ${nouveau}`;
    // Un produit marqué « service » qui garde du stock redevient un produit physique, sauf « vrai service »
    const doitMarquerPhysique = cas.produit.estService && optionId !== 'service_zero' && marquerPhysique !== false;
    const ancien = cas.stockAffiche;
    const delta = nouveau - ancien;

    const resultat = await this.prisma.$transaction(async (tx) => {
      let produitMaj = null;
      if (doitMarquerPhysique) {
        produitMaj = await tx.produit.update({ where: { id: cas.produit.id }, data: { estService: false } });
      }
      let ligneStock = null;
      let mouvement = null;
      if (delta !== 0) {
        if (cas.boutique) {
          ligneStock = await tx.stockBoutique.update({
            where: { boutiqueId_produitId: { boutiqueId: cas.boutique.id, produitId: cas.produit.id } },
            data: { quantiteDisponible: nouveau },
          });
        } else {
          ligneStock = await tx.stock.update({ where: { produitId: cas.produit.id }, data: { quantiteDisponible: nouveau } });
        }
        mouvement = await tx.mouvementStock.create({
          data: {
            produitId: cas.produit.id,
            boutiqueId: cas.boutique ? cas.boutique.id : null,
            typeMouvement: 'correction',
            changementQuantite: delta,
            stockInitial: ancien,
            stockFinal: nouveau,
            typeReference: 'decision',
            notes: `Décision utilisateur : ${libelle}. Stock ${ancien} → ${nouveau}.`
              + (cas.ventes.length ? ` Ventes concernées : ${cas.ventes.map((v) => v.numeroVente).join(', ')}.` : ''),
          },
        });
      }
      return { produitMaj, ligneStock, mouvement };
    });

    await journaliser('applique', ancien, nouveau, { libelle, marquePhysique: doitMarquerPhysique, mouvementCorrectionId: resultat.mouvement ? resultat.mouvement.id : null });

    // Synchronisation vers Neon (les hooks Prisma ne s'appliquent pas aux transactions)
    if (this.syncService && typeof this.syncService.enqueue === 'function') {
      try {
        if (resultat.produitMaj) await this.syncService.enqueue('produits', 'UPDATE', resultat.produitMaj);
        if (resultat.ligneStock) await this.syncService.enqueue(cas.boutique ? 'stock_boutiques' : 'stock', 'UPDATE', resultat.ligneStock);
        if (resultat.mouvement) await this.syncService.enqueue('mouvements_stock', 'INSERT', resultat.mouvement);
      } catch (e) {
        console.warn('⚠️  Décision appliquée mais synchronisation non planifiée:', e.message);
      }
    }

    return { statut: 'applique', cas: caseKey, ancien, nouveau, delta, produitMarquePhysique: doitMarquerPhysique, mouvementId: resultat.mouvement ? resultat.mouvement.id : null };
  }
}

module.exports = { DecisionCenter, buildStockCases, resoudreCible };
