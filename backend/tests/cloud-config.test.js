/**
 * Saisie du lien Neon dans l'application : validation stricte, test de connexion, écriture sûre du .env.
 *
 * Exécution :  node --test tests/cloud-config.test.js
 */
const test = require('node:test');
const assert = require('node:assert');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');

const cc = require('../src/services/cloud-config');

const URL_OK = 'postgresql://neondb_owner:MotDePasseSecret123@ep-exemple-pooler.c-3.eu-central-1.aws.neon.tech/neondb?sslmode=require&channel_binding=require';
const dossier = () => fs.mkdtempSync(path.join(os.tmpdir(), 'cloudcfg-'));

// ── Validation ───────────────────────────────────────────────────────────────────────────────────────

test('un lien Neon valide est accepté ; on n\'en extrait que l\'hôte, la base et l\'utilisateur', () => {
  const v = cc.valider(URL_OK);
  assert.strictEqual(v.ok, true);
  assert.deepStrictEqual(v.info, { hote: 'ep-exemple-pooler.c-3.eu-central-1.aws.neon.tech', base: 'neondb', utilisateur: 'neondb_owner' });
  assert.ok(!JSON.stringify(v).includes('MotDePasseSecret123'), 'le mot de passe ne ressort jamais');
});

test('liens refusés, avec un message clair', () => {
  const cas = [
    ['', /Collez le lien/],
    [null, /Collez le lien/],
    ['https://neon.tech/neondb', /commencer par postgresql/],
    ['postgresql://utilisateur@hote/base', /mot de passe/],
    ['postgresql://:motdepasse@hote/base', /nom d'utilisateur/],
    ['postgresql://u:p@hote', /nom de la base/],
    ['postgresql://u:p@/base', /pas valide|adresse/],
  ];
  for (const [lien, motif] of cas) {
    const v = cc.valider(lien);
    assert.strictEqual(v.ok, false, `refusé : ${lien}`);
    assert.match(v.erreur, motif, `message de « ${lien} »`);
  }
});

test('INJECTION dans le .env : un retour à la ligne, une espace ou un guillemet dans le lien est refusé', () => {
  const pieges = [
    URL_OK + '\nJWT_SECRET=pirate',
    URL_OK + '\r\nNODE_ENV=development',
    URL_OK + ' AUTRE=1',
    URL_OK + '"\nPORT=1',
    URL_OK.replace('neondb?', "neondb'?"),
    URL_OK + '`',
    URL_OK + '\\',
  ];
  for (const p of pieges) assert.strictEqual(cc.valider(p).ok, false, `refusé : ${JSON.stringify(p).slice(-30)}`);
});

// ── Écriture du .env ─────────────────────────────────────────────────────────────────────────────────

test('enregistrement : la ligne est ajoutée, les autres variables sont conservées, le fichier est entre guillemets', () => {
  const fichier = path.join(dossier(), '.env');
  fs.writeFileSync(fichier, 'NODE_ENV=production\nPORT=8080\nJWT_SECRET=secret-a-garder\n');
  const info = cc.enregistrer(URL_OK, fichier);
  assert.strictEqual(info.base, 'neondb');
  const contenu = fs.readFileSync(fichier, 'utf8');
  assert.match(contenu, /^NODE_ENV=production$/m);
  assert.match(contenu, /^JWT_SECRET=secret-a-garder$/m);
  assert.match(contenu, new RegExp(`^CLOUD_DB_URL="${URL_OK.replace(/[?&.]/g, '\\$&')}"$`, 'm'));
  assert.strictEqual(cc.lireDansFichier(fichier), URL_OK, 'relue sans les guillemets');
});

test('enregistrement : une ligne CLOUD_DB_URL existante est REMPLACÉE (pas dupliquée), une copie de sécurité est gardée', () => {
  const fichier = path.join(dossier(), '.env');
  fs.writeFileSync(fichier, 'PORT=8080\n# commentaire\nCLOUD_DB_URL="postgresql://a:ancien@vieux/base"\nLOG_LEVEL=info\n');
  cc.enregistrer(URL_OK, fichier);
  const contenu = fs.readFileSync(fichier, 'utf8');
  assert.strictEqual((contenu.match(/CLOUD_DB_URL/g) || []).length, 1, 'une seule ligne');
  assert.match(contenu, /# commentaire/);
  assert.match(contenu, /LOG_LEVEL=info/);
  assert.ok(!contenu.includes('ancien'), "l'ancien mot de passe a disparu du fichier");
  assert.ok(fs.existsSync(fichier + '.avant-cloud'), "copie de l'ancien fichier");
});

test('enregistrement dans un fichier absent : il est créé ; un lien invalide ne touche à rien', () => {
  const d = dossier();
  const fichier = path.join(d, 'sous', '.env');
  cc.enregistrer(URL_OK, fichier);
  assert.strictEqual(cc.lireDansFichier(fichier), URL_OK);
  const avant = fs.readFileSync(fichier, 'utf8');
  assert.throws(() => cc.enregistrer('pasunlien', fichier), /postgresql/);
  assert.throws(() => cc.enregistrer(URL_OK + '\nX=1', fichier), /espaces|retour/);
  assert.strictEqual(fs.readFileSync(fichier, 'utf8'), avant, 'fichier inchangé');
});

// ── État de la configuration ─────────────────────────────────────────────────────────────────────────

test('état : jamais le mot de passe ; redémarrage nécessaire quand le fichier diffère du serveur en marche', () => {
  const fichier = path.join(dossier(), '.env');
  const avant = process.env.CLOUD_DB_URL;
  try {
    delete process.env.CLOUD_DB_URL;
    let c = cc.lireConfiguration(fichier);
    assert.deepStrictEqual([c.active, c.enregistree, c.redemarrageNecessaire], [false, false, false], '100 % local, rien d\'enregistré');

    cc.enregistrer(URL_OK, fichier);
    c = cc.lireConfiguration(fichier);
    assert.deepStrictEqual([c.active, c.enregistree, c.redemarrageNecessaire], [false, true, true], 'enregistré mais pas encore appliqué');
    assert.ok(!JSON.stringify(c).includes('MotDePasseSecret123'), 'aucun mot de passe dans la réponse');

    process.env.CLOUD_DB_URL = URL_OK; // le serveur a redémarré avec ce lien
    c = cc.lireConfiguration(fichier);
    assert.deepStrictEqual([c.active, c.enregistree, c.redemarrageNecessaire], [true, true, false]);
  } finally {
    if (avant === undefined) delete process.env.CLOUD_DB_URL; else process.env.CLOUD_DB_URL = avant;
  }
});

// ── Test de connexion (faux client) ──────────────────────────────────────────────────────────────────

function fauxClient({ tables = cc.TABLES_SCHEMA, erreurConnexion = null, comptes = { produits: 12, clients: 3, ventes: 40 } } = {}) {
  return {
    ferme: false,
    async connect() { if (erreurConnexion) throw erreurConnexion; },
    async query(sql) {
      if (/information_schema/.test(sql)) return { rows: tables.map((t) => ({ table_name: t })) };
      const m = sql.match(/FROM "(\w+)"/);
      return { rows: [{ n: comptes[m[1]] }] };
    },
    async end() { this.ferme = true; },
  };
}

test('connexion réussie et base prête : on dit si le cloud contient déjà des données', async () => {
  const f = fauxClient();
  const r = await cc.tester(URL_OK, { creerClient: () => f });
  assert.strictEqual(r.ok, true);
  assert.strictEqual(r.schemaPret, true);
  assert.deepStrictEqual(r.donnees, { produits: 12, clients: 3, ventes: 40 });
  assert.strictEqual(f.ferme, true, 'connexion refermée');
  assert.ok(!JSON.stringify(r).includes('MotDePasseSecret123'));
});

test('base vide (sans les tables de LOGESCO) : connexion ok mais schéma absent, avec la liste des tables manquantes', async () => {
  const r = await cc.tester(URL_OK, { creerClient: () => fauxClient({ tables: ['produits'] }) });
  assert.strictEqual(r.ok, true);
  assert.strictEqual(r.schemaPret, false);
  assert.deepStrictEqual(r.tablesManquantes, ['ventes', 'clients', 'user_roles', 'boutiques']);
  assert.match(r.message, /pas encore les tables/);
});

test('échecs de connexion expliqués en clair, sans jamais montrer le mot de passe', async () => {
  const cas = [
    [Object.assign(new Error('getaddrinfo ENOTFOUND ep-x'), { code: 'ENOTFOUND' }), /adresse du serveur est introuvable/],
    [Object.assign(new Error('timeout'), { code: 'ETIMEDOUT' }), /ne répond pas à temps/],
    [new Error('password authentication failed for user "neondb_owner"'), /mot de passe .* refusé/],
    [new Error('database "x" does not exist'), /base de données n'existe pas/],
    [new Error('quelque chose d\'inattendu avec MotDePasseSecret123'), /Connexion impossible/],
  ];
  for (const [erreur, motif] of cas) {
    const r = await cc.tester(URL_OK, { creerClient: () => fauxClient({ erreurConnexion: erreur }) });
    assert.strictEqual(r.ok, false);
    assert.match(r.message, motif);
    assert.ok(!JSON.stringify(r).includes('MotDePasseSecret123'), "le message d'erreur du pilote n'est jamais recopié");
  }
});

test('un lien invalide est refusé avant toute connexion', async () => {
  let connecte = false;
  const r = await cc.tester('postgresql://u:p@hote/base\nX=1', { creerClient: () => { connecte = true; return fauxClient(); } });
  assert.strictEqual(r.ok, false);
  assert.strictEqual(connecte, false);
});
