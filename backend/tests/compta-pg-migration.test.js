/**
 * Migrations Neon (PostgreSQL) du module comptable : exécutables et rejouables sans erreur, tables et contraintes présentes.
 * Ne s'exécute que si COMPTA_TEST_PG_URL est défini (voir scripts/compta-test-postgres.js) ; travaille dans un schéma isolé.
 */
const test = require('node:test');
const assert = require('node:assert');
const { Client } = require('pg');
const { urlDirecte } = require('./helpers/base-compta');

const url = process.env.COMPTA_TEST_PG_URL;
const schema = `t_mig_${Date.now().toString(36)}${Math.random().toString(36).slice(2, 6)}`;
let client;

test.before(async () => {
  if (!url) return;
  client = new Client({ connectionString: urlDirecte(url), ssl: { rejectUnauthorized: false } });
  await client.connect();
  await client.query(`CREATE SCHEMA "${schema}"`);
  await client.query(`SET search_path TO "${schema}"`);
});

test.after(async () => {
  if (!client) return;
  try { await client.query(`DROP SCHEMA IF EXISTS "${schema}" CASCADE`); } finally { await client.end(); }
});

test('socle et immobilisations : exécutables, rejouables, contraintes actives', { skip: !url && 'COMPTA_TEST_PG_URL non défini' }, async () => {
  const socle = require('../src/services/compta-schema-pg');
  const immos = require('../src/services/compta-schema-pg-immobilisations');
  const audit = require('../src/services/compta-schema-pg-audit');
  for (let i = 0; i < 2; i += 1) { // deux passages : idempotence
    await client.query(socle);
    await client.query(immos);
    await client.query(audit);
  }
  const tables = (await client.query('select table_name from information_schema.tables where table_schema = $1 order by 1', [schema])).rows.map((r) => r.table_name);
  for (const t of ['compta_exercices', 'compta_periodes', 'compta_comptes', 'compta_journaux', 'compta_ecritures', 'compta_lignes', 'compta_parametres', 'compta_immobilisations', 'compta_audit']) {
    assert.ok(tables.includes(t), `table ${t} absente`);
  }
  await client.query("insert into compta_comptes (numero, libelle, classe, nature) values ('571', 'Caisse', 5, 'tresorerie')");
  await assert.rejects(client.query("insert into compta_comptes (numero, libelle, classe, nature) values ('571', 'Doublon', 5, 'tresorerie')"), /unique|duplicate/i);
  await client.query("insert into compta_exercices (libelle, date_debut, date_fin) values ('2027', '2027-01-01', '2027-12-31')");
  await client.query("insert into compta_journaux (code, libelle, type) values ('OD', 'Opérations diverses', 'od')");
  await client.query("insert into compta_ecritures (exercice_id, journal_id, date_ecriture, libelle, origine) values (1, 1, '2027-03-01', 'x', 'manuelle')");
  await assert.rejects(client.query('insert into compta_lignes (ecriture_id, compte_id, debit, credit) values (1, 1, 5, 5)'), /check/i, 'débit et crédit sur une même ligne refusés');
  await assert.rejects(client.query('insert into compta_lignes (ecriture_id, compte_id, debit, credit) values (1, 1, -5, 0)'), /check/i, 'montant négatif refusé');
  await client.query('insert into compta_lignes (ecriture_id, compte_id, debit, credit) values (1, 1, 5, 0)');
  await client.query('delete from compta_ecritures where id = 1');
  const restantes = (await client.query('select count(*)::int n from compta_lignes')).rows[0].n;
  assert.strictEqual(restantes, 0, 'les lignes suivent leur écriture (suppression en cascade)');
});
