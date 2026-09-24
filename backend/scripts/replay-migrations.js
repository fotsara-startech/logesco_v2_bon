/**
 * Rejoue manuellement toutes les migrations en attente sur la base d'un
 * poste client, sans attendre qu'il relance l'application.
 *
 * Contexte : sur les postes déjà installés avec une build ancienne,
 * migration-runner.js n'a jamais tourné (ou pas jusqu'au bout) — la table
 * de suivi _app_migrations peut ne pas exister, ou être incomplète. Ce
 * script réutilise migration-runner.js tel quel (même MIGRATION_ORDER,
 * même logique de détection "déjà appliqué" vs "en attente") pour ne
 * jamais diverger du chemin utilisé au démarrage normal du serveur — il
 * ne fait qu'appeler le même code, à la demande, sur une base au choix.
 *
 * Usage (depuis le dossier backend d'une installation cliente, backend
 * arrêté au préalable — le fichier .db ne doit pas être verrouillé) :
 *
 *   node.exe scripts\replay-migrations.js
 *   node.exe scripts\replay-migrations.js "C:\chemin\vers\logesco.db"
 *
 * Sans argument, cible database/logesco.db à côté de ce script (l'
 * emplacement standard dans une installation LOGESCO).
 *
 * Ce script ne fait qu'ajouter les colonnes/tables manquantes : il ne
 * supprime ni ne modifie aucune donnée existante.
 */
const path = require('path');
const fs = require('fs');
const { PrismaClient } = require('@prisma/client');
const migrationRunner = require('../src/services/migration-runner');

async function main() {
  const dbPath = process.argv[2]
    ? path.resolve(process.argv[2])
    : path.join(__dirname, '..', 'database', 'logesco.db');

  if (!fs.existsSync(dbPath)) {
    console.error(`❌ Base introuvable: ${dbPath}`);
    process.exit(1);
  }

  console.log(`📂 Base ciblée: ${dbPath}`);
  console.log(`📋 Migrations connues (MIGRATION_ORDER): ${migrationRunner.MIGRATION_ORDER.length}`);

  const dbUrl = `file:${dbPath.replace(/\\/g, '/')}`;
  const prisma = new PrismaClient({ datasources: { db: { url: dbUrl } } });

  try {
    await migrationRunner.run(prisma, { freshInstall: false });

    const appliedRows = await prisma.$queryRawUnsafe('SELECT name FROM _app_migrations');
    const applied = new Set(appliedRows.map((r) => r.name));
    const stillPending = migrationRunner.MIGRATION_ORDER.filter((name) => !applied.has(name));

    if (stillPending.length > 0) {
      console.warn(`⚠️  ${stillPending.length} migration(s) toujours EN ATTENTE (voir avertissements ci-dessus) :`);
      for (const name of stillPending) console.warn(`   - ${name}`);
      console.warn('⚠️  Base NON à jour — corrigez la cause (dossier prisma/migrations manquant ? base verrouillée ?) puis relancez ce script.');
      process.exitCode = 1;
    } else {
      console.log('✅ Base à jour — toutes les migrations connues sont appliquées.');
    }
  } finally {
    await prisma.$disconnect();
  }
}

main().catch((err) => {
  console.error('❌ Erreur lors du rattrapage des migrations:', err);
  process.exit(1);
});
