/**
 * Envoi du stock par DIFFÉRENCE (et non par valeur totale).
 *
 * Défaut corrigé : chaque vente envoyait au cloud le stock TOTAL du poste (« quantite_disponible = 997 »). Deux postes
 * qui vendent en même temps s'écrasaient : A (1000 − 3 = 997) puis B (1000 − 2 = 998) laissaient 998 dans le cloud au lieu
 * de 995, alors que les deux mouvements de vente étaient bien présents.
 *
 * Principe :
 *  - le poste retient, pour chaque ligne de stock, sa « base » : la valeur qu'il avait la dernière fois qu'il s'est
 *    synchronisé avec le cloud (table locale `sync_stock_base`) ;
 *  - à l'envoi, le cloud ajoute la DIFFÉRENCE (valeur envoyée − base) à son total : A envoie −3, B envoie −2, le cloud
 *    arrive à 995 ;
 *  - l'envoi et l'inscription de l'identifiant de l'opération dans le registre `sync_applied_ops` (clé unique) se font
 *    dans UNE transaction : une opération rejouée après un accusé de réception perdu n'est jamais comptée deux fois ;
 *  - la réception rapporte ensuite le total du cloud sur les postes, et la base est alors remise à cette valeur.
 *
 * Sans base connue (première synchronisation, anciennes données) ou si la ligne n'existe pas encore dans le cloud : on garde
 * l'envoi de la valeur totale, qui crée la ligne, puis la base est établie.
 */

const TABLES_STOCK = ['stock', 'stock_boutiques'];

const DDL_BASE_LOCALE = `CREATE TABLE IF NOT EXISTS "sync_stock_base" (
  "table_name" TEXT NOT NULL,
  "record_id"  INTEGER NOT NULL,
  "quantite"   REAL NOT NULL,
  PRIMARY KEY ("table_name", "record_id")
)`;

const DDL_REGISTRE_CLOUD = `CREATE TABLE IF NOT EXISTS "sync_applied_ops" (
  "operation_id" TEXT PRIMARY KEY,
  "applied_at"   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
)`;

const num = (v) => (typeof v === 'bigint' ? Number(v) : v);

async function creerBaseLocale(prisma) {
  await prisma.$executeRawUnsafe(DDL_BASE_LOCALE);
}

async function creerRegistreCloud(client) {
  await client.query(DDL_REGISTRE_CLOUD);
}

/** Dernière valeur synchronisée de la ligne, ou null si inconnue */
async function lireBase(prisma, table, id) {
  try {
    const r = await prisma.$queryRawUnsafe(`SELECT CAST("quantite" AS TEXT) AS q FROM "sync_stock_base" WHERE "table_name" = ? AND "record_id" = ?`, table, Number(id));
    if (!r.length) return null;
    const v = Number(r[0].q);
    return Number.isFinite(v) ? v : null;
  } catch (_) {
    return null; // table absente : comportement historique
  }
}

async function ecrireBase(prisma, table, id, quantite) {
  const q = Number(quantite);
  if (!TABLES_STOCK.includes(table) || !Number.isFinite(q) || !Number.isFinite(Number(id))) return;
  try {
    await prisma.$executeRawUnsafe(
      `INSERT INTO "sync_stock_base" ("table_name", "record_id", "quantite") VALUES (?, ?, ?)
       ON CONFLICT("table_name", "record_id") DO UPDATE SET "quantite" = excluded."quantite"`,
      table, Number(id), q
    );
  } catch (_) { /* table absente : la base ne sera simplement pas retenue */ }
}

const aColonneDateModification = new Map(); // table → bool (le schéma ne change pas en cours d'exécution)
async function dateModificationExiste(client, table) {
  if (aColonneDateModification.has(table)) return aColonneDateModification.get(table);
  let existe = false;
  try {
    const r = await client.query(
      `SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = $1 AND column_name = 'date_modification' LIMIT 1`,
      [table]
    );
    existe = r.rows.length > 0;
  } catch (_) { /* on n'y touche pas */ }
  aColonneDateModification.set(table, existe);
  return existe;
}

function enIso(v) {
  if (v === null || v === undefined) return null;
  const d = typeof v === 'number' || typeof v === 'bigint' ? new Date(Number(v)) : new Date(v);
  return Number.isNaN(d.getTime()) ? null : d.toISOString();
}

/**
 * Applique une opération de stock par différence.
 *
 * @param {{client:Object, prisma:Object, table:string, row:Object, operationId:string}} p
 *   row : ligne en snake_case (id, quantite_disponible, éventuellement quantite_reservee, derniere_maj)
 * @returns {Promise<{traite:boolean, doublon?:boolean, difference?:number}>}
 *   traite=false : l'appelant doit envoyer la valeur totale (pas de base connue, ou ligne absente du cloud)
 */
async function appliquerParDifference({ client, prisma, table, row, operationId }) {
  if (!TABLES_STOCK.includes(table) || !operationId) return { traite: false };
  const id = Number(row.id);
  const quantite = Number(num(row.quantite_disponible));
  if (!Number.isFinite(id) || !Number.isFinite(quantite)) return { traite: false };

  const base = await lireBase(prisma, table, id);
  if (base === null) return { traite: false };
  const difference = quantite - base;

  // UNE SEULE requête (donc un seul aller-retour vers le cloud, et atomique sans transaction explicite) :
  //  - inscrire l'opération au registre (clé unique : un rejeu après accusé perdu n'est jamais compté deux fois) ;
  //  - ajouter la DIFFÉRENCE au stock, seulement si l'inscription vient d'avoir lieu.
  // Avant : BEGIN + registre + mise à jour + COMMIT = 4 allers-retours, soit 4 fois plus lent sur une connexion lente.
  const params = [operationId, difference];
  const sets = ['"quantite_disponible" = "quantite_disponible" + $2'];
  if (row.quantite_reservee !== undefined && row.quantite_reservee !== null) {
    params.push(Number(num(row.quantite_reservee)));
    sets.push(`"quantite_reservee" = $${params.length}`);
  }
  const derniereMaj = enIso(row.derniere_maj);
  if (derniereMaj) {
    params.push(derniereMaj);
    sets.push(`"derniere_maj" = $${params.length}`);
  }
  // Les autres postes reçoivent le changement grâce à la date de modification : on la fait avancer elle-même, sans
  // compter sur un déclencheur côté cloud
  if (await dateModificationExiste(client, table)) sets.push('"date_modification" = CURRENT_TIMESTAMP');
  params.push(id);

  const r = await client.query(
    `WITH reg AS (
       INSERT INTO "sync_applied_ops" ("operation_id") VALUES ($1) ON CONFLICT DO NOTHING RETURNING "operation_id"
     ), maj AS (
       UPDATE "${table}" SET ${sets.join(', ')} WHERE id = $${params.length} AND EXISTS (SELECT 1 FROM reg) RETURNING 1
     )
     SELECT (SELECT COUNT(*) FROM reg)::int AS enregistre, (SELECT COUNT(*) FROM maj)::int AS mis_a_jour`,
    params
  );
  const { enregistre, mis_a_jour: misAJour } = r.rows[0] || { enregistre: 0, mis_a_jour: 0 };

  if (Number(enregistre) === 0) {
    // Opération déjà appliquée (accusé de réception perdu puis rejeu) : on ne la compte pas deux fois
    await ecrireBase(prisma, table, id, quantite);
    return { traite: true, doublon: true, difference: 0 };
  }
  if (Number(misAJour) === 0) {
    // La ligne n'existe pas (encore) dans le cloud : l'envoi de la valeur totale la créera. On retire aussi l'inscription
    // au registre, pour que cette opération soit rejouée par le chemin normal (cas rare : un aller-retour de plus).
    await client.query('DELETE FROM "sync_applied_ops" WHERE "operation_id" = $1', [operationId]);
    return { traite: false };
  }
  await ecrireBase(prisma, table, id, quantite);
  return { traite: true, difference };
}

module.exports = { TABLES_STOCK, creerBaseLocale, creerRegistreCloud, lireBase, ecrireBase, appliquerParDifference };
