/**
 * Doublons probables entre fiches saisies sur deux postes (clients, fournisseurs, boutiques).
 *
 * Défaut corrigé (mineur) : le même client ou fournisseur saisi sur deux postes devient deux fiches, sans aucun refus
 * du cloud (ces tables n'ont pas de clé unique) et donc sans alerte : deux comptes, deux soldes, personne ne le voit.
 *
 * Ce module ne FUSIONNE RIEN : fusionner deux clients touche à des comptes et à des soldes, c'est une décision humaine.
 * Il rend seulement les doublons VISIBLES : liste des groupes de fiches qui semblent désigner la même personne ou la
 * même boutique, avec de quoi décider (identifiants, solde, date de création).
 *
 * Règles (volontairement prudentes pour éviter les faux positifs) :
 *  - clients et fournisseurs : même nom (et prénom pour un client) ET même téléphone NON VIDE. Deux fiches sans téléphone
 *    ne sont jamais rapprochées (deux homonymes sans téléphone sont plus probablement deux personnes) ;
 *  - boutiques : même nom.
 * Comparaison sans tenir compte des majuscules, des espaces en trop, ni de la forme du numéro (espaces, +, tirets, points).
 */

const num = (v) => (typeof v === 'bigint' ? Number(v) : v);

/** SQL : numéro sans espaces, +, tirets ni points */
const TEL_NORMALISE = (col) => `replace(replace(replace(replace(coalesce(${col}, ''), ' ', ''), '+', ''), '-', ''), '.', '')`;

const REGLES = [
  {
    table: 'clients', libelle: 'Client',
    cle: `lower(trim(coalesce(nom, ''))) || '|' || lower(trim(coalesce(prenom, ''))) || '|' || ${TEL_NORMALISE('telephone')}`,
    exige: `${TEL_NORMALISE('telephone')} <> '' AND trim(coalesce(nom, '')) <> ''`,
    colonnes: 'id, nom, prenom, telephone',
    affiche: (l) => [l.prenom, l.nom].filter(Boolean).join(' ') + (l.telephone ? ` · ${l.telephone}` : ''),
    compte: { table: 'comptes_clients', colonne: 'client_id' },
  },
  {
    table: 'fournisseurs', libelle: 'Fournisseur',
    cle: `lower(trim(coalesce(nom, ''))) || '|' || ${TEL_NORMALISE('telephone')}`,
    exige: `${TEL_NORMALISE('telephone')} <> '' AND trim(coalesce(nom, '')) <> ''`,
    colonnes: 'id, nom, telephone',
    affiche: (l) => l.nom + (l.telephone ? ` · ${l.telephone}` : ''),
    compte: { table: 'comptes_fournisseurs', colonne: 'fournisseur_id' },
  },
  {
    table: 'boutiques', libelle: 'Boutique',
    cle: `lower(trim(coalesce(nom, '')))`,
    exige: `trim(coalesce(nom, '')) <> ''`,
    colonnes: 'id, nom',
    affiche: (l) => l.nom,
    compte: null,
  },
];

/**
 * @param {Object} prisma  accès SQL du poste ($queryRawUnsafe)
 * @returns {Promise<Array<{table:string, libelle:string, nombre:number, fiches:Array<{id:number, libelle:string, solde:(number|null)}>}>>}
 */
async function trouverDoublons(prisma) {
  const groupes = [];
  for (const r of REGLES) {
    let lignes;
    try {
      lignes = await prisma.$queryRawUnsafe(
        `SELECT ${r.colonnes}, ${r.cle} AS cle_doublon FROM "${r.table}" WHERE ${r.exige}`
      );
    } catch (_) {
      continue; // table absente sur ce poste
    }
    const parCle = new Map();
    for (const l of lignes) {
      if (!parCle.has(l.cle_doublon)) parCle.set(l.cle_doublon, []);
      parCle.get(l.cle_doublon).push(l);
    }
    for (const membres of parCle.values()) {
      if (membres.length < 2) continue;
      const fiches = [];
      for (const m of membres) {
        let solde = null;
        if (r.compte) {
          try {
            const c = await prisma.$queryRawUnsafe(
              `SELECT CAST(solde_actuel AS TEXT) AS s FROM "${r.compte.table}" WHERE "${r.compte.colonne}" = ? LIMIT 1`, Number(num(m.id))
            );
            if (c.length) solde = Number(c[0].s);
          } catch (_) { /* pas de compte */ }
        }
        fiches.push({ id: Number(num(m.id)), libelle: r.affiche(m), solde });
      }
      fiches.sort((a, b) => a.id - b.id);
      groupes.push({ table: r.table, libelle: r.libelle, nombre: fiches.length, fiches });
    }
  }
  return groupes;
}

module.exports = { trouverDoublons, REGLES };
