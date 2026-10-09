import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:logesco_v2/features/customers/services/statement_pdf_service.dart';

/// Texte lisible du PDF : décompresse les flux Flate et récupère les chaînes
/// des opérateurs Tj/TJ (polices standard, donc texte littéral).
String _pdfText(List<int> bytes) {
  final raw = latin1.decode(bytes, allowInvalid: true);
  final out = StringBuffer();
  final re = RegExp(r'stream\r?\n');
  var pos = 0;
  while (true) {
    final m = re.matchAsPrefix(raw, raw.indexOf('stream', pos) < 0 ? raw.length : raw.indexOf('stream', pos));
    final s = raw.indexOf('stream', pos);
    if (s < 0) break;
    final start = raw.indexOf('\n', s) + 1;
    final end = raw.indexOf('endstream', start);
    if (end < 0) break;
    try {
      out.writeln(latin1.decode(zlib.decode(bytes.sublist(start, end)), allowInvalid: true));
    } catch (_) {}
    pos = end + 9;
    if (m == null && s < 0) break;
  }
  return out.toString();
}

Map<String, dynamic> _data(int n) => {
      'entreprise': {'nom': 'LAURY EVENT SA'},
      'client': {'nomComplet': 'FOTSARA'},
      'compte': {'soldeActuel': -4000.0, 'aDette': true},
      'transactions': List.generate(
        n,
        (i) => {
              'id': i,
              'typeTransaction': 'achat_credit',
              'typeTransactionDetail': 'achat_credit',
              'montant': 1000.0 + i,
              'description': 'TRX-MARQUEUR-$i',
              'dateTransaction': '2026-10-08T10:00:00.000Z',
              'soldeApres': -1000.0 * i,
              'venteReference': null,
              'isCredit': false,
            },
      ),
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final n in [3, 22, 100]) {
    test('relevé avec $n transactions : toutes les lignes sont dans le PDF', () async {
      final bytes = await StatementPdfService.generateStatementPDF(_data(n));
      final text = _pdfText(bytes);
      final found = List.generate(n, (i) => i).where((i) => text.contains('TRX-MARQUEUR-$i)')).length;
      final pages = RegExp(r'/Type\s*/Page\b').allMatches(latin1.decode(bytes, allowInvalid: true)).length;
      // ignore: avoid_print
      print('>>> n=$n lignes trouvées=$found pages=$pages');
      expect(found, n);
    });
  }

  test('un dépôt (approvisionnement) est affiché en crédit (+) avec son libellé', () async {
    final data = _data(0);
    data['transactions'] = [
      {
        'id': 1,
        'typeTransaction': 'depot',
        'typeTransactionDetail': 'depot_avance',
        'montant': 20000.0,
        'description': null,
        'dateTransaction': '2026-10-09T10:00:00.000Z',
        'soldeApres': 20000.0,
        'venteReference': null,
        // le serveur marque le dépôt comme crédit
        'isCredit': true,
      },
    ];
    final text = _pdfText(await StatementPdfService.generateStatementPDF(data));
    // le PDF écrit chaque mot séparément : (+20000) puis (F), (Approvisionnement) (du) (compte)
    expect(text, contains('[(+20000)]TJ'));
    expect(text, contains('[(Approvisionnement)]TJ'));
  });
}
