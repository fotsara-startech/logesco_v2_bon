/**
 * Renvoi vers le cloud des lignes locales que le système n'a jamais envoyées.
 *
 * Le contrôle d'écart (sync-health) repère des lignes présentes ici et absentes du cloud sans aucune trace
 * d'envoi (données antérieures à la mise en route de la synchronisation, par exemple). Ce module les renvoie,
 * mais seulement quand c'est sans risque. Chaque ligne est revérifiée AU MOMENT de l'envoi :
 *
 *   - l'identifiant est libre dans le cloud (un renvoi ne peut donc écraser aucune ligne existante) ;
 *   - le produit (et la boutique) existent dans le cloud et n'y ont pas été supprimés ;
 *   - aucune ligne équivalente n'existe déjà (même produit, même couple boutique + produit) ;
 *   - pour un mouvement de stock : le cloud n'a aucun autre mouvement pour ce produit. Sinon l'historique
 *     est déjà alimenté ailleurs et l'ajout d'un mouvement change la chaîne de stock : c'est une décision
 *     humaine (écran « Décisions à prendre »), pas un renvoi automatique.
 *
 * Tout ce qui ne passe pas est listé avec sa raison et n'est PAS envoyé.
 */

const { describeRecord, tableLabel } = require('./sync-detail');

/** Tables autorisées au renvoi automatique */
const TABLES_RENVOI = ['stock', 'stock_boutiques', 'mouvements_stock', 'historique_prix_achat'];

const num = (v) => (typeof v === 'bigint' ? Number(v) : v);

async function existeDansCloud(client, sql, params) {
  const r = await client.query(sql, params);
  return r.rows.length > 0;
}

/**
 * Analyse (sans rien envoyer).
 * @returns {{envoyables:Array, refuses:Array}}
 */
async function planifierRenvoi({ prisma, client, tables = TABLES_RENVOI, isConnectionError = () => false, forcer = new Set() }) {
  const envoyables = [];
  const refuses = [];

  // Ce que le système connaît déjà : on n'y touche pas
  const enAttente = new Map();
  try {
    for (const r of await prisma.$queryRawUnsafe(`SELECT table_name, record_id FROM operation_log WHERE status IN ('pending','failed') AND record_id IS NOT NULL`)) {
      if (!enAttente.has(r.table_name)) enAttente.set(r.table_name, new Set());
      enAttente.get(r.table_name).add(Number(r.record_id));
    }
  } catch (_) { /* journal absent */ }

  const supprimesCloud = new Set();
  try {
    const res = await client.query(`SELECT table_name, record_id FROM deleted_records`);
    for (const r of res.rows) supprimesCloud.add(`${r.table_name}|${Number(r.record_id)}`);
  } catch (e) {
    if (isConnectionError(e)) throw e;
  }

  for (const table of tables) {
    let locales;
    let idsCloud;
    try {
      locales = await prisma.$queryRawUnsafe(`SELECT * FROM "${table}"`);
      idsCloud = new Set((await client.query(`SELECT id FROM "${table}"`)).rows.map((r) => Number(r.id)));
    } catch (e) {
      if (isConnectionError(e)) throw e;
      continue;
    }

    for (const brute of locales) {
      const id = Number(brute.id);
      if (idsCloud.has(id)) continue;                         // déjà dans le cloud
      if (enAttente.get(table) && enAttente.get(table).has(id)) continue; // déjà prévu à l'envoi
      const ligne = Object.fromEntries(Object.entries(brute).map(([k, v]) => [k, num(v)]));
      const resume = await describeRecord(prisma, table, ligne, id).catch(() => `n° ${id}`);
      const refus = (raison, forcable = false) => refuses.push({ table, tableLabel: tableLabel(table), id, resume, raison, forcable });

      try {
        if (ligne.produit_id !== null && ligne.produit_id !== undefined) {
          const pid = Number(ligne.produit_id);
          if (supprimesCloud.has(`produits|${pid}`)) { refus('Le produit a été supprimé dans le cloud : à supprimer ici, pas à envoyer.'); continue; }
          if (!(await existeDansCloud(client, `SELECT 1 FROM "produits" WHERE id = $1`, [pid]))) { refus("Le produit n'existe pas dans le cloud."); continue; }
        }
        if (ligne.boutique_id !== null && ligne.boutique_id !== undefined) {
          if (!(await existeDansCloud(client, `SELECT 1 FROM "boutiques" WHERE id = $1`, [Number(ligne.boutique_id)]))) { refus("La boutique n'existe pas dans le cloud."); continue; }
        }

        if (table === 'stock') {
          if (await existeDansCloud(client, `SELECT 1 FROM "stock" WHERE produit_id = $1`, [Number(ligne.produit_id)])) { refus('Le cloud a déjà une ligne de stock pour ce produit sous un autre identifiant.'); continue; }
        } else if (table === 'stock_boutiques') {
          if (await existeDansCloud(client, `SELECT 1 FROM "stock_boutiques" WHERE produit_id = $1 AND boutique_id = $2`, [Number(ligne.produit_id), Number(ligne.boutique_id)])) {
            refus('Le cloud a déjà une ligne de stock pour ce produit dans cette boutique, sous un autre identifiant.'); continue;
          }
        } else if (table === 'mouvements_stock') {
          const r = await client.query(`SELECT COUNT(*) AS n FROM "mouvements_stock" WHERE produit_id = $1`, [Number(ligne.produit_id)]);
          const n = Number(r.rows[0].n);
          // Seul refus que la personne peut lever (« envoyer quand même ») : les autres rendraient l'envoi dangereux
          if (n > 0 && !forcer.has(`${table}|${id}`)) {
            refus(`Le cloud a déjà ${n} mouvement(s) pour ce produit : l'ajouter change l'historique du stock, à décider dans « Décisions à prendre ».`, true);
            continue;
          }
        }
      } catch (e) {
        if (isConnectionError(e)) throw e;
        refus(`Vérification impossible : ${e.message}`);
        continue;
      }

      envoyables.push({ table, tableLabel: tableLabel(table), id, resume, ligne });
    }
  }
  return { envoyables, refuses };
}

/**
 * Renvoie ce qui est sans risque. `dryRun` : simple aperçu.
 * `forcer` : lignes ({table, id}) que la personne choisit d'envoyer malgré le seul refus levable (mouvement de stock
 * alors que le cloud a déjà un historique pour ce produit).
 * @param {{prisma, client, logOperation:Function, dryRun?:boolean, tables?:string[], isConnectionError?:Function, forcer?:Array}} p
 */
async function renvoyerVersCloud({ prisma, client, logOperation, dryRun = false, tables, isConnectionError, forcer = [] }) {
  const aForcer = new Set((forcer || []).map((x) => `${x.table}|${Number(x.id)}`));
  const { envoyables, refuses } = await planifierRenvoi({ prisma, client, tables, isConnectionError, forcer: aForcer });
  if (!dryRun) {
    for (const e of envoyables) await logOperation(e.table, 'INSERT', e.ligne);
  }
  return {
    dryRun,
    envoyes: dryRun ? 0 : envoyables.length,
    aEnvoyer: envoyables.length,
    refuses: refuses.length,
    details: {
      envoyables: envoyables.map(({ table, tableLabel: l, id, resume }) => ({ table, tableLabel: l, id, resume })),
      refuses,
    },
  };
}

module.exports = { renvoyerVersCloud, planifierRenvoi, TABLES_RENVOI };
