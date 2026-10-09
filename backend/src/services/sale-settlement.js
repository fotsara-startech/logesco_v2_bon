/**
 * Règlement d'une vente vis-à-vis du compte client.
 *
 * Le compte client porte UN SEUL solde signé :
 *   solde < 0  → dette du client
 *   solde > 0  → avance (le client a approvisionné son compte)
 *
 * Dette et avance ne coexistent donc jamais : un manque de paiement vient
 * d'abord en déduction de l'avance, et seul le reste devient dette.
 *
 * Fonction pure (aucun accès base) pour pouvoir être testée exhaustivement.
 */

/**
 * @param {Object} p
 * @param {number} p.soldeAvant        solde signé du compte avant la vente (0 si pas de compte)
 * @param {number} p.montantVenteTotal total TTC de la vente (remise déduite, TVA incluse)
 * @param {number} p.montantVerse      espèces données par le client
 * @param {boolean} p.resteVersSolde   true : l'excédent est ajouté au solde au lieu d'être rendu
 * @param {boolean} p.hasClient        false : vente anonyme (ni compte, ni avance, ni solde)
 */
function computeSaleSettlement({ soldeAvant = 0, montantVenteTotal, montantVerse = 0, resteVersSolde = false, hasClient = true }) {
  const solde = hasClient ? Number(soldeAvant) || 0 : 0;
  const dettePrecedente = solde < 0 ? -solde : 0;
  const avanceDisponible = solde > 0 ? solde : 0;

  const montantTotalAPayer = montantVenteTotal + dettePrecedente;

  // L'avance couvre automatiquement ce que les espèces ne couvrent pas de la vente.
  const avanceUtilisee = Math.min(avanceDisponible, Math.max(0, montantVenteTotal - montantVerse));

  // Espèces qui suffisent à tout solder (vente + dette éventuelle − avance utilisée)
  const especesNecessaires = montantTotalAPayer - avanceUtilisee;
  const excedent = Math.max(0, montantVerse - especesNecessaires);

  // Excédent : ajouté au solde du client (pas de monnaie) ou rendu en monnaie.
  const ajouteAuSolde = hasClient && resteVersSolde ? excedent : 0;
  const monnaieARendre = excedent - ajouteAuSolde;

  // Espèces qui RESTENT en caisse (ce qui est donné moins la monnaie rendue)
  const especesConservees = montantVerse - monnaieARendre;

  // Montant réglé au titre de la vente + dette (avance incluse, excédent exclu)
  const montantRegle = Math.min(montantVerse + avanceUtilisee, montantTotalAPayer);
  const montantRestant = montantTotalAPayer - montantRegle;
  const mode = montantRestant > 0 ? 'credit' : 'comptant';

  // Part de CETTE vente effectivement payée (pour le reçu)
  const montantPayePourCetteVente = Math.min(montantVerse + avanceUtilisee, montantVenteTotal);

  // Solde après : ancien solde + espèces conservées − montant de la vente
  const soldeApres = hasClient ? solde + especesConservees - montantVenteTotal : 0;

  return {
    dettePrecedente,
    avanceDisponible,
    avanceUtilisee,
    montantTotalAPayer,
    especesNecessaires,
    excedent,
    ajouteAuSolde,
    monnaieARendre,
    especesConservees,
    montantRegle,
    montantRestant,
    montantPayePourCetteVente,
    mode,
    soldeApres,
  };
}

module.exports = { computeSaleSettlement };
