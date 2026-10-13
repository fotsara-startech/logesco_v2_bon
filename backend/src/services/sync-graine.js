/**
 * Données de base du tout premier poste (« graine ») : rôle, utilisateur, boutique, caisse, paramètres.
 *
 * Défaut corrigé : ces lignes sont créées au premier démarrage, sans passer par le journal d'envoi, et le script
 * d'installation du cloud n'en insère aucune. Sur un cloud neuf, elles n'arrivaient donc JAMAIS ; toutes les lignes qui
 * en dépendent (stock par boutique, ventes, sessions de caisse) étaient refusées par clé étrangère, restaient en échec,
 * et les autres postes ne recevaient ni boutique ni rôle.
 *
 * Règle (sans risque pour un client établi) :
 *  - pour chaque table de base, si le cloud n'y a AUCUNE ligne et que le poste en a : on journalise un INSERT par ligne
 *    locale, une seule fois ;
 *  - si le cloud a déjà des lignes dans cette table : on n'envoie rien (un poste qui rejoint un cloud existant est
 *    traité par la fusion sur clé naturelle, qui ne doit pas être court-circuitée), et on n'y revient plus.
 *
 * Le rejeu des opérations range déjà les tables parents avant les enfants (ordre de PULL_TABLES).
 */

/** Ordre sans importance pour l'envoi (le rejeu trie), mais lisible : parents d'abord */
const TABLES_GRAINE = ['user_roles', 'boutiques', 'utilisateurs', 'cash_registers', 'parametres_entreprise', 'user_boutique_assignments'];

const DDL_MARQUEUR = `CREATE TABLE IF NOT EXISTS "sync_graine" (
  "table_name" TEXT PRIMARY KEY,
  "decision"   TEXT NOT NULL,
  "traitee_le" TEXT DEFAULT CURRENT_TIMESTAMP
)`;

async function creerMarqueur(prisma) {
  await prisma.$executeRawUnsafe(DDL_MARQUEUR);
}

async function tablesTraitees(prisma) {
  try {
    const r = await prisma.$queryRawUnsafe('SELECT "table_name" AS t FROM "sync_graine"');
    return new Set(r.map((x) => x.t));
  } catch (_) {
    return new Set();
  }
}

async function marquer(prisma, table, decision) {
  await prisma.$executeRawUnsafe(
    'INSERT INTO "sync_graine" ("table_name", "decision") VALUES (?, ?) ON CONFLICT("table_name") DO UPDATE SET "decision" = excluded."decision"',
    table, decision
  );
}

/** Colonnes réellement présentes dans la table du cloud (une colonne purement locale ferait échouer l'insertion) */
async function colonnesCloud(client, table) {
  const r = await client.query(
    "SELECT column_name FROM information_schema.columns WHERE table_schema = 'public' AND table_name = $1",
    [table]
  );
  return new Set(r.rows.map((x) => x.column_name));
}

const num = (v) => (typeof v === 'bigint' ? Number(v) : v);

/**
 * Reste-t-il une table de base à examiner ? (vérification purement locale : évite d'ouvrir une connexion au cloud à
 * chaque cycle une fois la graine traitée)
 */
async function resteAFaire(prisma) {
  await creerMarqueur(prisma);
  const faites = await tablesTraitees(prisma);
  for (const table of TABLES_GRAINE) {
    if (faites.has(table)) continue;
    try {
      const r = await prisma.$queryRawUnsafe(`SELECT COUNT(*) AS n FROM "${table}"`);
      if (Number(num(r[0].n)) > 0) return true;
    } catch (_) { /* table locale absente */ }
  }
  return false;
}

/**
 * Envoie la graine d'un cloud neuf. Idempotent : les tables déjà traitées sont ignorées.
 *
 * @param {{prisma:Object, client:Object, enqueue:Function, log?:Function}} p
 *   enqueue(table, 'INSERT', ligne) : journalise l'envoi
 * @returns {Promise<{envoyees:number, tables:Object}>} tables : { nom: 'envoyee' | 'cloud_non_vide' | 'rien_en_local' }
 */
async function pousserGraineSiCloudVide({ prisma, client, enqueue, log = () => {} }) {
  await creerMarqueur(prisma);
  const faites = await tablesTraitees(prisma);
  const resultat = { envoyees: 0, tables: {} };

  for (const table of TABLES_GRAINE) {
    if (faites.has(table)) continue;

    let locales;
    try {
      locales = await prisma.$queryRawUnsafe(`SELECT * FROM "${table}"`);
    } catch (_) {
      continue; // table locale absente (ancienne version) : rien à envoyer
    }
    if (!locales.length) { resultat.tables[table] = 'rien_en_local'; continue; } // on retentera : le poste n'a peut-être pas fini de démarrer

    let nbCloud;
    try {
      nbCloud = Number((await client.query(`SELECT COUNT(*)::int AS n FROM "${table}"`)).rows[0].n);
    } catch (e) {
      if (/does not exist/i.test(e.message)) continue; // table absente du cloud : on retentera plus tard
      throw e; // coupure : le cycle suivant reprendra
    }

    if (nbCloud > 0) {
      await marquer(prisma, table, 'cloud_non_vide');
      resultat.tables[table] = 'cloud_non_vide';
      continue;
    }

    const colonnes = await colonnesCloud(client, table);
    for (const l of locales) {
      const ligne = {};
      for (const [k, v] of Object.entries(l)) if (colonnes.has(k)) ligne[k] = num(v);
      await enqueue(table, 'INSERT', ligne);
      resultat.envoyees++;
    }
    await marquer(prisma, table, 'envoyee');
    resultat.tables[table] = 'envoyee';
    log(`🌱 Données de base : ${locales.length} ligne(s) de ${table} envoyée(s) vers le cloud (cloud neuf)`);
  }
  return resultat;
}

module.exports = { TABLES_GRAINE, creerMarqueur, resteAFaire, pousserGraineSiCloudVide };
