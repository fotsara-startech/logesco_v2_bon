/**
 * Saisie du lien Neon depuis l'application (routes /sync/cloud-config) sur un poste 100 % local.
 *
 *   SYNC_TEST_NEON_URL='postgresql://…' node --experimental-sqlite --test tests/e2e-sync/scenarios/50-cloud-config.test.js
 *
 * Vérifie, sur un vrai poste : l'état avant, le test d'un lien (bon, mauvais mot de passe, base inexistante, lien piégé),
 * l'enregistrement dans le .env, et surtout que le MOT DE PASSE n'apparaît ni dans une réponse ni dans le journal du poste.
 */
const test = require('node:test');
const assert = require('node:assert');
const fs = require('node:fs');
const path = require('node:path');
const { nouvelleCampagne, peutLancer } = require('../harness/campagne');
const aide = require('../harness/aide-horsligne');

const lancement = peutLancer();
const skip = lancement.ok ? false : lancement.raison;

/** Le mot de passe d'une URL (jamais affiché) */
const motDePasse = (url) => decodeURIComponent(new URL(url).password);

test('50. poste 100 % local : lien Neon testé puis enregistré depuis l\'application, sans jamais exposer le mot de passe', { skip, timeout: 600000 }, async (t) => {
  const c = await nouvelleCampagne({ etiquette: 'cfgcloud', postes: [{ nom: 'L', cloud: false, preload: [aide.PRELOAD_SANS_CLOUD] }] });
  t.after(() => c.terminer());
  const { L } = c.postes;
  const lienBon = c.cloud.url; // base jetable synctest_* : le schéma LOGESCO y est
  const secret = motDePasse(lienBon);
  const jamaisLeSecret = (x, ou) => assert.ok(!JSON.stringify(x).includes(secret), `le mot de passe apparaît dans ${ou}`);

  await t.test('avant : mode 100 % local, rien d\'enregistré', async () => {
    const r = await L.api('GET', '/sync/cloud-config');
    assert.strictEqual(r.statut, 200, JSON.stringify(r.corps).slice(0, 200));
    const d = r.corps.data;
    assert.deepStrictEqual([d.active, d.enregistree, d.redemarrageNecessaire], [false, false, false]);
    jamaisLeSecret(r.corps, 'GET /sync/cloud-config');
  });

  await t.test('un bon lien : connexion réussie, base prête, cloud vide', async () => {
    const r = await L.api('POST', '/sync/cloud-config/test', { url: lienBon }, { delaiMs: 60000 });
    assert.strictEqual(r.statut, 200, JSON.stringify(r.corps).slice(0, 300));
    const d = r.corps.data;
    assert.strictEqual(d.ok, true, d.message);
    assert.strictEqual(d.schemaPret, true, `tables manquantes : ${d.tablesManquantes}`);
    assert.deepStrictEqual(d.donnees, { produits: 0, clients: 0, ventes: 0 });
    jamaisLeSecret(r.corps, 'POST /sync/cloud-config/test');
  });

  await t.test('un mauvais mot de passe : refusé avec un message clair, sans recopier le mot de passe', async () => {
    const u = new URL(lienBon);
    u.password = 'mauvais-mot-de-passe-xyz';
    const r = await L.api('POST', '/sync/cloud-config/test', { url: u.toString() }, { delaiMs: 60000 });
    const d = r.corps.data;
    assert.strictEqual(d.ok, false);
    assert.match(d.message, /mot de passe|Connexion impossible|répond pas/i);
    assert.ok(!JSON.stringify(r.corps).includes('mauvais-mot-de-passe-xyz'), 'le mauvais mot de passe saisi n\'est pas renvoyé');
  });

  await t.test('un lien piégé (retour à la ligne + autre variable) est refusé AVANT toute connexion', async () => {
    const r = await L.api('POST', '/sync/cloud-config/test', { url: `${lienBon}\nJWT_SECRET=pirate` });
    assert.strictEqual(r.corps.data.ok, false);
    assert.match(r.corps.data.message, /espaces|retour à la ligne/);
  });

  await t.test('enregistrer un lien piégé ou faux est refusé et ne crée aucun fichier', async () => {
    const piege = await L.api('POST', '/sync/cloud-config', { url: `${lienBon}\nJWT_SECRET=pirate` });
    assert.strictEqual(piege.statut, 400);
    const faux = await L.api('POST', '/sync/cloud-config', { url: 'pas-un-lien' });
    assert.strictEqual(faux.statut, 400);
    assert.ok(!fs.existsSync(path.join(L.dossier, '.env')), 'aucun .env écrit');
  });

  await t.test('enregistrer le bon lien : écrit dans le .env, redémarrage nécessaire, mot de passe jamais renvoyé', async () => {
    const r = await L.api('POST', '/sync/cloud-config', { url: lienBon }, { delaiMs: 60000 });
    assert.strictEqual(r.statut, 200, JSON.stringify(r.corps).slice(0, 300));
    jamaisLeSecret(r.corps, 'POST /sync/cloud-config');
    const d = r.corps.data;
    assert.strictEqual(d.enregistree, true);
    assert.strictEqual(d.active, false, 'pas appliqué à chaud : le serveur tourne toujours en 100 % local');
    assert.strictEqual(d.redemarrageNecessaire, true);

    const fichier = path.join(L.dossier, '.env');
    assert.ok(fs.existsSync(fichier), `.env écrit dans ${fichier}`);
    assert.match(fs.readFileSync(fichier, 'utf8'), /^CLOUD_DB_URL="postgres(ql)?:\/\//m, 'la ligne est dans le .env');

    const etat = await L.api('GET', '/sync/cloud-config');
    assert.strictEqual(etat.corps.data.redemarrageNecessaire, true);
    jamaisLeSecret(etat.corps, 'GET /sync/cloud-config après enregistrement');
  });

  await t.test('le mot de passe n\'est écrit nulle part dans le journal du poste', async () => {
    const journal = L.journal(200000);
    assert.ok(!journal.includes(secret), 'le mot de passe apparaît dans le journal du poste');
    assert.match(journal, /Lien du cloud enregistré \(hôte /, 'l\'enregistrement est tracé (hôte et base seulement)');
  });
});
