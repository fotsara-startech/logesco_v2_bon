/**
 * Qualité du CONTRÔLE D'ÉCART (GET /sync/drift?refresh=1, POST /sync/drift/resend, POST /sync/drift/ignore).
 *
 * Après convergence : aucun écart inexpliqué. Puis on INJECTE des divergences directement dans le cloud ou dans la base
 * locale (sans passer par l'application) et on vérifie qu'elles sont détectées ET traitées :
 *   a) ligne supprimée dans le cloud, encore présente sur le poste  → « à envoyer » → renvoi (dryRun puis réel) ;
 *   a2) idem sur une table que le renvoi ne gère pas (produits)       → détectée, mais aucun traitement automatique ;
 *   b) ligne supprimée sur le poste, présente dans le cloud           → « à recevoir » → rattrapage automatique ;
 *   c) stock modifié directement dans le cloud                         → « valeur différente » ;
 *   d) « ignorer » un écart puis le restaurer.
 * Et : pas de faux positif pendant qu'une écriture locale est en attente d'envoi.
 *
 *   SYNC_TEST_NEON_URL='postgresql://…' node --experimental-sqlite --test tests/e2e-sync/scenarios/40-metier-ecart.test.js
 */
const test = require('node:test');
const assert = require('node:assert');
const { DatabaseSync } = require('node:sqlite');
const { nouvelleCampagne, peutLancer } = require('../harness/campagne');
const { SPECS_PAR_DEFAUT, attendreConvergence, decrire } = require('../harness/oracle');
const { pause } = require('../harness/station');
const M = require('../harness/aide-metier');

const lancement = peutLancer();
const skip = lancement.ok ? false : lancement.raison;

/** Écriture directe dans la base SQLite d'un poste EN MARCHE (hors application : aucune trace de synchro) */
function ecrireLocal(poste, sql, ...params) {
  const db = new DatabaseSync(poste.fichierDb);
  try { db.exec('PRAGMA busy_timeout = 8000'); return db.prepare(sql).run(...params); } finally { db.close(); }
}

const drift = async (poste) => (await poste.api('GET', '/sync/drift?refresh=1', undefined, { delaiMs: 120000 })).corps.data;
const ecartsDe = (d, table, sens) => (d.rapport ? d.rapport.ecarts : []).filter((e) => e.table === table && (!sens || e.sens === sens));
const resume = (d) => (d.rapport ? JSON.stringify(d.rapport.resume) : 'pas de rapport');

test('contrôle d\'écart : aucun écart inexpliqué, détection et traitement des divergences injectées',
  { skip, timeout: 3000000 }, async (t) => {
    const c = await nouvelleCampagne({ etiquette: 'metier', postes: ['A', 'B'] });
    t.after(() => c.terminer());
    const { A, B } = c.postes;
    const POSTES = [A, B];
    const defauts = [];
    const converger = async (quoi) => {
      const r = await M.avecReprise(() => attendreConvergence({ stations: POSTES, cloudUrl: c.cloudUrl, specs: SPECS_PAR_DEFAUT, delaiMs: 90000 }));
      if (!r.ok) defauts.push(`(${quoi}) ${decrire(r.differences)}`);
      return r;
    };
    const bq = Number(A.lire('SELECT id FROM boutiques WHERE est_principale = 1')[0].id);
    const ids = {};

    await t.test('préparation : 4 produits dont 3 avec du stock, vente, client', async () => {
      for (const [k, ref] of [['p1', 'ECA-1'], ['p2', 'ECA-2'], ['p3', 'ECA-3'], ['p4', 'ECA-4']]) ids[k] = await M.creerProduit(A, { reference: ref, nom: `Produit ${ref}` });
      await M.approvisionner(A, ids.p1, bq, 50);
      await M.approvisionner(A, ids.p2, bq, 40);
      await M.approvisionner(A, ids.p3, bq, 30);
      await M.vendre(A, { boutiqueId: bq, lignes: [{ produitId: ids.p1, quantite: 2, prix: 1500 }] });
      await converger('préparation');
      // Constat : la création d'un produit crée des lignes « stock » (global) que la synchro n'envoie pas ? (le contrôle le dit)
      const avant = await drift(A);
      t.diagnostic(`contrôle juste après la préparation : ${avant.rapport ? JSON.stringify(avant.rapport.ecarts.filter((e) => !e.connue).map((e) => [e.table, e.sens, e.cause, e.nombre])) : 'pas de rapport'}`);
      const re = await A.api('POST', '/sync/drift/resend', { dryRun: false });
      t.diagnostic(`renvoi initial : ${JSON.stringify(re.corps.data && { envoyes: re.corps.data.envoyes, refuses: re.corps.data.refuses })}`);
      await converger('après renvoi initial');
    });

    await t.test('★6 état sain : aucun écart inexpliqué sur A ni sur B après convergence', async () => {
      for (const p of POSTES) {
        const d = await drift(p);
        assert.strictEqual(d.actif, true, 'cloud actif');
        assert.ok(d.rapport, `${p.nom} : pas de rapport (${d.erreur})`);
        assert.strictEqual(d.rapport.resume.inexpliques, 0, `${p.nom} : écarts inexpliqués sur un système sain : ${JSON.stringify(d.rapport.ecarts.map((e) => [e.table, e.sens, e.cause, e.nombre]))}`);
        assert.strictEqual(d.rapport.ecarts.filter((e) => !e.connue).length, 0);
      }
    });

    await t.test('pas de faux positif pendant qu\'une écriture locale est en attente', async () => {
      const fauxPositifs = [];
      let vuEnAttente = 0;
      for (let i = 0; i < 4; i++) {
        await M.creerProduit(A, { reference: `ECA-ATT${i}`, nom: `En attente ${i}` });
        await M.vendre(A, { boutiqueId: bq, lignes: [{ produitId: ids.p2, quantite: 1, prix: 1500 }] });
        const d = await drift(A);
        if (!d.rapport) { fauxPositifs.push('pas de rapport'); continue; }
        if (d.rapport.resume.connus > 0) vuEnAttente++;
        if (d.rapport.resume.inexpliques > 0) fauxPositifs.push(`passe ${i} : ${JSON.stringify(d.rapport.ecarts.filter((e) => !e.connue).map((e) => [e.table, e.sens, e.cause, e.nombre]))}`);
      }
      assert.strictEqual(fauxPositifs.length, 0, `faux positifs : ${fauxPositifs.join(' | ')}`);
      t.diagnostic(`écarts « connus » (envoi en attente) observés sur ${vuEnAttente}/4 contrôles`);
      await converger('après écritures en attente');
      const apres = await drift(A);
      assert.strictEqual(apres.rapport.resume.inexpliques, 0);
    });

    await t.test('a) ligne supprimée dans le cloud (le poste la possède encore) → à envoyer → renvoi dryRun puis réel', async () => {
      const cible = (await M.lireCloud(c, 'SELECT id, quantite_disponible q FROM stock_boutiques WHERE produit_id = $1 AND boutique_id = $2', [ids.p3, bq]))[0];
      assert.ok(cible, 'ligne de stock P3 présente dans le cloud');
      await M.lireCloud(c, 'DELETE FROM stock_boutiques WHERE id = $1', [cible.id]);
      await pause(4000);
      const d = await drift(A);
      t.diagnostic(`a) operation_log de la ligne ${cible.id} : ${JSON.stringify(A.lire("SELECT operation_type, status, substr(coalesce(error_message,''),1,200) e FROM operation_log WHERE table_name = 'stock_boutiques' AND record_id = ?", cible.id))} ; écarts : ${JSON.stringify(d.rapport.ecarts.map((x) => [x.table, x.sens, x.cause, x.nombre]))}`);
      const e = ecartsDe(d, 'stock_boutiques', 'a_envoyer');
      assert.ok(e.length === 1, `écart « à envoyer » stock_boutiques attendu : ${resume(d)} ${JSON.stringify(d.rapport.ecarts.map((x) => [x.table, x.sens, x.cause, x.nombre]))}`);
      assert.strictEqual(e[0].cause, 'inconnue');
      assert.ok(e[0].ids.some((x) => Number(x.id) === Number(cible.id)));
      assert.ok(e[0].renvoi && e[0].renvoi.envoyables === 1, `le rapport indique que le renvoi est possible : ${JSON.stringify(e[0].renvoi)}`);
      assert.ok(d.rapport.resume.inexpliques >= 1);

      // aperçu : rien n'est envoyé
      const ap = await A.api('POST', '/sync/drift/resend', { dryRun: true });
      assert.strictEqual(ap.statut, 200, JSON.stringify(ap.corps).slice(0, 300));
      assert.strictEqual(ap.corps.data.dryRun, true);
      assert.strictEqual(ap.corps.data.envoyes, 0);
      assert.ok(ap.corps.data.aEnvoyer >= 1);
      assert.strictEqual((await M.lireCloud(c, 'SELECT 1 FROM stock_boutiques WHERE id = $1', [cible.id])).length, 0, 'dryRun n\'a rien écrit dans le cloud');

      // réel
      const re = await A.api('POST', '/sync/drift/resend', { dryRun: false });
      assert.strictEqual(re.statut, 200, JSON.stringify(re.corps).slice(0, 300));
      assert.ok(re.corps.data.envoyes >= 1, `renvoi réel : ${JSON.stringify(re.corps.data).slice(0, 300)}`);
      await converger('après renvoi');
      const rec = await M.lireCloud(c, 'SELECT quantite_disponible q FROM stock_boutiques WHERE id = $1', [cible.id]);
      assert.strictEqual(rec.length, 1, 'ligne restaurée dans le cloud');
      assert.strictEqual(Number(rec[0].q), Number(cible.q), 'avec la bonne quantité');
      for (const p of POSTES) assert.strictEqual((await drift(p)).rapport.resume.inexpliques, 0, `${p.nom} : plus d'écart après renvoi`);
    });

    await t.test('a2) ligne « produits » supprimée dans le cloud : détectée, mais le renvoi automatique ne la couvre pas', { todo: 'DÉFAUT CONNU : TABLES_RENVOI (sync-resend.js) ne couvre que stock, stock_boutiques, mouvements_stock, historique_prix_achat' }, async () => {
      await M.lireCloud(c, 'DELETE FROM stock_boutiques WHERE produit_id = $1', [ids.p4]);
      await M.lireCloud(c, 'DELETE FROM stock WHERE produit_id = $1', [ids.p4]);
      await M.lireCloud(c, 'DELETE FROM produits WHERE id = $1', [ids.p4]);
      await pause(3000);
      const d = await drift(A);
      const e = ecartsDe(d, 'produits', 'a_envoyer');
      assert.strictEqual(e.length, 1, `écart « à envoyer » produits attendu : ${resume(d)}`);
      const re = await A.api('POST', '/sync/drift/resend', { dryRun: false });
      assert.strictEqual(re.statut, 200);
      const apres = await M.lireCloud(c, 'SELECT 1 FROM produits WHERE id = $1', [ids.p4]);
      // DÉFAUT/LIMITE : seules 4 tables sont renvoyables (sync-resend.js TABLES_RENVOI). Une fiche produit perdue dans le
      // cloud reste signalée sans remède proposé ; seule une modification du produit sur le poste la renverrait.
      t.diagnostic(`renvoi d'un produit absent du cloud : ${apres.length ? 'rétabli' : 'NON rétabli (hors TABLES_RENVOI)'}`);
      assert.strictEqual(apres.length, 1, 'le produit supprimé du cloud devrait pouvoir être renvoyé depuis le contrôle d\'écart');
    });

    await t.test('d) ignorer un écart de présence puis le restaurer', async () => {
      // un écart de présence qui subsiste : le produit p4 (si a2 ne l'a pas rétabli) sinon on en crée un
      let d = await drift(A);
      let ec = ecartsDe(d, 'produits', 'a_envoyer');
      if (ec.length === 0) {
        const id = await M.creerProduit(A, { reference: 'ECA-IGN', nom: 'À ignorer' });
        await converger('produit à ignorer');
        await M.lireCloud(c, 'DELETE FROM stock_boutiques WHERE produit_id = $1', [id]);
        await M.lireCloud(c, 'DELETE FROM stock WHERE produit_id = $1', [id]);
        await M.lireCloud(c, 'DELETE FROM produits WHERE id = $1', [id]);
        await pause(3000);
        d = await drift(A);
        ec = ecartsDe(d, 'produits', 'a_envoyer');
      }
      assert.strictEqual(ec.length, 1, `écart de présence à ignorer : ${resume(d)}`);
      const avant = d.rapport.resume.inexpliques;
      assert.ok(avant >= 1);
      const item = { table: 'produits', id: Number(ec[0].ids[0].id), sens: 'a_envoyer' };
      const ig = await A.api('POST', '/sync/drift/ignore', { items: [item], note: 'test' });
      assert.strictEqual(ig.statut, 200, JSON.stringify(ig.corps).slice(0, 300));
      assert.strictEqual(ig.corps.data.rapport.resume.inexpliques, avant - 1, 'l\'écart ignoré n\'est plus compté comme inexpliqué');
      assert.strictEqual(ig.corps.data.rapport.resume.ignores, 1, 'il est compté à part');
      const res = await A.api('POST', '/sync/drift/ignore', { restaurer: true });
      assert.strictEqual(res.statut, 200);
      assert.strictEqual(res.corps.data.rapport.resume.inexpliques, avant, 'restauré : de nouveau signalé');
      assert.strictEqual(res.corps.data.rapport.resume.ignores, 0);
      // une valeur ne s'ignore pas
      const refus = await A.api('POST', '/sync/drift/ignore', { items: [{ table: 'stock_boutiques', id: 1, sens: 'valeur' }] });
      assert.ok(refus.statut === 400 || refus.corps.data.nombre === 0, 'un écart de valeur ne peut pas être ignoré');
      // un poste non administrateur ne peut pas ignorer : non testé (le jeton de test est l'administrateur)
    });

    await t.test('b) ligne supprimée sur le poste (le cloud la possède) → à recevoir → rattrapage automatique', async () => {
      // on nettoie l'écart « produits » restant pour isoler le test
      await A.api('POST', '/sync/drift/ignore', { restaurer: true });
      const cible = B.lire('SELECT id, quantite_disponible q FROM stock_boutiques WHERE produit_id = ? AND boutique_id = ?', ids.p2, bq)[0];
      assert.ok(cible);
      ecrireLocal(B, 'DELETE FROM stock_boutiques WHERE id = ?', cible.id);
      assert.strictEqual(B.lire('SELECT 1 FROM stock_boutiques WHERE id = ?', cible.id).length, 0, 'supprimée localement');
      const d = await drift(B);
      // après le contrôle, le rattrapage doit avoir récupéré la ligne
      await pause(6000);
      t.diagnostic(`b) écarts après contrôle : ${JSON.stringify(d.rapport.ecarts.map((x) => [x.table, x.sens, x.cause, x.nombre]))}`);
      const retour = B.lire('SELECT quantite_disponible q FROM stock_boutiques WHERE id = ?', cible.id);
      t.diagnostic(`rapport après rattrapage : ${resume(d)} ; récupérés=${d.rapport && d.rapport.recuperes}`);
      assert.strictEqual(retour.length, 1, 'la ligne jamais reçue est récupérée automatiquement du cloud');
      assert.strictEqual(Number(retour[0].q), Number(cible.q));
      assert.ok(d.rapport.recuperes >= 1, 'le rapport signale ce qui a été récupéré');
    });

    await t.test('c) stock modifié directement dans le cloud → écart « valeur différente »', async () => {
      const cible = (await M.lireCloud(c, 'SELECT id, quantite_disponible q FROM stock_boutiques WHERE produit_id = $1 AND boutique_id = $2', [ids.p1, bq]))[0];
      // On neutralise le déclencheur de date de modification pour que la valeur reste différente (sinon le poste la reçoit
      // normalement au prochain cycle, ce qui est le comportement attendu et vérifié plus bas).
      await M.lireCloud(c, 'ALTER TABLE stock_boutiques DISABLE TRIGGER USER');
      await M.lireCloud(c, 'UPDATE stock_boutiques SET quantite_disponible = 777 WHERE id = $1', [cible.id]);
      await M.lireCloud(c, 'ALTER TABLE stock_boutiques ENABLE TRIGGER USER');
      await pause(4000);
      for (const p of POSTES) {
        const d = await drift(p);
        const e = ecartsDe(d, 'stock_boutiques', 'valeur');
        assert.strictEqual(e.length, 1, `${p.nom} : écart de valeur attendu : ${resume(d)}`);
        assert.strictEqual(e[0].connue, false);
        assert.ok(e[0].exemples.some((x) => Number(x.cloud) === 777 && Number(x.local) === Number(cible.q)), `${p.nom} : valeurs locale/cloud données : ${JSON.stringify(e[0].exemples)}`);
        assert.ok(d.rapport.resume.inexpliques >= 1);
      }
      // retour à la normale
      await M.lireCloud(c, 'ALTER TABLE stock_boutiques DISABLE TRIGGER USER');
      await M.lireCloud(c, 'UPDATE stock_boutiques SET quantite_disponible = $2 WHERE id = $1', [cible.id, cible.q]);
      await M.lireCloud(c, 'ALTER TABLE stock_boutiques ENABLE TRIGGER USER');
      await pause(5000);
      for (const p of POSTES) {
        let n = -1;
        for (let k = 0; k < 3 && n !== 0; k++) { n = ecartsDe(await drift(p), 'stock_boutiques', 'valeur').length; if (n) await pause(5000); }
        t.diagnostic(`c) ${p.nom} après restauration : ${n} écart(s) de valeur ; local=${M.stockPoste(p, ids.p1, bq)} cloud=${await M.stockCloud(c, ids.p1, bq)}`);
        assert.strictEqual(n, 0, `${p.nom} : écart de valeur disparu`);
      }
    });

    await t.test('c2) modification de stock dans le cloud AVEC date de modification : reçue par les postes (le cloud fait foi)', async () => {
      const cible = (await M.lireCloud(c, 'SELECT id, quantite_disponible q FROM stock_boutiques WHERE produit_id = $1 AND boutique_id = $2', [ids.p1, bq]))[0];
      await M.lireCloud(c, 'UPDATE stock_boutiques SET quantite_disponible = 888 WHERE id = $1', [cible.id]);
      await converger('stock modifié dans le cloud');
      for (const p of POSTES) assert.strictEqual(M.stockPoste(p, ids.p1, bq), 888, `${p.nom} a reçu la valeur du cloud`);
      // Le stock (888) n'est plus égal à la somme des mouvements : le contrôle d'écart ne voit rien (les deux côtés sont d'accord)
      // → c'est le centre de décisions (cas « stock affiché différent du dernier mouvement ») qui doit le signaler.
      const dec = await A.api('GET', '/decisions');
      const cas = (dec.corps.data.cases || []).filter((x) => x.produit && x.produit.id === ids.p1);
      t.diagnostic(`centre de décisions : ${cas.length} cas pour le produit modifié (${cas.map((x) => x.raisons.map((r) => r.code)).join(',')})`);
      assert.ok(cas.length >= 1, 'une modification sans mouvement doit apparaître dans le centre de décisions');
    });

    await t.test('e) écart de valeur LOCAL (stock changé hors application sur le poste) → détecté', async () => {
      const cible = B.lire('SELECT id, quantite_disponible q FROM stock_boutiques WHERE produit_id = ? AND boutique_id = ?', ids.p2, bq)[0];
      ecrireLocal(B, 'UPDATE stock_boutiques SET quantite_disponible = quantite_disponible + 5 WHERE id = ?', cible.id);
      let d = await drift(B);
      t.diagnostic(`e) local B après modif : ${M.stockPoste(B, ids.p2, bq)} (avant ${cible.q}), cloud ${await M.stockCloud(c, ids.p2, bq)}`);
      const e = ecartsDe(d, 'stock_boutiques', 'valeur');
      assert.strictEqual(e.length, 1, `écart de valeur local attendu : ${resume(d)}`);
      assert.ok(e[0].exemples.some((x) => Number(x.local) === Number(cible.q) + 5 && Number(x.cloud) === Number(cible.q)));
    });
  });
