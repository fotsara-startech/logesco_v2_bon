/**
 * Chiffres de ventes du tableau de bord (aujourd'hui, semaine, mois, 7 derniers jours).
 *
 * POURQUOI PAS un simple `dateVente: { gte: ... }` : dans une base SQLite, la date d'une vente peut être stockée en
 * TEXTE ('2026-07-29T07:23:14.208Z' ou '2026-07-29 07:23:14') alors que l'ORM envoie la date de départ sous forme de
 * NOMBRE (millisecondes). SQLite classe tout texte au-dessus de tout nombre : le filtre `>=` laissait donc passer TOUTES
 * les ventes (30 ventes affichées pour aujourd'hui, la semaine et le mois) et le filtre `<` n'en laissait passer aucune.
 *
 * Le filtre de l'ORM ne sert donc plus qu'à ÉCARTER LARGEMENT (il ne peut qu'en laisser passer trop, jamais en perdre),
 * et la vraie comparaison de dates est faite ici, sur les dates lues par l'ORM (qui sait relire les deux formats).
 * Fonctionne à l'identique sur SQLite (poste) et PostgreSQL (cloud).
 */

/** Ventes dont la date est >= depuis : [{ date: Date, montant: number }] */
async function ventesDepuis(prisma, baseWhere, depuis) {
  const lignes = await prisma.vente.findMany({
    where: { ...baseWhere, dateVente: { gte: depuis } },
    select: { dateVente: true, montantTotal: true },
  });
  const debut = depuis.getTime();
  return lignes
    .map((l) => ({ date: new Date(l.dateVente), montant: Number(l.montantTotal) || 0 }))
    .filter((l) => !Number.isNaN(l.date.getTime()) && l.date.getTime() >= debut);
}

const somme = (lignes) => lignes.reduce((t, l) => t + l.montant, 0);
const entre = (lignes, debut, fin) => lignes.filter((l) => l.date >= debut && (fin === null || l.date < fin));

/** Début du jour (minuit, heure du poste) */
const debutDuJour = (d) => new Date(d.getFullYear(), d.getMonth(), d.getDate(), 0, 0, 0, 0);

/** Début de la semaine = dimanche (convention déjà utilisée par le tableau de bord) */
function debutDeSemaine(maintenant) {
  const jour = debutDuJour(maintenant);
  jour.setDate(jour.getDate() - jour.getDay());
  return jour;
}

/** Ventes d'aujourd'hui, de la semaine et du mois : { todaySales, todayRevenue, weekSales, ... } */
async function statistiquesVentes(prisma, baseWhere, maintenant = new Date()) {
  const aujourdhui = debutDuJour(maintenant);
  const semaine = debutDeSemaine(maintenant);
  const mois = new Date(maintenant.getFullYear(), maintenant.getMonth(), 1, 0, 0, 0, 0);

  const plusAncien = new Date(Math.min(aujourdhui.getTime(), semaine.getTime(), mois.getTime()));
  const lignes = await ventesDepuis(prisma, baseWhere, plusAncien);

  const j = entre(lignes, aujourdhui, null);
  const s = entre(lignes, semaine, null);
  const m = entre(lignes, mois, null);
  return {
    todaySales: j.length, todayRevenue: somme(j),
    weekSales: s.length, weekRevenue: somme(s),
    monthSales: m.length, monthRevenue: somme(m),
  };
}

/** Ventes des `jours` derniers jours (aujourd'hui inclus), jour par jour : [{ date: 'AAAA-MM-JJ', sales, revenue }] */
async function ventesParJour(prisma, baseWhere, maintenant = new Date(), jours = 7) {
  const premier = debutDuJour(maintenant);
  premier.setDate(premier.getDate() - (jours - 1));
  const lignes = await ventesDepuis(prisma, baseWhere, premier);

  const resultat = [];
  for (let i = 0; i < jours; i++) {
    const debut = new Date(premier);
    debut.setDate(premier.getDate() + i);
    const fin = new Date(debut);
    fin.setDate(debut.getDate() + 1);
    const duJour = entre(lignes, debut, fin);
    resultat.push({ date: debut.toISOString().split('T')[0], sales: duJour.length, revenue: somme(duJour) });
  }
  return resultat;
}

module.exports = { ventesDepuis, statistiquesVentes, ventesParJour, debutDeSemaine };
