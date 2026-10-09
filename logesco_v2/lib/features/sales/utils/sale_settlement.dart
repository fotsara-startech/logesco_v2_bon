/// Règlement d'une vente vis-à-vis du compte client (avance, dette, monnaie).
///
/// Miroir EXACT de `backend/src/services/sale-settlement.js` : le dialogue de
/// paiement affiche ce que le serveur appliquera réellement. Toute modification
/// des règles doit être faite aux deux endroits (les deux ont leurs tests).
///
/// Le compte client porte UN SEUL solde signé : < 0 dette, > 0 avance.
/// L'avance couvre automatiquement ce que les espèces ne couvrent pas de la
/// vente ; seul le reste devient dette.
class SaleSettlement {
  final double dettePrecedente;
  final double avanceDisponible;
  final double avanceUtilisee;
  final double montantTotalAPayer;
  final double especesNecessaires;
  final double excedent;
  final double ajouteAuSolde;
  final double monnaieARendre;
  final double especesConservees;
  final double montantRestant;
  final double soldeApres;

  const SaleSettlement({
    required this.dettePrecedente,
    required this.avanceDisponible,
    required this.avanceUtilisee,
    required this.montantTotalAPayer,
    required this.especesNecessaires,
    required this.excedent,
    required this.ajouteAuSolde,
    required this.monnaieARendre,
    required this.especesConservees,
    required this.montantRestant,
    required this.soldeApres,
  });

  bool get hasExcedent => excedent > 0;
  bool get isCredit => montantRestant > 0;

  /// [soldeAvant] solde signé du compte avant la vente (0 sans compte)
  /// [venteTotal] total TTC de la vente (remise déduite, TVA incluse)
  /// [montantVerse] espèces données par le client
  /// [resteVersSolde] true : l'excédent est ajouté au solde au lieu d'être rendu
  /// [hasClient] false : vente anonyme (pas d'avance, pas de solde)
  factory SaleSettlement.compute({
    required double soldeAvant,
    required double venteTotal,
    required double montantVerse,
    bool resteVersSolde = false,
    bool hasClient = true,
  }) {
    final solde = hasClient ? soldeAvant : 0.0;
    final dette = solde < 0 ? -solde : 0.0;
    final avance = solde > 0 ? solde : 0.0;

    final totalAPayer = venteTotal + dette;

    final manque = venteTotal - montantVerse;
    final avanceUtilisee = manque > 0 ? (avance < manque ? avance : manque) : 0.0;

    final especesNecessaires = totalAPayer - avanceUtilisee;
    final excedent = montantVerse > especesNecessaires ? montantVerse - especesNecessaires : 0.0;

    final ajoute = (hasClient && resteVersSolde) ? excedent : 0.0;
    final monnaie = excedent - ajoute;
    final conservees = montantVerse - monnaie;

    final regle = (montantVerse + avanceUtilisee) < totalAPayer ? (montantVerse + avanceUtilisee) : totalAPayer;

    return SaleSettlement(
      dettePrecedente: dette,
      avanceDisponible: avance,
      avanceUtilisee: avanceUtilisee,
      montantTotalAPayer: totalAPayer,
      especesNecessaires: especesNecessaires,
      excedent: excedent,
      ajouteAuSolde: ajoute,
      monnaieARendre: monnaie,
      especesConservees: conservees,
      montantRestant: totalAPayer - regle,
      soldeApres: hasClient ? solde + conservees - venteTotal : 0.0,
    );
  }
}
