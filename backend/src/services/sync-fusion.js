/**
 * Fusion champ par champ des fiches (produits, clients, fournisseurs, catégories).
 *
 * Défaut corrigé : une fiche était envoyée EN ENTIER, et le dernier envoi gagnait. Deux postes qui modifiaient des
 * champs différents de la même fiche (A : la description, B : le prix) se perdaient mutuellement une modification ; et
 * un poste relié tard avec une ANCIENNE modification écrasait la plus récente.
 *
 * Principe (fusion à trois, comme pour le stock) :
 *  - le poste retient, pour chaque fiche, sa « base » : la version qu'il a vue la dernière fois qu'il s'est synchronisé
 *    (table locale `sync_row_base`, mise à jour à la réception et à l'envoi) ;
 *  - à l'envoi, seules les colonnes réellement modifiées par rapport à cette base partent ;
 *  - dans le cloud, une colonne n'est écrasée que si (a) personne ne l'a changée depuis la base du poste, ou (b) la
 *    modification du poste est PLUS RÉCENTE que la dernière édition de la fiche (table `sync_edition`, date
 *    d'édition réelle : la colonne date_modification est réécrite par un déclencheur à chaque envoi, elle ne peut pas
 *    servir à comparer deux éditions). Cette date vit dans une TABLE À PART du cloud (`sync_edition`), pas dans une
 *    colonne des tables de fiches : un poste pas encore mis à jour lit ces tables avec SELECT * et recevrait une
 *    colonne qu'il ne connaît pas (l'insertion locale échouerait) ;
 *  - sans base connue (première modification depuis la mise à jour, ligne jamais synchronisée), la fiche part en entier
 *    mais ne remplace jamais une édition plus récente.
 */

const TABLES_FUSION = ['produits', 'clients', 'fournisseurs', 'categories'];

/** Jamais comparées ni envoyées par la fusion : identifiant, dates gérées par déclencheur ou à la création */
const COLONNES_IGNOREES = new Set(['id', 'date_modification', 'date_creation', 'derniere_edition']);

const DDL_BASE_LOCALE = `CREATE TABLE IF NOT EXISTS "sync_row_base" (
  "table_name" TEXT NOT NULL,
  "record_id"  INTEGER NOT NULL,
  "snapshot"   TEXT NOT NULL,
  PRIMARY KEY ("table_name", "record_id")
)`;

const DDL_EDITION_CLOUD = `CREATE TABLE IF NOT EXISTS "sync_edition" (
  "table_name"       TEXT NOT NULL,
  "record_id"        BIGINT NOT NULL,
  "derniere_edition" TIMESTAMP NOT NULL,
  PRIMARY KEY ("table_name", "record_id")
)`;

async function creerEditionCloud(client) {
  await client.query(DDL_EDITION_CLOUD);
}

async function creerBaseLocale(prisma) {
  await prisma.$executeRawUnsafe(DDL_BASE_LOCALE);
}

/** Valeur comparable ; undefined = colonne à ignorer (objet imbriqué, tableau) */
function normaliser(v) {
  if (v === null || v === undefined) return null;
  if (typeof v === 'bigint') return Number(v);
  if (typeof v === 'boolean') return v ? 1 : 0;
  if (v instanceof Date) return Number.isNaN(v.getTime()) ? null : v.toISOString();
  if (typeof v === 'object') return undefined;
  return v;
}

/** Colonnes scalaires d'une ligne, normalisées (clés en snake_case : la ligne doit déjà l'être) */
function instantane(ligne) {
  const out = {};
  for (const [k, v] of Object.entries(ligne || {})) {
    if (COLONNES_IGNOREES.has(k) || k.startsWith('_')) continue;
    const n = normaliser(v);
    if (n !== undefined) out[k] = n;
  }
  return out;
}

async function lireBase(prisma, table, id) {
  try {
    const r = await prisma.$queryRawUnsafe('SELECT "snapshot" AS s FROM "sync_row_base" WHERE "table_name" = ? AND "record_id" = ?', table, Number(id));
    if (!r.length) return null;
    return JSON.parse(r[0].s);
  } catch (_) {
    return null; // table absente ou illisible : comportement de repli (fiche entière, sans écraser une édition plus récente)
  }
}

async function ecrireBase(prisma, table, id, instantaneBase) {
  if (!TABLES_FUSION.includes(table) || !Number.isFinite(Number(id))) return;
  try {
    await prisma.$executeRawUnsafe(
      `INSERT INTO "sync_row_base" ("table_name", "record_id", "snapshot") VALUES (?, ?, ?)
       ON CONFLICT("table_name", "record_id") DO UPDATE SET "snapshot" = excluded."snapshot"`,
      table, Number(id), JSON.stringify(instantane(instantaneBase))
    );
  } catch (_) { /* table absente : la base ne sera simplement pas retenue */ }
}

/**
 * Colonnes de `courant` qui diffèrent de `base`. Une colonne absente de la base compte comme modifiée, SAUF si sa
 * valeur est vide : une colonne que le cloud ne connaît pas (ex. image_url, propre au poste) y est toujours vide et ne
 * doit pas partir.
 */
function colonnesModifiees(courant, base) {
  const out = [];
  for (const [k, v] of Object.entries(courant)) {
    if (!(k in base)) { if (v !== null) out.push(k); continue; }
    if (base[k] !== v) out.push(k);
  }
  return out;
}

/** Ne garde que les colonnes qui existent dans la table du cloud (`colonnesCloud` : Set de noms) */
function limiterAuxColonnes(ligne, colonnesCloud) {
  if (!colonnesCloud) return ligne;
  const out = {};
  for (const [k, v] of Object.entries(ligne)) if (k === 'id' || colonnesCloud.has(k) || k.startsWith('_') || k === 'date_modification' || k === 'dateModification') out[k] = v;
  return out;
}

/** Date d'édition ISO d'une opération : date de modification de la ligne locale, sinon maintenant */
function dateEdition(ligne) {
  const v = ligne && (ligne.date_modification || ligne.dateModification);
  const d = v instanceof Date ? v : new Date(typeof v === 'number' || typeof v === 'bigint' ? Number(v) : v);
  return Number.isNaN(d.getTime()) ? new Date().toISOString() : d.toISOString();
}

/** Enregistre la date d'édition d'une fiche (ne recule jamais) */
function requeteEdition({ table, id, edition }) {
  return {
    sql: `INSERT INTO "sync_edition" ("table_name", "record_id", "derniere_edition") VALUES ($1, $2, $3::timestamp)
          ON CONFLICT ("table_name", "record_id") DO UPDATE SET "derniere_edition" = GREATEST("sync_edition"."derniere_edition", EXCLUDED."derniere_edition")`,
    params: [table, id, edition],
  };
}

/**
 * Requête de mise à jour dans le cloud.
 *
 * La dernière édition de la fiche est lue dans `sync_edition` (jointure `e`, -infini si inconnue).
 *
 * @param {{table:string, ligne:Object, base:(Object|null), reactivation?:boolean}} p
 *   ligne : la ligne locale en snake_case ; base : instantané connu du cloud (ou null) ;
 *   reactivation : l'opération est une réactivation explicite d'un produit
 * @returns {{sql:string, params:Array, colonnes:string[], edition:string, id:number, upsertEdition:{sql:string, params:Array}}|null}
 *   null : rien à envoyer
 */
function construireMiseAJour({ table, ligne, base, reactivation = false }) {
  const courant = instantane(ligne);
  // Un produit désactivé ailleurs ne repasse à « actif » que par une réactivation explicite (voir produit-actif-collant)
  if (table === 'produits' && courant.est_actif === 1 && !reactivation) delete courant.est_actif;
  const edition = dateEdition(ligne);
  const id = Number(ligne.id);
  const upsertEdition = requeteEdition({ table, id, edition });
  const jointure = (pId) => `FROM (SELECT COALESCE((SELECT "derniere_edition" FROM "sync_edition" WHERE "table_name" = '${table}' AND "record_id" = ${pId}), '-infinity'::timestamp) AS ed) e`;

  if (!base) {
    // Sans base : fiche entière, mais jamais par-dessus une édition plus récente
    const colonnes = Object.keys(courant).filter((k) => courant[k] !== null);
    if (!colonnes.length) return null;
    const params = colonnes.map((k) => courant[k]);
    const sets = colonnes.map((k, i) => `"${k}" = $${i + 1}`);
    params.push(id);
    const pId = `$${params.length}`;
    params.push(edition);
    const pEdition = `$${params.length}::timestamp`;
    return {
      sql: `UPDATE "${table}" SET ${sets.join(', ')} ${jointure(pId)} WHERE "${table}".id = ${pId} AND e.ed <= ${pEdition}`,
      params, colonnes, edition, id, upsertEdition,
    };
  }

  const colonnes = colonnesModifiees(courant, base);
  if (!colonnes.length) return null;
  const params = [];
  const sets = [];
  params.push(edition);
  const pEdition = `$${params.length}::timestamp`;
  const pIdIndex = colonnes.length * 2 + 2;
  const pId = `$${pIdIndex}`;
  for (const k of colonnes) {
    params.push(courant[k]);
    const pNouveau = `$${params.length}`;
    params.push(k in base ? base[k] : null);
    const pBase = `$${params.length}`;
    // appliquée si personne ne l'a changée depuis notre base, ou si notre édition est plus récente que la dernière
    sets.push(`"${k}" = CASE WHEN "${table}"."${k}" IS NOT DISTINCT FROM ${pBase} OR e.ed <= ${pEdition} THEN ${pNouveau} ELSE "${table}"."${k}" END`);
  }
  params.push(id);
  return {
    sql: `UPDATE "${table}" SET ${sets.join(', ')} ${jointure(pId)} WHERE "${table}".id = ${pId}`,
    params, colonnes, edition, id, upsertEdition,
  };
}

module.exports = {
  creerEditionCloud, requeteEdition, TABLES_FUSION, COLONNES_IGNOREES, creerBaseLocale, lireBase, ecrireBase,
  normaliser, instantane, colonnesModifiees, limiterAuxColonnes, dateEdition, construireMiseAJour,
};
