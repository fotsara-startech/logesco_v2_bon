/**
 * Contrôle d'écart entre ce poste et le cloud.
 *
 * Le détail de synchronisation (sync-detail) ne montre que ce que le système SAIT être en retard : envois en
 * attente, envois refusés, lignes reçues non appliquées. Un écart qu'aucun de ces mécanismes ne connaît
 * (ligne jamais reçue, ligne jamais envoyée, valeur différente) reste invisible : c'est ainsi qu'un poste a pu
 * rester des semaines sans plusieurs produits du cloud.
 *
 * Ce contrôle compare directement les deux bases, table par table :
 *   - identifiants présents d'un seul côté (« à recevoir » / « à envoyer ») ;
 *   - valeurs différentes pour les chiffres qui comptent (stock, soldes de comptes).
 * Chaque écart est rapproché de ce que le système connaît déjà (envoi en attente, file de reprise,
 * suppression) : seul l'écart NON expliqué est une alerte. Sa date de première détection est conservée pour
 * signaler ceux qui durent (par défaut : plus d'un jour).
 */

const { describeRecord, tableLabel } = require('./sync-detail');
const { planifierRenvoi } = require('./sync-resend');

/** Chiffres comparés valeur par valeur (id → colonne) */
const VALEURS = {
  stock_boutiques: 'quantite_disponible',
  stock: 'quantite_disponible',
  comptes_clients: 'solde_actuel',
  comptes_fournisseurs: 'solde_actuel',
};

const MAX_LIGNES_COMPAREES = 300000; // au-delà : comparaison par comptage seulement
const MAX_EXEMPLES = 5;
const MAX_SUIVIS = 20000;
const UN_JOUR_MS = 24 * 60 * 60 * 1000;

const CAUSES = {
  a_recevoir: {
    inconnue: "Présent dans le cloud mais jamais reçu sur ce poste",
    reprise: 'Reçu mais non appliqué (file de reprise)',
    supprime_ici: 'Supprimé ici, suppression pas encore transmise au cloud',
  },
  a_envoyer: {
    inconnue: "Présent sur ce poste mais jamais arrivé dans le cloud",
    en_attente: "Envoi en attente",
    supprime_cloud: 'Supprimé dans le cloud mais encore présent sur ce poste',
  },
  valeur: {
    differente: 'Valeur différente entre ce poste et le cloud',
  },
};
const CONNUES = new Set(['reprise', 'supprime_ici', 'en_attente']);

const num = (v) => (typeof v === 'bigint' ? Number(v) : v);

async function assurerSuivi(prisma) {
  await prisma.$executeRawUnsafe(
    `CREATE TABLE IF NOT EXISTS "sync_drift_state" (
       "table_name"    TEXT NOT NULL,
       "record_id"     INTEGER NOT NULL,
       "sens"          TEXT NOT NULL,
       "first_seen_at" INTEGER NOT NULL,
       PRIMARY KEY ("table_name", "record_id", "sens")
     )`
  );
  await prisma.$executeRawUnsafe(
    `CREATE TABLE IF NOT EXISTS "sync_drift_ignored" (
       "table_name"  TEXT NOT NULL,
       "record_id"   INTEGER NOT NULL,
       "sens"        TEXT NOT NULL,
       "ignored_at"  INTEGER NOT NULL,
       "ignored_by"  INTEGER,
       "note"        TEXT,
       PRIMARY KEY ("table_name", "record_id", "sens")
     )`
  );
}

/** Écarts qu'une personne a déclarés « vus, volontaires » : seuls les écarts de présence peuvent l'être */
const SENS_IGNORABLES = ['a_envoyer', 'a_recevoir'];

async function ignorerEcarts(prisma, items, { userId = null, note = null, now = Date.now() } = {}) {
  await assurerSuivi(prisma);
  let n = 0;
  for (const it of items || []) {
    if (!it || !it.table || !SENS_IGNORABLES.includes(it.sens) || !Number.isFinite(Number(it.id))) continue;
    n += await prisma.$executeRawUnsafe(
      `INSERT OR REPLACE INTO sync_drift_ignored (table_name, record_id, sens, ignored_at, ignored_by, note) VALUES (?, ?, ?, ?, ?, ?)`,
      it.table, Number(it.id), it.sens, now, userId, note
    );
  }
  return n;
}

async function restaurerEcarts(prisma) {
  await assurerSuivi(prisma);
  return prisma.$executeRawUnsafe(`DELETE FROM sync_drift_ignored`);
}

async function idsLocaux(prisma, table, colonneValeur) {
  const cols = colonneValeur ? `id, "${colonneValeur}" AS v` : 'id';
  const rows = await prisma.$queryRawUnsafe(`SELECT ${cols} FROM "${table}"`);
  const m = new Map();
  for (const r of rows) m.set(Number(r.id), colonneValeur ? num(r.v) : null);
  return m;
}

async function idsCloud(client, table, colonneValeur) {
  const cols = colonneValeur ? `id, "${colonneValeur}" AS v` : 'id';
  const res = await client.query(`SELECT ${cols} FROM "${table}"`);
  const m = new Map();
  for (const r of res.rows) m.set(Number(r.id), colonneValeur ? (r.v === null ? null : Number(r.v)) : null);
  return m;
}

async function ensembleDe(prisma, sql, ...params) {
  const rows = await prisma.$queryRawUnsafe(sql, ...params);
  const parTable = new Map();
  for (const r of rows) {
    if (!parTable.has(r.table_name)) parTable.set(r.table_name, new Set());
    parTable.get(r.table_name).add(Number(r.record_id));
  }
  return parTable;
}

function aDansEnsemble(map, table, id) {
  const s = map.get(table);
  return !!s && s.has(id);
}

/**
 * @param {{prisma:Object, client:Object, tables:string[], now?:number, seuilAncienMs?:number,
 *          isConnectionError?:Function}} p
 */
async function computeDrift({ prisma, client, tables, now = Date.now(), seuilAncienMs = UN_JOUR_MS, isConnectionError = () => false, avecRenvoi = false }) {
  await assurerSuivi(prisma);

  // Ce que le système sait déjà
  const enAttente = await ensembleDe(prisma, `SELECT table_name, record_id FROM operation_log WHERE status IN ('pending','failed') AND record_id IS NOT NULL`).catch(() => new Map());
  const reprise = await ensembleDe(prisma, `SELECT table_name, record_id FROM sync_pull_retry`).catch(() => new Map());
  const supprimesIci = await ensembleDe(prisma, `SELECT table_name, record_id FROM deleted_records`).catch(() => new Map());
  let supprimesCloud = new Map();
  try {
    const res = await client.query(`SELECT table_name, record_id FROM deleted_records`);
    for (const r of res.rows) {
      if (!supprimesCloud.has(r.table_name)) supprimesCloud.set(r.table_name, new Set());
      supprimesCloud.get(r.table_name).add(Number(r.record_id));
    }
  } catch (e) {
    if (isConnectionError(e)) throw e;
  }

  const constats = []; // { table, sens, id, cause, local?, cloud? }
  const parTable = [];

  for (const table of tables) {
    const colVal = VALEURS[table] || null;
    let locaux;
    let cloud;
    try {
      locaux = await idsLocaux(prisma, table, colVal);
      cloud = await idsCloud(client, table, colVal);
    } catch (e) {
      if (isConnectionError(e)) throw e;
      continue; // table absente d'un côté (ancienne installation) : rien à comparer
    }
    parTable.push({ table, label: tableLabel(table), nbLocal: locaux.size, nbCloud: cloud.size });
    if (locaux.size > MAX_LIGNES_COMPAREES || cloud.size > MAX_LIGNES_COMPAREES) continue;

    for (const id of cloud.keys()) {
      if (locaux.has(id)) continue;
      let cause = 'inconnue';
      if (aDansEnsemble(reprise, table, id)) cause = 'reprise';
      else if (aDansEnsemble(supprimesIci, table, id)) cause = 'supprime_ici';
      constats.push({ table, sens: 'a_recevoir', id, cause });
    }
    for (const id of locaux.keys()) {
      if (cloud.has(id)) continue;
      let cause = 'inconnue';
      if (aDansEnsemble(enAttente, table, id)) cause = 'en_attente';
      else if (aDansEnsemble(supprimesCloud, table, id)) cause = 'supprime_cloud';
      constats.push({ table, sens: 'a_envoyer', id, cause });
    }
    if (colVal) {
      for (const [id, vLocal] of locaux) {
        if (!cloud.has(id)) continue;
        const vCloud = cloud.get(id);
        const diff = Math.abs((Number(vLocal) || 0) - (Number(vCloud) || 0));
        if (diff < 0.01) continue;
        // une modification en cours d'envoi ou de réception explique la différence
        if (aDansEnsemble(enAttente, table, id) || aDansEnsemble(reprise, table, id)) continue;
        constats.push({ table, sens: 'valeur', id, cause: 'differente', local: vLocal, cloud: vCloud });
      }
    }
  }

  // Écarts déclarés « vus » par une personne : écartés du rapport tant qu'ils existent ; oubliés dès qu'ils disparaissent
  const ignores = new Set();
  for (const r of await prisma.$queryRawUnsafe(`SELECT table_name, record_id, sens FROM sync_drift_ignored`)) {
    ignores.add(`${r.table_name}|${Number(r.record_id)}|${r.sens}`);
  }
  const presents = new Set(constats.map((c) => `${c.table}|${c.id}|${c.sens}`));
  for (const k of ignores) {
    if (presents.has(k)) continue;
    const [t, id, sens] = k.split('|');
    await prisma.$executeRawUnsafe(`DELETE FROM sync_drift_ignored WHERE table_name = ? AND record_id = ? AND sens = ?`, t, Number(id), sens);
  }
  let nbIgnores = 0;
  for (let i = constats.length - 1; i >= 0; i--) {
    const c = constats[i];
    if (!CONNUES.has(c.cause) && ignores.has(`${c.table}|${c.id}|${c.sens}`)) {
      constats.splice(i, 1);
      nbIgnores++;
    }
  }

  // Ancienneté : première détection conservée tant que l'écart dure ; effacée dès qu'il disparaît
  const inexpliques = constats.filter((c) => !CONNUES.has(c.cause));
  const vus = new Map();
  const suivis = await prisma.$queryRawUnsafe(`SELECT table_name, record_id, sens, first_seen_at FROM sync_drift_state`);
  for (const s of suivis) vus.set(`${s.table_name}|${Number(s.record_id)}|${s.sens}`, Number(s.first_seen_at));
  const encore = new Set();
  for (const c of inexpliques.slice(0, MAX_SUIVIS)) {
    const k = `${c.table}|${c.id}|${c.sens}`;
    encore.add(k);
    if (!vus.has(k)) {
      await prisma.$executeRawUnsafe(
        `INSERT OR IGNORE INTO sync_drift_state (table_name, record_id, sens, first_seen_at) VALUES (?, ?, ?, ?)`,
        c.table, c.id, c.sens, now
      );
      vus.set(k, now);
    }
    c.premiereDetection = vus.get(k);
  }
  for (const [k] of vus) {
    if (encore.has(k)) continue;
    const [t, id, sens] = k.split('|');
    await prisma.$executeRawUnsafe(`DELETE FROM sync_drift_state WHERE table_name = ? AND record_id = ? AND sens = ?`, t, Number(id), sens);
  }

  // Verdict du renvoi pour chaque ligne « ici, pas dans le cloud » (même règles que le bouton « Renvoyer »)
  const verdicts = new Map();
  if (avecRenvoi && constats.some((c) => c.sens === 'a_envoyer' && !CONNUES.has(c.cause))) {
    const plan = await planifierRenvoi({ prisma, client, isConnectionError });
    for (const e of plan.envoyables) verdicts.set(`${e.table}|${e.id}`, { ok: true });
    for (const r of plan.refuses) verdicts.set(`${r.table}|${r.id}`, { ok: false, raison: r.raison, forcable: !!r.forcable });
  }

  // Regroupement par table / sens / cause
  const groupes = new Map();
  for (const c of constats) {
    const k = `${c.table}|${c.sens}|${c.cause}`;
    if (!groupes.has(k)) groupes.set(k, { table: c.table, label: tableLabel(c.table), sens: c.sens, cause: c.cause, connue: CONNUES.has(c.cause), libelle: CAUSES[c.sens][c.cause], lignes: [] });
    groupes.get(k).lignes.push(c);
  }
  const ecarts = [];
  for (const g of groupes.values()) {
    const anciens = g.lignes.filter((l) => l.premiereDetection && now - l.premiereDetection >= seuilAncienMs);
    const premieres = g.lignes.map((l) => l.premiereDetection).filter(Boolean);
    const exemples = [];
    for (const l of g.lignes.slice(0, MAX_EXEMPLES)) {
      let resume = `n° ${l.id}`;
      try {
        const ligne = (await prisma.$queryRawUnsafe(`SELECT * FROM "${l.table}" WHERE id = ? LIMIT 1`, l.id))[0];
        let donnees = ligne || null;
        if (!donnees && l.sens === 'a_recevoir') {
          const r = await client.query(`SELECT * FROM "${l.table}" WHERE id = $1 LIMIT 1`, [l.id]);
          donnees = r.rows[0] || null;
        }
        if (donnees) resume = await describeRecord(prisma, l.table, donnees, l.id);
      } catch (e) {
        if (isConnectionError(e)) throw e;
      }
      exemples.push({ id: l.id, resume, ...(l.sens === 'valeur' ? { local: l.local, cloud: l.cloud } : {}) });
    }
    let renvoi = null;
    if (verdicts.size && g.sens === 'a_envoyer' && !g.connue) {
      const v = g.lignes.map((l) => verdicts.get(`${l.table}|${l.id}`)).filter(Boolean);
      if (v.length) {
        renvoi = {
          envoyables: v.filter((x) => x.ok).length,
          refuses: v.filter((x) => !x.ok).length,
          raisons: [...new Set(v.filter((x) => !x.ok).map((x) => x.raison))],
          forcable: v.some((x) => !x.ok && x.forcable),
        };
      }
    }
    ecarts.push({
      table: g.table, tableLabel: g.label, sens: g.sens, cause: g.cause, connue: g.connue, libelle: g.libelle,
      ids: g.lignes.slice(0, 500).map((l) => ({ table: l.table, id: l.id, sens: l.sens })),
      renvoi,
      nombre: g.lignes.length,
      anciens: g.connue ? 0 : anciens.length,
      depuis: !g.connue && premieres.length ? new Date(Math.min(...premieres)).toISOString() : null,
      exemples,
    });
  }
  // Les écarts inconnus d'abord, les plus anciens en tête
  ecarts.sort((a, b) => {
    if (a.connue !== b.connue) return a.connue ? 1 : -1;
    const da = a.depuis || '';
    const db = b.depuis || '';
    if (da !== db) return da < db ? -1 : 1;
    return b.nombre - a.nombre;
  });

  return {
    verifieLe: new Date(now).toISOString(),
    seuilAncienHeures: Math.round(seuilAncienMs / 3600000),
    tables: parTable,
    ecarts,
    resume: {
      inexpliques: inexpliques.length,
      anciens: ecarts.reduce((n, e) => n + e.anciens, 0),
      connus: constats.length - inexpliques.length,
      ignores: nbIgnores,
    },
  };
}

module.exports = { computeDrift, ignorerEcarts, restaurerEcarts, CAUSES, VALEURS };
