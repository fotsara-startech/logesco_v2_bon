/**
 * Annule les opérations de synchronisation (operation_log) bloquées en
 * boucle parce qu'elles appartiennent à une ANCIENNE identité de poste —
 * typiquement un poste de test réinitialisé/réinstallé plusieurs fois, qui a
 * reçu un nouveau numéro à chaque fois sans repartir d'une base vide. Leur
 * parent (session de caisse, caisse...) n'a jamais été synchronisé sous
 * l'ancienne identité et ne le sera jamais : chaque tentative de replay
 * échoue indéfiniment sur une contrainte de clé étrangère.
 *
 * Ce script ne touche QUE le journal local (operation_log) : il marque ces
 * opérations comme "cancelled" (elles ne seront plus retentées), sans
 * supprimer ni modifier aucune donnée métier, et SANS jamais se connecter à
 * Neon. Totalement local, sans risque pour la base cloud partagée.
 *
 * À lancer avec l'application LOGESCO complètement fermée (le fichier
 * SQLite ne doit pas être ouvert par un autre processus).
 *
 * Utilisation :
 *   node scripts/clear-stale-sync-queue.js                          (base locale par défaut, .env)
 *   node scripts/clear-stale-sync-queue.js --db "C:\chemin\vers\logesco.db"
 *   node scripts/clear-stale-sync-queue.js --dry-run                (affiche seulement, ne modifie rien)
 */
const path = require('path');
const { PrismaClient } = require('@prisma/client');

const ID_BLOCK_SIZE = 10000000; // doit rester identique à src/utils/installation.js

function parseArgs() {
  const args = process.argv.slice(2);
  const dbIndex = args.indexOf('--db');
  const dbPath = dbIndex !== -1 ? args[dbIndex + 1] : null;
  const dryRun = args.includes('--dry-run');
  return { dbPath, dryRun };
}

async function main() {
  const { dbPath, dryRun } = parseArgs();

  const prisma = dbPath
    ? new PrismaClient({ datasources: { db: { url: `file:${path.resolve(dbPath)}` } } })
    : new PrismaClient();

  try {
    const identityRows = await prisma.$queryRawUnsafe(
      `SELECT installation_id FROM sync_identity WHERE id = 1`
    );
    if (!identityRows.length) {
      console.log('❌ Table sync_identity introuvable ou vide — ce poste n\'a pas encore d\'identité enregistrée. Rien à faire.');
      return;
    }
    const idPoste = Number(identityRows[0].installation_id);
    const debutActuel = idPoste * ID_BLOCK_SIZE;
    console.log(`ℹ️  Poste actuel : n°${idPoste} (plage à partir de ${debutActuel})`);

    // Plage [10 000 000, debutActuel[ : anciennes identités de CE poste
    // (poste 1, en dessous de 10 000 000, est la base historique pré-blocs et n'est jamais touchée)
    const candidats = await prisma.$queryRawUnsafe(
      `SELECT operation_id, table_name, operation_type, record_id, timestamp, error_message
         FROM operation_log
        WHERE status IN ('pending', 'failed')
          AND record_id >= ${ID_BLOCK_SIZE} AND record_id < ${debutActuel}
        ORDER BY table_name, record_id`
    );

    if (candidats.length === 0) {
      console.log('✅ Aucune opération bloquée appartenant à une ancienne identité de ce poste.');
      return;
    }

    console.log(`\n🔍 ${candidats.length} opération(s) en attente/échouée(s) appartenant à une ancienne identité de ce poste :\n`);
    const parTable = {};
    for (const op of candidats) {
      parTable[op.table_name] = (parTable[op.table_name] || 0) + 1;
    }
    for (const [table, count] of Object.entries(parTable)) {
      console.log(`   - ${table}: ${count}`);
    }

    if (dryRun) {
      console.log('\n🧪 --dry-run : aucune modification effectuée.');
      return;
    }

    const ids = candidats.map((c) => c.operation_id);
    // SQLite : pas de limite de paramètres problématique ici (quelques dizaines/centaines au plus)
    const placeholders = ids.map(() => '?').join(',');
    await prisma.$executeRawUnsafe(
      `UPDATE operation_log SET status = 'cancelled', error_message = 'Ancienne identité de poste — abandonné (clear-stale-sync-queue.js)'
        WHERE operation_id IN (${placeholders})`,
      ...ids
    );

    console.log(`\n✅ ${ids.length} opération(s) marquée(s) comme annulée(s). Elles ne seront plus retentées.`);
  } finally {
    await prisma.$disconnect();
  }
}

main().catch((e) => {
  console.error('❌ Erreur:', e.message);
  process.exit(1);
});
