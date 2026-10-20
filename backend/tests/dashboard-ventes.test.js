/**
 * Chiffres de ventes du tableau de bord sur une VRAIE base SQLite où les dates sont stockées en texte et/ou en nombre.
 *
 * Cas réel (client Smart Energy) : "30 ventes aujourd'hui, 30 cette semaine, 30 ce mois" alors que seules quelques
 * ventes étaient du jour : SQLite classe tout texte au-dessus de tout nombre, le filtre de l'ORM laissait tout passer.
 *
 * Exécution :  node --test tests/dashboard-ventes.test.js
 */
const test = require('node:test');
const assert = require('node:assert');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { execSync } = require('node:child_process');
const { PrismaClient } = require('@prisma/client');
const { statistiquesVentes, ventesParJour } = require('../src/services/dashboard-ventes');

const dossier = fs.mkdtempSync(path.join(os.tmpdir(), 'dash-ventes-'));
const fichier = path.join(dossier, 'essai.db');
const url = `file:${fichier.split(path.sep).join('/')}`;
let prisma;

// "Maintenant" fixe : mardi 20 octobre 2026, 14 h (heure du poste)
const MAINTENANT = new Date(2026, 9, 20, 14, 0, 0);
const local = (a, m, j, h = 10, mi = 0) => new Date(a, m - 1, j, h, mi, 0);

let compteur = 0;
/** Insère une vente avec la date écrite sous la forme voulue : 'iso' (texte ISO), 'sql' (texte AAAA-MM-JJ HH:MM:SS UTC), 'ms' (nombre) */
async function vente(date, forme, montant, statut = 'terminee') {
  compteur++;
  const valeur = forme === 'ms' ? date.getTime() : forme === 'iso' ? date.toISOString() : date.toISOString().replace('T', ' ').replace(/\.\d+Z$/, '');
  await prisma.$executeRawUnsafe(
    `INSERT INTO ventes (numero_vente, date_vente, sous_total, montant_total, statut) VALUES (?, ?, ?, ?, ?)`,
    `V-${compteur}`, valeur, montant, montant, statut,
  );
}

test.before(async () => {
  execSync('npx prisma db push --skip-generate --accept-data-loss', { cwd: path.join(__dirname, '..'), env: { ...process.env, DATABASE_URL: url }, stdio: 'ignore' });
  prisma = new PrismaClient({ datasources: { db: { url } } });

  // Aujourd'hui (mardi 20) : 2 ventes en texte ISO, 1 en texte SQL, 1 en nombre
  await vente(local(2026, 10, 20, 9), 'iso', 1000);
  await vente(local(2026, 10, 20, 11), 'iso', 2000);
  await vente(local(2026, 10, 20, 12), 'sql', 3000);
  await vente(local(2026, 10, 20, 13), 'ms', 4000);
  // Cette semaine (dimanche 18 et lundi 19)
  await vente(local(2026, 10, 19, 15), 'iso', 500);
  await vente(local(2026, 10, 18, 8), 'sql', 600);
  // Ce mois, avant la semaine (5 et 12 octobre)
  await vente(local(2026, 10, 12, 10), 'iso', 10000);
  await vente(local(2026, 10, 5, 10), 'ms', 20000);
  // Mois précédent et bien avant
  await vente(local(2026, 9, 30, 23, 30), 'iso', 100000);
  await vente(local(2026, 6, 1, 10), 'iso', 200000);
  // Annulée aujourd'hui : jamais comptée
  await vente(local(2026, 10, 20, 10), 'iso', 999999, 'annulee');
});

test.after(async () => {
  if (prisma) await prisma.$disconnect();
  fs.rmSync(dossier, { recursive: true, force: true });
});

const base = { statut: { not: 'annulee' } };

test('PREUVE DU DÉFAUT : le filtre de date de l\'ORM laisse passer les ventes dont la date est en texte', async () => {
  const brut = await prisma.vente.count({ where: { ...base, dateVente: { gte: new Date(2026, 9, 20) } } });
  assert.ok(brut > 4, `le filtre brut compte ${brut} ventes pour aujourd'hui alors qu'il y en a 4 (c'est le défaut corrigé par le service)`);
});

test('aujourd\'hui, semaine, mois : chaque période ne compte que ses ventes, quel que soit le format de la date', async () => {
  const s = await statistiquesVentes(prisma, base, MAINTENANT);
  assert.deepStrictEqual([s.todaySales, s.todayRevenue], [4, 10000]);
  assert.deepStrictEqual([s.weekSales, s.weekRevenue], [6, 11100]);
  assert.deepStrictEqual([s.monthSales, s.monthRevenue], [8, 41100]);
});

test('les trois périodes ne sont plus identiques', async () => {
  const s = await statistiquesVentes(prisma, base, MAINTENANT);
  assert.ok(s.todaySales < s.weekSales && s.weekSales < s.monthSales);
});

test('une vente annulée n\'est jamais comptée', async () => {
  const s = await statistiquesVentes(prisma, base, MAINTENANT);
  assert.ok(s.todayRevenue < 999999);
});

test('limite de minuit : 23 h 59 la veille n\'est pas dans aujourd\'hui, minuit pile l\'est', async () => {
  await vente(local(2026, 10, 19, 23, 59), 'iso', 7);
  await vente(new Date(2026, 9, 20, 0, 0, 0), 'iso', 11);
  const s = await statistiquesVentes(prisma, base, MAINTENANT);
  assert.deepStrictEqual([s.todaySales, s.todayRevenue], [5, 10011]);
});

test('graphique des 7 derniers jours : jour par jour, avec des jours à zéro', async () => {
  const jours = await ventesParJour(prisma, base, MAINTENANT, 7);
  assert.strictEqual(jours.length, 7);
  const parDate = Object.fromEntries(jours.map((j) => [j.date, j]));
  const cle = (a, m, j) => new Date(a, m - 1, j).toISOString().split('T')[0];
  assert.strictEqual(parDate[cle(2026, 10, 20)].sales, 5, 'aujourd\'hui (avec la vente de minuit)');
  assert.strictEqual(parDate[cle(2026, 10, 19)].sales, 2);
  assert.strictEqual(parDate[cle(2026, 10, 18)].sales, 1);
  assert.strictEqual(parDate[cle(2026, 10, 17)].sales, 0);
  const total = jours.reduce((t, j) => t + j.sales, 0);
  assert.strictEqual(total, 8, 'les ventes du 12 et du 5 octobre sont hors des 7 jours');
});

test('base sans aucune vente : tout à zéro', async () => {
  const s = await statistiquesVentes(prisma, { ...base, boutiqueId: 99999 }, MAINTENANT);
  assert.deepStrictEqual([s.todaySales, s.weekSales, s.monthSales], [0, 0, 0]);
});
