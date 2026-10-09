import 'package:flutter_test/flutter_test.dart';
import 'package:logesco_v2/features/sales/utils/sale_settlement.dart';

SaleSettlement _s(double solde, double vente, double verse, {bool reste = false, bool client = true}) =>
    SaleSettlement.compute(soldeAvant: solde, venteTotal: vente, montantVerse: verse, resteVersSolde: reste, hasClient: client);

/// Mêmes cas que backend/tests/sale-settlement.test.js : le dialogue doit
/// afficher ce que le serveur appliquera.
void main() {
  test('paiement exact, sans dette ni avance', () {
    final r = _s(0, 10000, 10000);
    expect(r.soldeApres, 0);
    expect(r.isCredit, false);
    expect(r.monnaieARendre, 0);
  });

  test('monnaie rendue : la caisse ne garde que la vente', () {
    final r = _s(0, 1500, 6500);
    expect(r.monnaieARendre, 5000);
    expect(r.especesConservees, 1500);
  });

  test('pas de monnaie : le reste est ajouté au solde du client', () {
    final r = _s(0, 9000, 10000, reste: true);
    expect(r.ajouteAuSolde, 1000);
    expect(r.monnaieARendre, 0);
    expect(r.soldeApres, 1000);
  });

  test('vente anonyme : option ignorée, monnaie rendue', () {
    final r = _s(0, 9000, 10000, reste: true, client: false);
    expect(r.ajouteAuSolde, 0);
    expect(r.monnaieARendre, 1000);
    expect(r.soldeApres, 0);
  });

  test('une avance existante est préservée quand la vente est payée en espèces', () {
    final r = _s(30000, 20000, 20000);
    expect(r.avanceUtilisee, 0);
    expect(r.soldeApres, 30000);
  });

  test('avance qui couvre toute la vente', () {
    final r = _s(30000, 20000, 0);
    expect(r.avanceUtilisee, 20000);
    expect(r.especesConservees, 0);
    expect(r.soldeApres, 10000);
    expect(r.isCredit, false);
  });

  test('avance + complément en espèces', () {
    final r = _s(30000, 50000, 20000);
    expect(r.avanceUtilisee, 30000);
    expect(r.soldeApres, 0);
    expect(r.isCredit, false);
  });

  test('avance et espèces insuffisantes : le reste devient dette', () {
    final r = _s(30000, 50000, 10000);
    expect(r.avanceUtilisee, 30000);
    expect(r.montantRestant, 10000);
    expect(r.soldeApres, -10000);
    expect(r.isCredit, true);
  });

  test('excédent avec avance existante : rendu ou ajouté', () {
    expect(_s(30000, 20000, 25000).soldeApres, 30000);
    expect(_s(30000, 20000, 25000, reste: true).soldeApres, 35000);
  });

  test('dette existante : paiement partiel, soldée avec monnaie, soldée avec reste ajouté', () {
    expect(_s(-10000, 20000, 15000).soldeApres, -15000);
    final solde = _s(-10000, 20000, 40000);
    expect(solde.monnaieARendre, 10000);
    expect(solde.soldeApres, 0);
    expect(_s(-10000, 20000, 40000, reste: true).soldeApres, 10000);
  });

  test('invariant : solde après = solde avant + espèces conservées − vente', () {
    for (final solde in [-30000.0, -5000.0, 0.0, 7000.0, 50000.0]) {
      for (final vente in [1000.0, 20000.0, 60000.0]) {
        for (final verse in [0.0, 500.0, 10000.0, 20000.0, 80000.0, 200000.0]) {
          for (final reste in [false, true]) {
            final r = _s(solde, vente, verse, reste: reste);
            expect(r.soldeApres, closeTo(solde + r.especesConservees - vente, 1e-9), reason: '$solde $vente $verse $reste');
            expect(r.avanceUtilisee, lessThanOrEqualTo(solde > 0 ? solde : 0));
          }
        }
      }
    }
  });
}
