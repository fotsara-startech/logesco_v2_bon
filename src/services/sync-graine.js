/**
 * Données locales d'un poste que le cloud n'a jamais reçues : données de base du premier poste (« graine ») et
 * historique d'un poste qui a travaillé SANS cloud avant d'y être relié.
 *
 * Défauts corrigés :
 *  - n°9 : le rôle, l'utilisateur, la boutique, la caisse et les paramètres du premier poste sont créés au premier
 *    démarrage sans passer par le journal d'envoi, et le script d'installation du cloud n'en insère aucune. Sur un
 *    cloud neuf, ils n'arrivaient jamais ; les lignes qui en dépendent (stock par boutique, ventes, sessions de caisse)
 *    étaient refusées par clé étrangère ;
 *  - n°10 : un poste démarré sans cloud ne journalise rien (mode 100 % local). Relié ensuite, il n'envoyait jamais ses
 *    produits, ses ventes, etc.
 *
 * Règle (sans risque pour un client établi), table par table :
 *  - si le cloud n'a AUCUNE ligne dans la table et que le poste en a : on journalise un INSERT par ligne locale qui n'a
 *    encore aucune entrée de journal, par lots, jusqu'à épuisement. La décision est mémorisée (table locale
 *    `sync_graine`, état « en_cours ») pour que l'envoi se poursuive même quand la table du cloud commence à se remplir ;
 *  - si le cloud a déjà des lignes dans la table : on n'envoie rien et on n'y revient plus (un poste qui rejoint un cloud
 *    alimenté par d'autres est traité par la fusion sur clé naturelle, qui ne doit pas être court-circuitée ; et ses
 *    identifiants peuvent chevaucher ceux d'un autre poste : c'est une décision humaine, le contrôle d'écart la signale).
 *
 * Le rejeu des opérations range déjà les tables parents avant les enfants (ordre de PULL_TABLES).
 */

/** Données de base : ordre sans importance pour l'envoi (le rejeu trie), mais lisible : parents d'abord */
const TABLES_GRAINE = ['user_roles', 'boutiques', 'utilisateurs', 'cash_registers', 'parametres_entreprise', 'user_boutique_assignments'];

const LOT_PAR_DEFAUT = 1000;

const DDL_MARQUEUR = `CREATE TABLE IF NOT EXISTS "sync_graine" (
  "table_name" TEXT PRIMARY KEY,
  "decision"   TEXT NOT NULL,
  "traitee_le" TEXT DEFAULT CURRENT_TIMESTAMP
)`;

/** États terminés : on n'y revient plus */
const TERMINES = new Set(['envoyee', 'cloud_non_vide']);

async function creerMarqueur(prisma) {
  await prisma.$executeRawUnsafe(DDL_MARQUEUR);
  // Les sélections « lignes sans journal » interrogent le journal par (table, ligne) : sans cet index, chaque ligne
  // provoquerait un parcours de tout le journal.
  try {
    await prisma.$executeRawUnsafe('CREATE INDEX IF NOT EXISTS "idx_operation_log_table_record" ON "operation_log" ("table_name", "record_id")');
  } catch (_) { /* journal absent : rien à indexer */ }
}

async function etatsDesTables(prisma) {
  try {
    const r = await prisma.$queryRawUnsafe('SELECT "table_name" AS t, "decision" AS d FROM "sync_graine"');
    return new Map(r.map((x) => [x.t, x.d]));
  } catch (_) {
    return new Map();
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

async function compter(prisma, table) {
  const r = await prisma.$queryRawUnsafe(`SELECT COUNT(*) AS n FROM "${table}"`);
  return Number(num(r[0].n));
}

/**
 * Reste-t-il une table à examiner ? (vérification purement locale : évite d'ouvrir une connexion au cloud à chaque cycle
 * une fois tout traité)
 */
async function resteAFaire(prisma, tables = TABLES_GRAINE) {
  await creerMarqueur(prisma);
  const etats = await etatsDesTables(prisma);
  for (const table of tables) {
    const etat = etats.get(table);
    if (etat && TERMINES.has(etat)) continue;
    if (etat === 'en_cours') return true;
    try {
      if ((await compter(prisma, table)) > 0) return true;
    } catch (_) { /* table locale absente */ }
  }
  return false;
}

/**
 * Journalise l'envoi des données locales jamais envoyées vers un cloud qui n'a pas encore la table. Idempotent et
 * reprenable : les tables terminées sont ignorées, une table « en_cours » continue au lot suivant.
 *
 * @param {{prisma:Object, client:Object, enqueue:Function, log?:Function, tables?:string[], lot?:number}} p
 *   enqueue(table, 'INSERT', ligne) : journalise l'envoi
 * @returns {Promise<{envoyees:number, tables:Object}>} tables : { nom: 'envoyee' | 'en_cours' | 'cloud_non_vide' | 'rien_en_local' }
 */
async function pousserGraineSiCloudVide({ prisma, client, enqueue, log = () => {}, tables = TABLES_GRAINE, lot = LOT_PAR_DEFAUT }) {
  await creerMarqueur(prisma);
  const etats = await etatsDesTables(prisma);
  const resultat = { envoyees: 0, tables: {} };

  for (const table of tables) {
    let etat = etats.get(table);
    if (etat && TERMINES.has(etat)) continue;

    if (etat !== 'en_cours') {
      let nbLocal;
      try {
        nbLocal = await compter(prisma, table);
      } catch (_) {
        continue; // table locale absente (ancienne version) : rien à envoyer
      }
      if (nbLocal === 0) { resultat.tables[table] = 'rien_en_local'; continue; } // on retentera : le poste n'a peut-être pas fini de démarrer

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
      // Décision mémorisée AVANT d'envoyer : la table du cloud va se remplir, ce qui ne doit pas arrêter l'envoi
      await marquer(prisma, table, 'en_cours');
      etat = 'en_cours';
    }

    let lignes;
    try {
      lignes = await prisma.$queryRawUnsafe(
        `SELECT t.* FROM "${table}" t
          WHERE NOT EXISTS (SELECT 1 FROM operation_log o WHERE o.table_name = ? AND o.record_id = t.id)
          ORDER BY t.id LIMIT ?`,
        table, lot
      );
    } catch (_) {
      continue; // table ou journal absent
    }

    if (lignes.length === 0) {
      await marquer(prisma, table, 'envoyee');
      resultat.tables[table] = 'envoyee';
      continue;
    }

    const colonnes = await colonnesCloud(client, table);
    for (const l of lignes) {
      const ligne = {};
      for (const [k, v] of Object.entries(l)) if (colonnes.has(k)) ligne[k] = num(v);
      await enqueue(table, 'INSERT', ligne);
      resultat.envoyees++;
    }
    if (lignes.length < lot) {
      await marquer(prisma, table, 'envoyee');
      resultat.tables[table] = 'envoyee';
    } else {
      resultat.tables[table] = 'en_cours'; // lot suivant au prochain cycle
    }
    log(`🌱 Données locales : ${lignes.length} ligne(s) de ${table} mise(s) en file d'envoi vers le cloud (la table y est vide)`);
  }
  return resultat;
}

module.exports = { TABLES_GRAINE, creerMarqueur, resteAFaire, pousserGraineSiCloudVide };
