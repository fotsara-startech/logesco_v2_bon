/**
 * Centre de décisions : réception saisie deux fois sur deux postes (même quantité, même stock de départ).
 *
 *   1. la même livraison (10 unités) est saisie sur A et sur B avant toute synchronisation ;
 *   2. après convergence le stock doit refléter l'historique (deux mouvements d'achat) ;
 *   3. GET /decisions liste le cas « réception en double » ;
 *   4. on applique « annuler la réception en double » sur A : le mouvement de correction doit arriver sur B, C et le cloud ;
 *   5. le cas doit alors être clos PARTOUT (sinon B proposerait de retirer une seconde fois les mêmes 10 unités).
 *
 *   SYNC_TEST_NEON_URL='postgresql://…' node --experimental-sqlite --test tests/e2e-sync/scenarios/40-metier-decisions.test.js
 */
const test = require('node:test');
const assert = require('node:assert');
const { nouvelleCampagne, peutLancer } = require('../harness/campagne');
const { SPECS_PAR_DEFAUT, attendreConvergence, decrire } = require('../harness/oracle');
const M = require('../harness/aide-metier');

const lancement = peutLancer();
const skip = lancement.ok ? false : lancement.raison;

const SPECS = { ...SPECS_PAR_DEFAUT, mouvements_stock: [...SPECS_PAR_DEFAUT.mouvements_stock, 'type_reference'] };

test('centre de décisions : réception en double sur deux postes, décision appliquée sur A, propagation',
  { skip, timeout: 1800000 }, async (t) => {
    const c = await nouvelleCampagne({ etiquette: 'metier', postes: ['A', 'B', 'C'] });
    t.after(() => c.terminer());
    const { A, B, C } = c.postes;
    const POSTES = [A, B, C];
    const converger = async (quoi) => {
      const r = await M.avecReprise(() => attendreConvergence({ stations: POSTES, cloudUrl: c.cloudUrl, specs: SPECS, delaiMs: 300000 }));
      assert.ok(r.ok, `pas de convergence (${quoi}) : ${decrire(r.differences)}`);
    };
    const bq = Number(A.lire('SELECT id FROM boutiques WHERE est_principale = 1')[0].id);
    const ids = {};
    const casDe = async (poste) => {
      const r = await poste.api('GET', '/decisions');
      assert.strictEqual(r.statut, 200, JSON.stringify(r.corps).slice(0, 300));
      return (r.corps.data.cases || []).filter((x) => x.produit && x.produit.id === ids.p);
    };

    await t.test('préparation : produit synchronisé partout, puis la même réception saisie sur A et B en même temps', async () => {
      ids.p = await M.creerProduit(A, { reference: 'DEC-1', nom: 'Produit livraison' });
      await converger('produit');
      const [ra, rb] = await Promise.all([
        A.api('POST', '/inventory/movements', { produitId: ids.p, boutiqueId: bq, typeMouvement: 'achat', changementQuantite: 10, notes: 'livraison saisie sur A' }),
        B.api('POST', '/inventory/movements', { produitId: ids.p, boutiqueId: bq, typeMouvement: 'achat', changementQuantite: 10, notes: 'livraison saisie sur B' }),
      ]);
      assert.strictEqual(ra.statut, 201, JSON.stringify(ra.corps).slice(0, 300));
      assert.strictEqual(rb.statut, 201, JSON.stringify(rb.corps).slice(0, 300));
      const si = (p) => Number(p.lire("SELECT stock_initial s FROM mouvements_stock WHERE produit_id = ? AND type_mouvement = 'achat' ORDER BY id LIMIT 1", ids.p)[0].s);
      // si un cycle de synchro est passé entre les deux saisies, le scénario n'est plus « simultané » : on le dit
      assert.strictEqual(si(A), 0, 'A a saisi à partir d\'un stock de 0');
      assert.strictEqual(si(B), 0, 'B a saisi à partir d\'un stock de 0 (saisies bien simultanées)');
      await converger('double réception');
    });

    await t.test('après convergence : le stock correspond à l\'historique (deux mouvements de +10)', { todo: 'DÉFAUT CONNU : stock envoyé en valeur absolue, entrées simultanées écrasées (10 au lieu de 20)' }, async () => {
      const mv = M.identiques(assert, await M.partout(c, POSTES, "SELECT changement_quantite q, stock_initial si, stock_final sf FROM mouvements_stock WHERE produit_id = $1 AND type_mouvement = 'achat' ORDER BY stock_final, id", [ids.p]), 'mouvements d\'achat');
      assert.strictEqual(mv.length, 2, 'les deux saisies sont conservées (aucune perdue, aucun doublon technique)');
      const somme = mv.reduce((s, x) => s + Number(x.q), 0);
      const stock = M.identiques(assert, await M.partout(c, POSTES, 'SELECT quantite_disponible q FROM stock_boutiques WHERE produit_id = $1 AND boutique_id = $2', [ids.p, bq]), 'stock');
      // DÉFAUT CONNU : le stock est envoyé en valeur absolue (« dernière écriture gagne ») : deux entrées simultanées sur deux
      // postes donnent 10 au lieu de 20, alors que l'historique contient +20. Voir rapport (stock_boutiques envoyé en absolu).
      t.diagnostic(`stock final ${stock[0].q} pour ${somme} unités dans l'historique`);
      assert.strictEqual(Number(stock[0].q), somme, `stock (${stock[0].q}) = somme des mouvements (${somme})`);
    });

    await t.test('GET /decisions liste la réception en double (sur A, B et C)', async () => {
      for (const p of POSTES) {
        const cas = await casDe(p);
        assert.strictEqual(cas.length, 1, `${p.nom} : un cas pour le produit`);
        assert.ok(cas[0].raisons.some((r) => r.code === 'reception_en_double'), `${p.nom} : raisons ${cas[0].raisons.map((r) => r.code)}`);
        assert.ok(cas[0].options.some((o) => o.id === 'sans_doublon'), `${p.nom} : option « annuler la réception en double »`);
      }
    });

    await t.test('décision « annuler la réception en double » sur A → correction propagée sur B, C et le cloud', async () => {
      const [cas] = await casDe(A);
      const opt = cas.options.find((o) => o.id === 'sans_doublon');
      const r = await A.api('POST', '/decisions/apply', { caseKey: cas.key, optionId: 'sans_doublon', stockVu: cas.stockAffiche });
      assert.strictEqual(r.statut, 200, JSON.stringify(r.corps).slice(0, 400));
      assert.strictEqual(r.corps.data.nouveau, opt.cible);
      ids.apresDecision = opt.cible;
      ids.delta = r.corps.data.delta;
      await converger('décision appliquée');
      const corr = M.identiques(assert, await M.partout(c, POSTES, "SELECT type_mouvement, changement_quantite q, stock_final sf, type_reference FROM mouvements_stock WHERE produit_id = $1 AND type_mouvement = 'correction'", [ids.p]), 'mouvement de correction');
      assert.strictEqual(corr.length, 1, 'un seul mouvement de correction partout');
      assert.strictEqual(Number(corr[0].q), ids.delta);
      M.identiques(assert, await M.partout(c, POSTES, 'SELECT quantite_disponible q FROM stock_boutiques WHERE produit_id = $1 AND boutique_id = $2', [ids.p, bq]), 'stock après décision');
      for (const p of POSTES) assert.strictEqual(M.stockPoste(p, ids.p, bq), ids.apresDecision, `${p.nom} : stock = ${ids.apresDecision}`);
    });

    await t.test('le cas est clos sur tous les postes (B ne propose pas de retirer les mêmes 10 unités une seconde fois)', { todo: 'DÉFAUT CONNU : decision_log local à chaque poste (decision-center.js _traites), la décision de A est inconnue de B/C' }, async () => {
      for (const p of POSTES) {
        const doublons = (await casDe(p)).filter((x) => x.raisons.some((r) => r.code === 'reception_en_double'));
        // DÉFAUT CONNU : le journal des décisions (decision_log) est local à chaque poste et n'est pas synchronisé :
        // les postes B et C ne savent pas que A a déjà tranché et reproposent « annuler la réception en double ».
        assert.strictEqual(doublons.length, 0, `${p.nom} : la réception en double est de nouveau proposée alors qu'elle a été traitée sur A`);
      }
    });
  });
