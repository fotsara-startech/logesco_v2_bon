import 'package:flutter_test/flutter_test.dart';
import 'package:logesco_v2/core/utils/pdf_text.dart';

void main() {
  test('les caractères hors Latin-1 sont remplacés (plus de carrés vides dans le PDF)', () {
    expect(pdfSafeText('Approvisionnement de 50000 FCFA — Pour la construction'), 'Approvisionnement de 50000 FCFA - Pour la construction');
    expect(pdfSafeText('l’avance “utilisée”… 5 – 6'), 'l\'avance "utilisée"... 5 - 6');
    expect(pdfSafeText('prix TTC'), 'prix TTC'); // espace insécable : dans Latin-1, conservé
    expect(pdfSafeText('cœur 10 €'), 'coeur 10 EUR');
    expect(pdfSafeText('日本'), '??');
  });

  test('les lettres accentuées usuelles sont conservées', () {
    const t = 'Dépôt réglé à l\'équipe : ça marche, Élodie, Noël, naïve, où';
    expect(pdfSafeText(t), t);
  });

  test('pdfSafeData : nettoie toute la structure, garde nombres et types de Map', () {
    final r = pdfSafeData({
      'client': {'nomComplet': 'Jean — Paul'},
      'transactions': [
        {'description': 'a – b', 'montant': 1200.5, 'isCredit': true, 'ref': null},
      ],
    }) as Map<String, dynamic>;
    expect((r['client'] as Map<String, dynamic>)['nomComplet'], 'Jean - Paul');
    final t = (r['transactions'] as List<dynamic>).first as Map<String, dynamic>;
    expect(t['description'], 'a - b');
    expect(t['montant'], 1200.5);
    expect(t['isCredit'], true);
    expect(t['ref'], isNull);
  });
}
