/**
 * Base de test pour les suites comptables qui ont besoin du schéma complet.
 *
 * Par défaut : SQLite temporaire (schéma prisma/schema.prisma).
 * Avec COMPTA_TEST_PG_URL : PostgreSQL, dans un SCHÉMA ISOLÉ créé pour la suite puis supprimé
 * (le schéma « public » de la base n'est jamais touché). Il faut alors aussi COMPTA_PRISMA_CLIENT,
 * chemin du client Prisma généré pour Postgres — voir scripts/compta-test-postgres.js qui prépare tout.
 */
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { execSync } = require('node:child_process');

const RACINE = path.join(__dirname, '..', '..');

function clientPrisma() {
  return process.env.COMPTA_PRISMA_CLIENT ? require(process.env.COMPTA_PRISMA_CLIENT) : require('@prisma/client');
}

const estPostgres = () => Boolean(process.env.COMPTA_TEST_PG_URL);

/** Neon : le point d'entrée « -pooler » (pgbouncer) conserve le search_path d'une connexion à l'autre, ce qui fausse les requêtes des autres clients. On travaille toujours en connexion directe. */
const urlDirecte = (u) => String(u).replace('-pooler', '');

function urlSchema(base, schema) {
  return `${base}${base.includes('?') ? '&' : '?'}schema=${schema}`;
}

/** @returns {{ prisma: object, url: string, postgres: boolean, nettoyer: () => Promise<void> }} */
function creerBaseSync(nom) {
  const { PrismaClient } = clientPrisma();
  if (estPostgres()) {
    const schema = `t_${nom}_${Date.now().toString(36)}${Math.random().toString(36).slice(2, 6)}`;
    const url = urlSchema(urlDirecte(process.env.COMPTA_TEST_PG_URL), schema);
    execSync('npx prisma db push --schema=prisma/schema.postgresql.prisma --skip-generate', {
      cwd: RACINE, env: { ...process.env, DATABASE_URL: url }, stdio: 'pipe',
    });
    const prisma = new PrismaClient({ datasources: { db: { url } } });
    return {
      prisma, url, postgres: true, schema,
      async nettoyer() {
        await prisma.$disconnect();
        const { Client } = require('pg');
        const c = new Client({ connectionString: urlDirecte(process.env.COMPTA_TEST_PG_URL), ssl: { rejectUnauthorized: false } });
        await c.connect();
        try { await c.query(`DROP SCHEMA IF EXISTS "${schema}" CASCADE`); } finally { await c.end(); }
      },
    };
  }
  const dossier = fs.mkdtempSync(path.join(os.tmpdir(), `compta-${nom}-`));
  const url = `file:${path.join(dossier, 'test.db').replace(/\\/g, '/')}`;
  execSync('npx prisma db push --schema=prisma/schema.prisma --skip-generate --accept-data-loss', {
    cwd: RACINE, env: { ...process.env, DATABASE_URL: url }, stdio: 'pipe',
  });
  const prisma = new PrismaClient({ datasources: { db: { url } } });
  return {
    prisma, url, postgres: false,
    async nettoyer() {
      await prisma.$disconnect();
      fs.rmSync(dossier, { recursive: true, force: true });
    },
  };
}

module.exports = { creerBaseSync, clientPrisma, estPostgres, urlSchema, urlDirecte };
