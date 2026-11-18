/**
 * Une seule façon de stocker une date dans SQLite : un NOMBRE (millisecondes depuis 1970), comme le fait l'ORM.
 *
 * Contexte : la réception des lignes du cloud écrivait les dates en TEXTE ('2026-07-29T07:23:14.208Z'), alors que
 * l'application les écrit en nombre. Résultat : colonnes mélangées, filtres de période faux (tableau de bord à 30 / 30 / 30)
 * et tri par date incohérent. Ce module fournit :
 *   - versMillisecondes : conversion d'une valeur (Date, texte ISO ou SQL, nombre) en millisecondes ;
 *   - normaliserDates   : conversion UNIQUE des dates déjà en texte (migration au démarrage, relançable sans risque).
 *
 * Les tables internes de la synchronisation (journal, suppressions, état de réception...) gardent leur format : elles
 * sont comparées avec datetime('now') par le code de synchronisation.
 */
const { enMillisecondes } = require('../utils/filtre-date');

const TABLES_INTERNES = /^(sqlite_|_app_migrations$|_prisma|operation_log$|deleted_records$|decision_log$|sync_)/;

/** Millisecondes depuis 1970 pour une Date, un nombre ou un texte (ISO, ou 'AAAA-MM-JJ HH:MM:SS' = UTC) ; null si illisible */
function versMillisecondes(valeur) {
  if (valeur === null || valeur === undefined) return null;
  if (valeur instanceof Date) return Number.isNaN(valeur.getTime()) ? null : valeur.getTime();
  if (typeof valeur === 'bigint') return Number(valeur);
  if (typeof valeur === 'number') return Number.isFinite(valeur) ? valeur : null;
  const texte = String(valeur).trim();
  if (!/^\d{4}-\d{2}-\d{2}/.test(texte)) return null;
  let iso = texte.includes('T') ? texte : texte.replace(' ', 'T');
  if (!/(Z|[+-]\d{2}:?\d{2})$/i.test(iso)) iso += 'Z'; // sans fuseau : UTC (convention de SQLite)
  const t = Date.parse(iso);
  return Number.isNaN(t) ? null : t;
}

/** Colonnes de type date des tables métier : [{ table, colonne }] */
async function colonnesDate(prisma) {
  const tables = await prisma.$queryRawUnsafe(`SELECT name FROM sqlite_master WHERE type = 'table'`);
  const resultat = [];
  for (const { name } of tables) {
    if (TABLES_INTERNES.test(name)) continue;
    const colonnes = await prisma.$queryRawUnsafe(
      `SELECT name FROM pragma_table_info('${name.replace(/'/g, "''")}') WHERE upper(type) LIKE 'DATETIME%' OR upper(type) LIKE 'TIMESTAMP%'`,
    );
    for (const c of colonnes) resultat.push({ table: name, colonne: c.name });
  }
  return resultat;
}

/**
 * Convertit en millisecondes toutes les dates encore en texte dans les tables métier.
 * Sans danger si relancée : seules les valeurs de type texte et lisibles comme une date sont touchées.
 * @returns {Promise<{ colonnes: number, lignes: number }>}
 */
async function normaliserDates(prisma) {
  let lignes = 0;
  let colonnes = 0;
  for (const { table, colonne } of await colonnesDate(prisma)) {
    const t = `"${table}"`;
    const c = `"${colonne}"`;
    const n = await prisma.$executeRawUnsafe(
      `UPDATE ${t} SET ${c} = ${enMillisecondes(colonne)} WHERE typeof(${c}) = 'text' AND strftime('%s', ${c}) IS NOT NULL`,
    );
    if (n > 0) {
      lignes += n;
      colonnes++;
    }
  }
  return { colonnes, lignes };
}

module.exports = { versMillisecondes, colonnesDate, normaliserDates, TABLES_INTERNES };
