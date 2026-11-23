/**
 * Référentiel comptable livré avec l'application : plan comptable SYSCOHADA de
 * départ et journaux.
 *
 * Ces lignes sont IDENTIQUES sur tous les postes (mêmes identifiants), pour que
 * la synchronisation vers Neon ne produise ni doublons ni conflits : un poste
 * qui reçoit d'un autre le compte « 411 » retombe sur la ligne qu'il a déjà.
 * L'identifiant d'un compte système est donc fixe : bande réservée
 * [ID_BASE, ID_BASE + n[ choisie sous la plage du poste 1 (< 10 000 000), au-dessus
 * de ce que les saisies utilisateur atteindront en pratique.
 *
 * RÈGLE d'évolution : on n'insère jamais au milieu de plan-comptable-syscohada.json,
 * on ajoute à la fin (l'id vient de la position).
 */
const plan = require('./plan-comptable-syscohada.json').comptes;

const ID_BASE = 8000000;

const JOURNAUX = [
  ['VT', 'Journal des ventes', 'ventes'],
  ['AC', 'Journal des achats', 'achats'],
  ['CA', 'Journal de caisse', 'caisse'],
  ['BQ', 'Journal de banque et mobile money', 'banque'],
  ['OD', 'Opérations diverses', 'od'],
  ['AN', 'À-nouveaux', 'a_nouveaux'],
];

// Comptes de tiers : rattachés à un client ou à un fournisseur dans les écritures, lettrables
const COLLECTIFS = new Set(['401', '411', '419', '4191', '4091']);
const LETTRABLES = new Set(['401', '411', '419', '4191', '4091', '421', '422', '431', '4711', '4712']);

function parentDe(numero, numeros) {
  for (let l = numero.length - 1; l >= 2; l--) {
    const candidat = numero.slice(0, l);
    if (numeros.has(candidat)) return candidat;
  }
  return null;
}

/** Lignes prêtes à insérer pour compta_comptes */
function comptesSysteme() {
  const numeros = new Set(plan.map((c) => c[0]));
  return plan.map(([numero, libelle, nature, sens], i) => ({
    id: ID_BASE + i + 1,
    numero,
    libelle,
    classe: Number(numero[0]),
    nature,
    sens,
    parentNumero: parentDe(numero, numeros),
    estCollectif: COLLECTIFS.has(numero),
    lettrable: LETTRABLES.has(numero),
    systeme: true,
    actif: true,
  }));
}

/** Lignes prêtes à insérer pour compta_journaux */
function journauxSysteme() {
  return JOURNAUX.map(([code, libelle, type], i) => ({ id: ID_BASE + i + 1, code, libelle, type }));
}

/**
 * Charge le référentiel s'il manque. Ne modifie jamais une ligne existante
 * (l'utilisateur peut avoir renommé un compte). Sans effet sur les tables déjà remplies.
 * Les lignes ne passent PAS par la file de synchronisation : chaque poste les crée à l'identique.
 */
async function ensureReferentiel(prisma) {
  // SQLite ne gère pas createMany({ skipDuplicates }) : on filtre à la main (id OU numéro/code déjà présent)
  const comptesExistants = await prisma.comptaCompte.findMany({ select: { id: true, numero: true } });
  const ids = new Set(comptesExistants.map((c) => c.id));
  const numeros = new Set(comptesExistants.map((c) => c.numero));
  const comptes = await prisma.comptaCompte.createMany({
    data: comptesSysteme().filter((c) => !ids.has(c.id) && !numeros.has(c.numero)),
  });
  const journauxExistants = await prisma.comptaJournal.findMany({ select: { id: true, code: true } });
  const idsJ = new Set(journauxExistants.map((j) => j.id));
  const codes = new Set(journauxExistants.map((j) => j.code));
  const journaux = await prisma.comptaJournal.createMany({
    data: journauxSysteme().filter((j) => !idsJ.has(j.id) && !codes.has(j.code)),
  });
  const param = await prisma.comptaParametres.findUnique({ where: { id: 1 } });
  if (!param) await prisma.comptaParametres.create({ data: { id: 1 } });
  return { comptes: comptes.count, journaux: journaux.count };
}

module.exports = { ID_BASE, comptesSysteme, journauxSysteme, ensureReferentiel };
