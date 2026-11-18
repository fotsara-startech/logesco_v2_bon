/**
 * Filtres de DATE fiables, quel que soit le format dans lequel SQLite a stocké la date.
 *
 * Le piège : dans une base SQLite, une colonne date peut contenir du TEXTE ('2026-07-29T07:23:14.208Z' ou
 * '2026-07-29 07:23:14') ou des NOMBRES (millisecondes, ce qu'écrit l'ORM). Or l'ORM envoie toujours la date du filtre
 * sous forme de nombre, et SQLite classe tout texte au-dessus de tout nombre : `date >= x` laissait passer TOUTES les
 * lignes et `date <= x` n'en laissait passer AUCUNE. Écrans touchés : listes et rapports filtrés par période.
 *
 * Solution : on demande d'abord à SQLite les identifiants des lignes dans la bonne période, en ramenant les deux formats
 * à des millisecondes, puis on ajoute `id IN (...)` au filtre existant (pagination et autres filtres restent intacts).
 * Sur une base qui n'est pas SQLite (PostgreSQL du cloud), le filtre d'origine est conservé tel quel.
 *
 * Usage :
 *   await appliquerFiltreDate(prisma, where, { table: 'ventes', colonne: 'date_vente', champ: 'dateVente' }, { gte: debut, lte: fin });
 */

const OPERATEURS = { gte: '>=', gt: '>', lte: '<=', lt: '<' };
const MAX_IDENTIFIANTS = 30000; // limite de variables de SQLite (32 766) : au-delà, on garde le filtre d'origine

const estSqlite = new WeakMap();

async function baseSqlite(prisma) {
  if (estSqlite.has(prisma)) return estSqlite.get(prisma);
  let r = false;
  try {
    await prisma.$queryRawUnsafe('SELECT sqlite_version() AS v');
    r = true;
  } catch (_) {
    r = false;
  }
  estSqlite.set(prisma, r);
  return r;
}

/** Expression SQL qui ramène la colonne à des millisecondes, qu'elle soit stockée en nombre ou en texte */
function enMillisecondes(colonne) {
  const c = `"${colonne}"`;
  return (
    `CASE WHEN typeof(${c}) IN ('integer','real') THEN CAST(${c} AS INTEGER) ` +
    `ELSE CAST(strftime('%s', ${c}) AS INTEGER) * 1000 + ` +
    `CASE WHEN instr(${c}, '.') > 0 THEN CAST(substr(${c}, instr(${c}, '.') + 1, 3) AS INTEGER) ELSE 0 END END`
  );
}

/** Bornes valides, converties en millisecondes : { gte: 1.7e12, ... } */
function bornesEnMs(bornes) {
  const r = {};
  for (const op of Object.keys(OPERATEURS)) {
    if (bornes[op] === undefined || bornes[op] === null) continue;
    const t = new Date(bornes[op]).getTime();
    if (!Number.isNaN(t)) r[op] = t;
  }
  return r;
}

/**
 * Fragment de filtre prêt à être ajouté à un `where` : `{ id: { in: [...] } }` sur SQLite, `{ [champ]: bornes }` ailleurs.
 * Retourne null s'il n'y a aucune borne valide.
 */
async function clauseDate(prisma, { table, colonne, champ }, bornes) {
  const ms = bornesEnMs(bornes || {});
  const ops = Object.keys(ms);
  if (ops.length === 0) return null;

  const dOrigine = {};
  for (const op of ops) dOrigine[op] = new Date(ms[op]);
  const filtreOrigine = { [champ]: dOrigine };

  if (!(await baseSqlite(prisma))) return filtreOrigine;

  const expr = enMillisecondes(colonne);
  const conditions = ops.map((op) => `${expr} ${OPERATEURS[op]} ?`).join(' AND ');
  const lignes = await prisma.$queryRawUnsafe(`SELECT id FROM "${table}" WHERE ${conditions}`, ...ops.map((op) => ms[op]));
  if (lignes.length > MAX_IDENTIFIANTS) {
    console.warn(`⚠️ [filtre-date] ${lignes.length} lignes dans la période pour ${table} : filtre d'origine conservé`);
    return filtreOrigine;
  }
  return { id: { in: lignes.map((l) => Number(l.id)) } };
}

/** Ajoute le filtre de date à `where` (en AND avec ce qui existe déjà) et retourne `where` */
async function appliquerFiltreDate(prisma, where, spec, bornes) {
  const clause = await clauseDate(prisma, spec, bornes);
  if (!clause) return where;
  where.AND = [].concat(where.AND || [], [clause]);
  return where;
}

module.exports = { clauseDate, appliquerFiltreDate, enMillisecondes };
