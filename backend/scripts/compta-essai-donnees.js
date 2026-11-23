/**
 * Essai du moteur comptable sur une COPIE des données d'une base PostgreSQL (Neon) — la base d'origine n'est jamais modifiée.
 *
 * Principe : les tables de gestion du schéma « public » sont lues (SELECT uniquement) et copiées dans un schéma temporaire
 * qui reçoit aussi les tables comptables ; l'ouverture est enregistrée à la date de la première activité, le moteur tourne,
 * puis les états et les contrôles de cohérence sont calculés. Le schéma temporaire est supprimé à la fin.
 * Le rapport n'affiche que des totaux : aucun nom de client ni de fournisseur.
 *
 * Usage (l'adresse de la base ne doit JAMAIS être écrite dans un fichier du dépôt) :
 *   COMPTA_TEST_PG_URL="postgresql://utilisateur:motdepasse@hote/base?sslmode=require" node scripts/compta-essai-donnees.js
 */
const path = require('node:path');
const { execSync } = require('node:child_process');
const { Client } = require('pg');

const brut = process.env.COMPTA_TEST_PG_URL;
if (!brut) { console.error('COMPTA_TEST_PG_URL est requis.'); process.exit(2); }
const racine = path.join(__dirname, '..');
const urlDirecte = brut.replace('-pooler', ''); // le pooler Neon garde le search_path d'une connexion à l'autre
const schema = `essai_${Date.now().toString(36)}`;
const urlPrisma = `${urlDirecte}${urlDirecte.includes('?') ? '&' : '?'}schema=${schema}&connect_timeout=60&pool_timeout=120&connection_limit=3`;

const TABLES_GESTION = [
  'utilisateurs', 'boutiques', 'categories', 'produits', 'stock', 'clients', 'comptes_clients', 'fournisseurs', 'comptes_fournisseurs',
  'ventes', 'details_ventes', 'commandes_approvisionnement', 'details_commandes_approvisionnement', 'movement_categories',
  'financial_movements', 'cash_registers', 'cash_sessions', 'cash_movements', 'transactions_comptes',
];

const fmt = (n) => new Intl.NumberFormat('fr-FR').format(Math.round(n || 0)).replace(/ | /g, ' ');

async function main() {
  // Neon se réveille parfois lentement : quelques tentatives avant d'abandonner
  let c;
  for (let essai = 1; ; essai += 1) {
    c = new Client({ connectionString: urlDirecte, ssl: { rejectUnauthorized: false }, connectionTimeoutMillis: 60000 });
    try { await c.connect(); break; } catch (e) {
      if (essai >= 4) throw e;
      console.log('Connexion impossible (' + (e.message || e.code || e) + '), nouvelle tentative...');
      await new Promise((r) => setTimeout(r, 15000));
    }
  }
  try {
    await c.query(`CREATE SCHEMA "${schema}"`);
    console.log(`Schéma temporaire : ${schema}`);

    // 1) Copie de la gestion (lecture seule sur « public »)
    const copiees = {};
    for (const t of TABLES_GESTION) {
      const existe = (await c.query("select 1 from information_schema.tables where table_schema='public' and table_name=$1", [t])).rowCount;
      if (!existe) continue;
      await c.query(`CREATE TABLE "${schema}"."${t}" (LIKE public."${t}" INCLUDING DEFAULTS)`);
      await c.query(`INSERT INTO "${schema}"."${t}" SELECT * FROM public."${t}"`);
      copiees[t] = (await c.query(`select count(*)::int n from "${schema}"."${t}"`)).rows[0].n;
    }
    // Colonne ajoutée par la phase 4 (le moteur de migration de l'application la crée sur Neon au démarrage)
    await c.query(`ALTER TABLE "${schema}".commandes_approvisionnement ADD COLUMN IF NOT EXISTS tva_recuperable BOOLEAN NOT NULL DEFAULT false`);

    // 2) Tables comptables
    await c.query(`SET search_path TO "${schema}"`);
    for (const f of ['compta-schema-pg', 'compta-schema-pg-immobilisations', 'compta-schema-pg-audit']) await c.query(require(`../src/services/${f}`));
    await c.query('SET search_path TO public');
    console.log('Données copiées :', Object.entries(copiees).filter(([, n]) => n > 0).map(([t, n]) => `${t}=${n}`).join('  '));

    // 3) Moteur sur la copie
    const { PrismaClient } = require(path.join(racine, 'node_modules', '.compta-pg-client'));
    const prisma = new PrismaClient({ datasources: { db: { url: urlPrisma } } });
    try {
      const referentiel = require('../src/compta/referentiel');
      const { ComptaService } = require('../src/compta/compta-service');
      const { MoteurAuto } = require('../src/compta/moteur-auto');
      const { EtatsService } = require('../src/compta/etats');
      await referentiel.ensureReferentiel(prisma);
      const service = new ComptaService(prisma, null);
      const moteur = new MoteurAuto(prisma, service);
      const etats = new EtatsService(prisma, service);

      const dates = [
        (await prisma.vente.aggregate({ _min: { dateVente: true } }))._min.dateVente,
        (await prisma.commandeApprovisionnement.aggregate({ _min: { dateCommande: true } }))._min.dateCommande,
        (await prisma.cashMovement.aggregate({ _min: { dateCreation: true } }))._min.dateCreation,
        (await prisma.transactionCompte.aggregate({ _min: { dateTransaction: true } }))._min.dateTransaction,
      ].filter(Boolean);
      if (dates.length === 0) { console.log('Aucune activité dans la base : rien à essayer.'); return; }
      const premiere = new Date(Math.min(...dates.map((d) => d.getTime())));
      const ouverture = new Date(Date.UTC(premiere.getUTCFullYear(), premiere.getUTCMonth(), 1));
      const caisseInitiale = (await prisma.cashRegister.aggregate({ _sum: { soldeInitial: true } }))._sum.soldeInitial || 0;
      const o = await service.enregistrerOuverture({
        dateOuverture: ouverture, dateFinExercice: new Date(Date.UTC(ouverture.getUTCFullYear() + 1, ouverture.getUTCMonth(), 0)),
        soldes: caisseInitiale > 0 ? [{ compteNumero: '571', debit: Math.round(caisseInitiale) }] : [],
      });
      console.log(`Ouverture au ${ouverture.toISOString().slice(0, 10)} (première activité : ${premiere.toISOString().slice(0, 10)}), écart d'ouverture ${fmt(o.ecart)}`);

      const t0 = Date.now();
      const rapport = await moteur.generer({ force: true });
      console.log(`\nGénération en ${((Date.now() - t0) / 1000).toFixed(1)} s`);
      for (const [type, b] of Object.entries(rapport.parType)) console.log(`  ${type.padEnd(22)} examinés ${String(b.examines).padStart(4)}  écritures ${String(b.ecritures).padStart(4)}  erreurs ${b.erreurs}`);
      const groupes = {};
      for (const e of rapport.erreurs) { const cle = `${e.type} : ${e.message}`; groupes[cle] = (groupes[cle] || 0) + 1; }
      console.log(rapport.erreurs.length ? '\nErreurs (regroupées) :' : '\nAucune erreur de génération.');
      for (const [m, n] of Object.entries(groupes)) console.log(`  ${n} × ${m}`);

      const relance = await moteur.generer({ force: true });
      const nouvelles = Object.values(relance.parType).reduce((s, b) => s + b.ecritures, 0);
      console.log(`\nSeconde passe : ${nouvelles} nouvelle(s) écriture(s) (attendu : 0, le moteur est idempotent)`);

      const bal = await service.balance({});
      console.log(`\nBalance : débit ${fmt(bal.total.debit)} = crédit ${fmt(bal.total.credit)} → ${bal.equilibree ? 'équilibrée' : 'DÉSÉQUILIBRÉE'}`);
      const cr = await etats.compteDeResultat({});
      const bilan = await etats.bilan({});
      console.log(`Compte de résultat : chiffre d'affaires ${fmt(cr.chiffreAffaires)}, résultat net ${fmt(cr.resultatNet)}`);
      console.log(`Bilan : actif ${fmt(bilan.actif.total)} / passif ${fmt(bilan.passif.total)} → ${bilan.equilibre ? 'équilibré' : 'NON ÉQUILIBRÉ'}${bilan.nonAffectes.length ? ` (${bilan.nonAffectes.length} compte(s) non classé(s))` : ''}`);
      const tft = await etats.fluxTresorerie({});
      console.log(`TFT : variation de trésorerie ${fmt(tft.variationTresorerie)} → contrôle ${tft.controle ? 'ok' : 'EN ÉCART'}`);

      const k = await moteur.controles();
      console.log('\nContrôles de cohérence comptabilité / gestion :');
      console.log(`  clients en écart : ${k.clients.length} (cumul des écarts ${fmt(k.clients.reduce((s, x) => s + Math.abs(x.ecart), 0))})`);
      console.log(`  fournisseurs en écart : ${k.fournisseurs.length} (cumul des écarts ${fmt(k.fournisseurs.reduce((s, x) => s + Math.abs(x.ecart), 0))})`);
      console.log(`  caisse : comptabilité ${fmt(k.caisse.comptabilite)} / gestion ${fmt(k.caisse.gestion)} → écart ${fmt(k.caisse.ecart)}`);
      const attente = await prisma.comptaLigne.aggregate({ where: { compte: { numero: { in: ['4711', '4712'] } } }, _sum: { debit: true, credit: true } });
      console.log(`  comptes d'attente (mouvements de caisse non identifiés) : débit ${fmt(attente._sum.debit)} / crédit ${fmt(attente._sum.credit)}`);
    } finally {
      await prisma.$disconnect();
    }
  } finally {
    await c.query('SET search_path TO public').catch(() => {});
    await c.query(`DROP SCHEMA IF EXISTS "${schema}" CASCADE`);
    await c.end();
    console.log(`\nSchéma temporaire ${schema} supprimé ; le schéma « public » n'a pas été modifié.`);
  }
}

main().catch((e) => { console.error('ERREUR :', e.message || e.code || String(e)); process.exit(1); });
