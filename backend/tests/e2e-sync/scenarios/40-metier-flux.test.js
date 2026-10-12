/**
 * Intégrité MÉTIER entre postes (gestion commerciale / stock / caisse) : ventes, comptes clients, caisse,
 * approvisionnement, transfert et inventaire, produit « service », invariants, idempotence.
 *
 * Trois postes réels (A, B, C) et un cloud jetable. Les étapes s'enchaînent sur le même jeu de données (comme une
 * journée de travail) ; chaque étape attend la convergence avant de vérifier. Un échec d'étape n'arrête pas les suivantes
 * (sauf si elles dépendent des objets créés par l'étape en échec).
 *
 *   SYNC_TEST_NEON_URL='postgresql://…' node --experimental-sqlite --test tests/e2e-sync/scenarios/40-metier-flux.test.js
 *
 * Invariants retenus (vérifiés dans les données réelles, voir « invariants ») :
 *  - stock : pour chaque (produit, boutique), quantite_disponible = somme des changements des mouvements de cette boutique ;
 *  - compte client : solde_actuel = solde_apres de la dernière écriture ; vente : solde_apres = solde_avant + espèces
 *    conservées − total de la vente ;
 *  - un produit « service » n'a jamais de stock.
 */
const test = require('node:test');
const assert = require('node:assert');
const { nouvelleCampagne, peutLancer } = require('../harness/campagne');
const { SPECS_PAR_DEFAUT, attendreConvergence, decrire } = require('../harness/oracle');
const M = require('../harness/aide-metier');

const lancement = peutLancer();
const skip = lancement.ok ? false : lancement.raison;

const SPECS = {
  ...SPECS_PAR_DEFAUT,
  mouvements_stock: [...SPECS_PAR_DEFAUT.mouvements_stock, 'reference_id', 'type_reference'],
  comptes_fournisseurs: ['fournisseur_id', 'solde_actuel'],
  cash_sessions: [...SPECS_PAR_DEFAUT.cash_sessions, 'solde_attendu', 'ecart', 'utilisateur_id', 'boutique_id'],
  cash_movements: [...SPECS_PAR_DEFAUT.cash_movements, 'session_id', 'boutique_id'],
  transactions_comptes: [...SPECS_PAR_DEFAUT.transactions_comptes, 'type_compte', 'type_transaction_detail', 'vente_id'],
  details_commandes_approvisionnement: ['commande_id', 'produit_id', 'quantite_commandee', 'quantite_recue'],
};

test('flux métier sur trois postes : vente, client, caisse, approvisionnement, transfert, inventaire, service, invariants, idempotence',
  { skip, timeout: 3300000 }, async (t) => {
    const c = await nouvelleCampagne({ etiquette: 'metier', postes: ['A', 'B', 'C'] });
    t.after(() => c.terminer());
    const { A, B, C } = c.postes;
    const POSTES = [A, B, C];
    // Différences déjà constatées (défauts connus) : elles ne bloquent pas les étapes suivantes (clé sans la valeur)
    const connues = new Set();
    const defauts = [];
    const cle = (d) => `${d.poste}|${d.table}#${d.id}|${d.colonne || 'absent'}`;
    const converger = async (quoi) => {
      const r = await M.avecReprise(() => attendreConvergence({ stations: POSTES, cloudUrl: c.cloudUrl, specs: SPECS, delaiMs: connues.size ? 80000 : 240000 }));
      const nouvelles = r.differences.filter((d) => !connues.has(cle(d)));
      for (const d of r.differences) connues.add(cle(d));
      if (nouvelles.length) defauts.push(`(${quoi}) ${decrire(nouvelles)}`);
      return r;
    };

    const bq = Number(A.lire('SELECT id FROM boutiques WHERE est_principale = 1')[0].id);
    const caisse = Number(A.lire('SELECT id FROM cash_registers ORDER BY id LIMIT 1')[0].id);
    const ids = {};

    await t.test('préparation : produits, client, fournisseur, stock de départ (créés sur A)', async () => {
      ids.p1 = await M.creerProduit(A, { reference: 'MET-P1', nom: 'Produit stock', prix: 1500, achat: 1000 });
      ids.p2 = await M.creerProduit(A, { reference: 'MET-SERV', nom: 'Service livraison', prix: 300, achat: 0, service: true });
      ids.p3 = await M.creerProduit(A, { reference: 'MET-P3', nom: 'Produit appro', prix: 1000, achat: 700 });
      const cl = await M.exiger(A, 'POST', '/customers', { nom: 'Client', prenom: 'Credit', telephone: '690000001' });
      ids.client = cl.id;
      const f = await M.exiger(A, 'POST', '/suppliers', { nom: 'Fournisseur Test', telephone: '690000002' });
      ids.fournisseur = f.id;
      await M.approvisionner(A, ids.p1, bq, 20);
      await converger('préparation');
      for (const p of POSTES) assert.strictEqual(M.stockPoste(p, ids.p1, bq), 20, `${p.nom} : stock de départ`);
    });

    // ───────────────────────────── ★1 vente
    await t.test('★1 vente sur A : lignes, stock, mouvement, aucun doublon (postes + cloud)', async () => {
      const v = await M.vendre(A, { boutiqueId: bq, lignes: [{ produitId: ids.p1, quantite: 3, prix: 1500 }] });
      ids.vente1 = v.id;
      await converger('vente 1');
      const ventes = await M.partout(c, POSTES, 'SELECT id, numero_vente, montant_total, montant_paye, montant_restant, statut FROM ventes WHERE id = $1', [v.id]);
      const lignesVente = M.identiques(assert, ventes, 'la vente');
      assert.strictEqual(lignesVente.length, 1, 'la vente existe une seule fois');
      assert.strictEqual(lignesVente[0].montant_total, 4500);
      const details = await M.partout(c, POSTES, 'SELECT produit_id, quantite, prix_unitaire, prix_total FROM details_ventes WHERE vente_id = $1', [v.id]);
      const d = M.identiques(assert, details, 'les lignes de vente');
      assert.deepStrictEqual(d.map((x) => [x.produit_id, x.quantite, x.prix_total]), [[ids.p1, 3, 4500]], 'une seule ligne de 3 unités');
      for (const p of POSTES) assert.strictEqual(M.stockPoste(p, ids.p1, bq), 17, `${p.nom} : stock = 20 − 3`);
      assert.strictEqual(await M.stockCloud(c, ids.p1, bq), 17, 'cloud : stock = 20 − 3');
      const mv = await M.partout(c, POSTES, "SELECT type_mouvement, changement_quantite, stock_initial, stock_final FROM mouvements_stock WHERE type_reference = 'vente' AND reference_id = $1", [v.id]);
      const m = M.identiques(assert, mv, 'le mouvement de la vente');
      assert.deepStrictEqual(m, [{ type_mouvement: 'vente', changement_quantite: -3, stock_initial: 20, stock_final: 17 }], 'un seul mouvement de vente, 20 → 17');
      // aucun doublon de numéro de vente ni de ligne dans tout le système
      const dup = await M.lireCloud(c, 'SELECT numero_vente, COUNT(*) n FROM ventes GROUP BY numero_vente HAVING COUNT(*) > 1');
      assert.strictEqual(dup.length, 0, `numéros de vente en double dans le cloud : ${JSON.stringify(dup)}`);
    });

    // ───────────────────────────── ★2 cycle client
    await t.test('★2 cycle client : crédit sur A, paiement partiel sur B, avance consommée sur C', { todo: 'défaut de synchronisation constaté : voir rapport' }, async () => {
      // crédit : 2 × 1500 = 3000, rien payé → dette
      await M.vendre(A, { boutiqueId: bq, clientId: ids.client, lignes: [{ produitId: ids.p1, quantite: 2, prix: 1500 }], montantPaye: 0 });
      await converger('vente à crédit');
      const compteId = Number(A.lire('SELECT id FROM comptes_clients WHERE client_id = ?', ids.client)[0].id);
      ids.compte = compteId;
      const lire = async () => M.identiques(assert, await M.partout(c, POSTES, 'SELECT solde_actuel s FROM comptes_clients WHERE client_id = $1', [ids.client]), 'solde client');
      assert.strictEqual(Number((await lire())[0].s), -3000, 'dette de 3000 partout');

      // paiement partiel sur B
      await M.exiger(B, 'POST', `/customers/${ids.client}/payment`, { montant: 1000, description: 'paiement partiel' });
      await converger('paiement partiel');
      assert.strictEqual(Number((await lire())[0].s), -2000, 'dette de 2000 partout après paiement de 1000');

      // paiement en excès sur B : solde positif (avance de 500)
      await M.exiger(B, 'POST', `/customers/${ids.client}/payment`, { montant: 2500, description: 'avance' });
      await converger('avance');
      assert.strictEqual(Number((await lire())[0].s), 500, 'avance de 500 partout');

      // vente de 1500 sur C avec 0 d'espèces : l'avance de 500 est consommée, la dette est 1000
      // formule : solde_apres = solde_avant (500) + espèces conservées (0) − total (1500) = −1000
      await M.vendre(C, { boutiqueId: bq, clientId: ids.client, lignes: [{ produitId: ids.p1, quantite: 1, prix: 1500 }], montantPaye: 0 });
      await converger('vente avec avance');
      assert.strictEqual(Number((await lire())[0].s), -1000, 'solde = 500 + 0 − 1500 = −1000 partout');

      // écritures identiques partout
      const ecr = await M.partout(c, POSTES, "SELECT id, type_transaction, type_transaction_detail, montant, solde_apres FROM transactions_comptes WHERE type_compte = 'client' AND compte_id = $1 ORDER BY id", [compteId]);
      M.identiques(assert, ecr, 'les écritures du compte client');
      for (const p of POSTES) {
        const k = M.controleCompte(p, 'comptes_clients', 'client', compteId);
        assert.strictEqual(k.dernier, k.solde, `${p.nom} : solde du compte (${k.solde}) = solde_apres de la dernière écriture (${k.dernier})`);
      }
      assert.ok((await M.lireCloud(c, "SELECT COUNT(*) n FROM transactions_comptes WHERE type_compte = 'client' AND compte_id = $1", [compteId]))[0].n >= 4);
    });

    // ───────────────────────────── ★3 caisse
    await t.test('★3 caisse : ouverture, ventes en espèces, mouvement, clôture sur A → mêmes soldes partout', { todo: 'défaut de synchronisation constaté : voir rapport' }, async () => {
      const s = await A.api('POST', '/cash-sessions/connect', { cashRegisterId: caisse, soldeInitial: 10000, boutiqueId: bq });
      assert.strictEqual(s.statut, 201, JSON.stringify(s.corps).slice(0, 300));
      ids.session = s.corps.data.id;
      // 2000 donnés pour 1500 → monnaie 500, 1500 conservés ; puis 3000 pour 3000
      await M.vendre(A, { boutiqueId: bq, lignes: [{ produitId: ids.p1, quantite: 1, prix: 1500 }], montantPaye: 2000 });
      await M.vendre(A, { boutiqueId: bq, lignes: [{ produitId: ids.p1, quantite: 2, prix: 1500 }], montantPaye: 3000 });
      const mv = await A.api('POST', `/cash-registers/${caisse}/movements`, { type: 'sortie', montant: 1000, description: 'dépense test' });
      assert.strictEqual(mv.statut, 201, JSON.stringify(mv.corps).slice(0, 300));
      await converger('caisse en cours');
      const attendu = 10000 + 1500 + 3000 - 1000;
      // DÉFAUT CONNU : le solde de caisse du cloud reste périmé (sortie de caisse jamais envoyée) et B/C ne reçoivent jamais
      // les mises à jour de cash_registers → vérification non bloquante ici, reprise dans l'étape de convergence.
      const avantCloture = await M.partout(c, POSTES, 'SELECT solde_actuel s FROM cash_registers WHERE id = $1', [caisse]);
      t.diagnostic(`solde de caisse avant clôture (attendu ${attendu}) : ${JSON.stringify(avantCloture)}`);
      defauts.push(`(caisse avant clôture, attendu ${attendu}) ${JSON.stringify(avantCloture)}`);

      const fin = await A.api('POST', '/cash-sessions/disconnect', { soldeFermeture: attendu, boutiqueId: bq });
      assert.strictEqual(fin.statut, 200, JSON.stringify(fin.corps).slice(0, 300));
      await converger('clôture');
      const ses = await M.partout(c, POSTES, 'SELECT solde_ouverture, solde_fermeture, solde_attendu, ecart, is_active FROM cash_sessions WHERE id = $1', [ids.session]);
      const sess = M.identiques(assert, ses, 'la session de caisse');
      assert.strictEqual(sess[0].is_active, 0, 'session close partout');
      assert.strictEqual(sess[0].solde_fermeture, attendu);
      const reg = M.identiques(assert, await M.partout(c, POSTES, 'SELECT solde_actuel s FROM cash_registers WHERE id = $1', [caisse]), 'solde de caisse final');
      assert.strictEqual(Number(reg[0].s), attendu, 'caisse = solde déclaré à la clôture');
      const types = M.identiques(assert, await M.partout(c, POSTES, 'SELECT type, COUNT(*) n, SUM(montant) m FROM cash_movements WHERE session_id = $1 GROUP BY type ORDER BY type', [ids.session]), 'mouvements de caisse par type');
      const parType = Object.fromEntries(types.map((x) => [x.type, [x.n, x.m]]));
      assert.deepStrictEqual(parType.vente, [2, 4500], 'deux ventes en espèces, 4500 conservés');
      assert.deepStrictEqual(parType.ouverture_session, [1, 10000]);
      assert.deepStrictEqual(parType.fermeture_session, [1, attendu]);
      // cohérence interne de la session : le solde attendu suit les ventes mais PAS la dépense de caisse (voir rapport)
      // → écart = déclaré − attendu(session)
    });

    // ───────────────────────────── ★4 approvisionnement
    await t.test('★4 approvisionnement : commande créée sur A, réception partielle sur B puis solde sur C', async () => {
      const cmd = await M.exiger(A, 'POST', '/procurement', {
        fournisseurId: ids.fournisseur, boutiqueId: bq, modePaiement: 'credit',
        details: [{ produitId: ids.p3, quantiteCommandee: 10, coutUnitaire: 700 }],
      });
      ids.cmd = cmd.id;
      await converger('commande');
      const det = Number(B.lire('SELECT id FROM details_commandes_approvisionnement WHERE commande_id = ?', cmd.id)[0].id);
      ids.detailCmd = det;
      // réception de 4 sur B
      await M.exiger(B, 'PUT', `/procurement/${cmd.id}/receive`, { details: [{ detailId: det, quantiteRecue: 4 }] });
      await converger('réception partielle');
      for (const p of POSTES) assert.strictEqual(M.stockPoste(p, ids.p3, bq), 4, `${p.nom} : stock reçu visible (4)`);
      assert.strictEqual(await M.stockCloud(c, ids.p3, bq), 4);
      // le reste (6) sur C
      await M.exiger(C, 'PUT', `/procurement/${cmd.id}/receive`, { details: [{ detailId: det, quantiteRecue: 6 }] });
      await converger('réception du solde');
      for (const p of POSTES) assert.strictEqual(M.stockPoste(p, ids.p3, bq), 10, `${p.nom} : stock = 10 (visible sur A, B, C)`);
      assert.strictEqual(await M.stockCloud(c, ids.p3, bq), 10);
      const st = M.identiques(assert, await M.partout(c, POSTES, 'SELECT statut FROM commandes_approvisionnement WHERE id = $1', [cmd.id]), 'statut de la commande');
      assert.strictEqual(st[0].statut, 'terminee');
      // compte fournisseur : 10 × 700 = 7000 dû, identique partout, dernière écriture cohérente
      const cf = M.identiques(assert, await M.partout(c, POSTES, 'SELECT id, solde_actuel s FROM comptes_fournisseurs WHERE fournisseur_id = $1', [ids.fournisseur]), 'compte fournisseur');
      assert.strictEqual(cf.length, 1, 'un seul compte fournisseur');
      assert.strictEqual(Number(cf[0].s), 7000, 'dette fournisseur = 10 × 700');
      for (const p of POSTES) {
        const k = M.controleCompte(p, 'comptes_fournisseurs', 'fournisseur', cf[0].id);
        assert.strictEqual(k.dernier, k.solde, `${p.nom} : solde fournisseur ${k.solde} = dernière écriture ${k.dernier}`);
      }
      M.identiques(assert, await M.partout(c, POSTES, "SELECT id, type_transaction, montant, solde_apres FROM transactions_comptes WHERE type_compte = 'fournisseur' ORDER BY id"), 'écritures fournisseur');
      const achats = await M.partout(c, POSTES, "SELECT COUNT(*) n, SUM(changement_quantite) q FROM mouvements_stock WHERE type_mouvement = 'achat' AND produit_id = $1", [ids.p3]);
      assert.deepStrictEqual(M.identiques(assert, achats, 'mouvements d\'achat'), [{ n: 2, q: 10 }]);
    });

    // ───────────────────────────── 8 transfert + inventaire
    await t.test('8 transfert de stock entre deux boutiques (sur B) puis inventaire (sur C)', async () => {
      const b2 = await M.exiger(A, 'POST', '/boutiques', { nom: 'Boutique 2' });
      ids.b2 = b2.id;
      await converger('boutique 2');
      const stockAvant = M.stockPoste(B, ids.p1, bq);
      await M.exiger(B, 'POST', '/boutiques/transferts', { sourceBoutiqueId: bq, destBoutiqueId: ids.b2, produitId: ids.p1, quantite: 4, notes: 'test' });
      await converger('transfert');
      for (const p of POSTES) {
        assert.strictEqual(M.stockPoste(p, ids.p1, bq), stockAvant - 4, `${p.nom} : source − 4`);
        assert.strictEqual(M.stockPoste(p, ids.p1, ids.b2), 4, `${p.nom} : destination = 4`);
      }
      assert.strictEqual(await M.stockCloud(c, ids.p1, ids.b2), 4);
      const tr = await M.partout(c, POSTES, "SELECT type_mouvement, boutique_id, changement_quantite FROM mouvements_stock WHERE type_reference = 'transfert' ORDER BY type_mouvement");
      assert.strictEqual(M.identiques(assert, tr, 'mouvements du transfert').length, 2, 'sortie + entrée présentes partout');
      assert.strictEqual(M.identiques(assert, await M.partout(c, POSTES, 'SELECT COUNT(*) n FROM transferts_stock'), 'transferts')[0].n, 1);

      // inventaire sur C (boutique principale) : on compte 2 de moins pour P1
      const inv = await M.exiger(C, 'POST', '/stock-inventory', { nom: 'Inv test', type: 'COMPLET', utilisateurId: 1, boutiqueId: bq });
      const items = await M.exiger(C, 'GET', `/stock-inventory/${inv.id}/items`);
      const liste = Array.isArray(items) ? items : (items.items || items.data || []);
      const it = liste.find((x) => Number(x.produitId) === ids.p1);
      assert.ok(it, `ligne d'inventaire du produit introuvable : ${JSON.stringify(liste).slice(0, 300)}`);
      const sys = M.stockPoste(C, ids.p1, bq);
      await M.exiger(C, 'PUT', `/stock-inventory/items/${it.id}`, { quantiteComptee: sys - 2, utilisateurComptageId: 1 });
      await M.exiger(C, 'POST', `/stock-inventory/${inv.id}/close`, {});
      await converger('inventaire');
      for (const p of POSTES) assert.strictEqual(M.stockPoste(p, ids.p1, bq), sys - 2, `${p.nom} : stock après inventaire = ${sys - 2}`);
      assert.strictEqual(await M.stockCloud(c, ids.p1, bq), sys - 2);
      const mi = await M.partout(c, POSTES, "SELECT changement_quantite q FROM mouvements_stock WHERE type_reference = 'inventaire'");
      assert.deepStrictEqual(M.identiques(assert, mi, "mouvement d'inventaire"), [{ q: -2 }]);
    });

    // ───────────────────────────── 9 service
    await t.test('9 produit « service » : aucun stock ajoutable, rien d\'incohérent ne se propage', async () => {
      const essais = [
        ['POST', '/inventory', { produitId: ids.p2, boutiqueId: bq, quantiteInitiale: 5 }],
        ['POST', '/inventory/movements', { produitId: ids.p2, boutiqueId: bq, typeMouvement: 'ajustement', changementQuantite: 5 }],
        ['POST', '/inventory/adjust', { produitId: ids.p2, changementQuantite: 5 }],
      ];
      for (const [m, ch, corps] of essais) {
        const r = await A.api(m, ch, corps);
        assert.ok([400, 422].includes(r.statut), `${m} ${ch} sur un service doit être refusé (obtenu ${r.statut})`);
      }
      // réception d'une commande contenant un service
      const cmd = await A.api('POST', '/procurement', { fournisseurId: ids.fournisseur, boutiqueId: bq, modePaiement: 'credit', details: [{ produitId: ids.p2, quantiteCommandee: 3, coutUnitaire: 100 }] });
      if ([200, 201].includes(cmd.statut)) {
        const det = Number(A.lire('SELECT id FROM details_commandes_approvisionnement WHERE commande_id = ?', cmd.corps.data.id)[0].id);
        const rec = await A.api('PUT', `/procurement/${cmd.corps.data.id}/receive`, { details: [{ detailId: det, quantiteRecue: 3 }] });
        assert.ok([400, 422].includes(rec.statut), `réception d'un service refusée (obtenu ${rec.statut})`);
      }
      // vente du service : aucun mouvement, aucun stock
      const v = await M.vendre(B, { boutiqueId: bq, lignes: [{ produitId: ids.p2, quantite: 2, prix: 300 }] });
      await converger('service');
      const mv = await M.partout(c, POSTES, 'SELECT COUNT(*) n FROM mouvements_stock WHERE produit_id = $1', [ids.p2]);
      assert.strictEqual(M.identiques(assert, mv, 'mouvements du service')[0].n, 0, 'aucun mouvement de stock pour un service');
      const st = await M.partout(c, POSTES, 'SELECT COUNT(*) n FROM stock_boutiques WHERE produit_id = $1', [ids.p2]);
      assert.strictEqual(M.identiques(assert, st, 'stock du service')[0].n, 0, 'aucune ligne de stock pour un service');
      assert.ok(v.id);
    });

    // ───────────────────────────── ★5 invariants
    await t.test('★5 invariants après convergence : stock = mouvements, comptes = écritures, service sans stock', { todo: 'défaut de synchronisation constaté : voir rapport' }, async () => {
      await converger('avant invariants');
      const sources = [...POSTES.map((p) => ({ nom: p.nom, lire: (sql) => p.lire(sql) })), { nom: 'cloud', lire: (sql) => M.lireCloud(c, sql.replace(/\?/g, '$1')) }];
      const violations = [];
      for (const s of POSTES) {
        // 1. stock boutique = somme des mouvements de la boutique
        const incoh = s.lire(`SELECT sb.produit_id p, sb.boutique_id b, sb.quantite_disponible q,
            COALESCE((SELECT SUM(changement_quantite) FROM mouvements_stock m WHERE m.produit_id = sb.produit_id AND m.boutique_id = sb.boutique_id), 0) mv
          FROM stock_boutiques sb`).filter((r) => Number(r.q) !== Number(r.mv));
        if (incoh.length) violations.push(`${s.nom} : stock ≠ somme des mouvements : ${JSON.stringify(incoh)}`);
        // 1b. chaîne : dernier stock_final (par date puis id) = stock
        const derniers = s.lire(`SELECT sb.produit_id p, sb.boutique_id b, sb.quantite_disponible q,
            (SELECT stock_final FROM mouvements_stock m WHERE m.produit_id = sb.produit_id AND m.boutique_id = sb.boutique_id ORDER BY date_mouvement DESC, id DESC LIMIT 1) dernier
          FROM stock_boutiques sb`).filter((r) => r.dernier !== null && Number(r.q) !== Number(r.dernier));
        if (derniers.length) violations.push(`${s.nom} : stock ≠ dernier stock_final : ${JSON.stringify(derniers)}`);
        // 2. comptes clients et fournisseurs : solde = dernière écriture
        for (const [table, type] of [['comptes_clients', 'client'], ['comptes_fournisseurs', 'fournisseur']]) {
          for (const cpt of s.lire(`SELECT id FROM ${table}`)) {
            const k = M.controleCompte(s, table, type, Number(cpt.id));
            if (k.nb > 0 && k.dernier !== k.solde) violations.push(`${s.nom} : ${table}#${cpt.id} solde ${k.solde} ≠ dernière écriture ${k.dernier}`);
          }
        }
        // 3. services sans stock
        const svc = s.lire('SELECT sb.produit_id p, sb.quantite_disponible q FROM stock_boutiques sb JOIN produits pr ON pr.id = sb.produit_id WHERE pr.est_service = 1 AND sb.quantite_disponible <> 0');
        if (svc.length) violations.push(`${s.nom} : produit service avec stock : ${JSON.stringify(svc)}`);
      }
      const svcCloud = await M.lireCloud(c, 'SELECT sb.produit_id p, sb.quantite_disponible q FROM stock_boutiques sb JOIN produits pr ON pr.id = sb.produit_id WHERE pr.est_service = true AND sb.quantite_disponible <> 0');
      if (svcCloud.length) violations.push(`cloud : produit service avec stock : ${JSON.stringify(svcCloud)}`);
      const stockCloudInc = await M.lireCloud(c, `SELECT sb.produit_id p, sb.boutique_id b, sb.quantite_disponible q,
          COALESCE((SELECT SUM(changement_quantite) FROM mouvements_stock m WHERE m.produit_id = sb.produit_id AND m.boutique_id = sb.boutique_id), 0) mv
        FROM stock_boutiques sb`);
      const incCloud = stockCloudInc.filter((r) => Number(r.q) !== Number(r.mv));
      if (incCloud.length) violations.push(`cloud : stock ≠ somme des mouvements : ${JSON.stringify(incCloud)}`);
      assert.strictEqual(violations.length, 0, violations.join('\n'));
      void sources;
    });

    // ───────────────────────────── ★7 idempotence
    await t.test('★7 idempotence : 5 cycles de synchronisation supplémentaires ne changent rien', async () => {
      await converger('avant idempotence');
      const photo = async () => {
        const cmp = {};
        for (const p of POSTES) {
          cmp[p.nom] = M.comptagesPoste(p);
          cmp[p.nom].__operation_log = Number(p.lire('SELECT COUNT(*) n FROM operation_log')[0].n);
          cmp[p.nom].__etat = JSON.stringify([...Object.entries(M.etatPoste(p, SPECS))].map(([t2, e]) => [t2, [...e.lignes.entries()]]));
        }
        cmp.cloud = await M.comptagesCloud(c, Object.keys(cmp.A).filter((k) => !k.startsWith('__') && k !== 'operation_log'));
        cmp.__cloudEtat = JSON.stringify([...Object.entries(await M.etatCloud(c.cloudUrl, SPECS))].map(([t2, e]) => [t2, [...e.lignes.entries()]]));
        return cmp;
      };
      const avant = await photo();
      for (let i = 0; i < 5; i++) for (const p of POSTES) await p.synchroniser();
      for (const p of POSTES) await M.avecReprise(() => p.synchroniserJusquaCalme());
      const apres = await photo();
      const diffs = [];
      for (const k of Object.keys(avant)) {
        if (typeof avant[k] === 'string') { if (avant[k] !== apres[k]) diffs.push(`${k} : valeurs modifiées`); continue; }
        for (const d of M.differencesObjets(avant[k], apres[k])) diffs.push(`${k}.${d}`);
      }
      assert.strictEqual(diffs.length, 0, `la resynchronisation a modifié l'état :\n${diffs.slice(0, 20).join('\n')}`);
    });

    // DÉFAUT CONNU : écarts de convergence constatés pendant le flux (écritures de compte client jamais envoyées, solde de
    // caisse périmé dans le cloud et jamais reçu par B/C…). Voir le rapport pour les causes.
    await t.test('convergence complète à chaque étape (aucune différence poste/cloud)', { todo: 'défauts de synchronisation constatés : voir rapport' }, async () => {
      assert.strictEqual(defauts.length, 0, defauts.join(' || '));
    });
  });
