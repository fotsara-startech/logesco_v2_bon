import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:logesco_v2/core/utils/exceptions.dart';
import 'package:logesco_v2/core/utils/friendly_error.dart';
import 'package:logesco_v2/core/utils/snackbar_helper.dart';

void main() {
  group('les messages réellement affichés sur mobile', () {
    test("« Unexpected token 'T', \"Trop de re\"... is not valid JSON » devient une explication de surcharge", () {
      const brut = "Impossible de charger les alertes: Exception: Erreur de connexion: FormatException: SyntaxError: Unexpected token 'T', \"Trop de re\"... is not valid JSON";
      expect(FriendlyError.nettoyer(brut), 'Impossible de charger les alertes. ${FriendlyError.surcharge}');
    });

    test("« ClientException: Failed to fetch, uri=... » devient « impossible de joindre le serveur », sans l'adresse technique", () {
      const brut =
          'Impossible de charger les alertes: Exception: Erreur de connexion: ClientException: Failed to fetch, uri=https://logesco-smart-energy.onrender.com/api/v1/inventory?page=1&limit=20&alerteStock=true&boutiqueId=1';
      final propre = FriendlyError.nettoyer(brut);
      expect(propre, 'Impossible de charger les alertes. ${FriendlyError.reseau}');
      expect(propre, isNot(contains('onrender')));
      expect(propre, isNot(contains('ClientException')));
    });

    test('« Erreur de communication avec le serveur (429) » : trop de demandes', () {
      expect(FriendlyError.nettoyer('Erreur de communication avec le serveur (429)'), FriendlyError.surcharge);
    });

    test('un message déjà clair, sans cause technique, reste tel quel', () {
      expect(FriendlyError.nettoyer('Impossible de charger le résumé des stocks'), 'Impossible de charger le résumé des stocks');
      expect(FriendlyError.nettoyer('Stock insuffisant pour LUSTRE. Disponible: 2, Demandé: 5'), 'Stock insuffisant pour LUSTRE. Disponible: 2, Demandé: 5');
      expect(FriendlyError.nettoyer('Exception: Cette référence existe déjà'), 'Cette référence existe déjà', reason: 'le préfixe technique « Exception: » disparaît');
    });

    test('un message déjà traduit n\'est pas retraduit en boucle', () {
      expect(FriendlyError.nettoyer(FriendlyError.surcharge), FriendlyError.surcharge);
      final deja = 'Impossible de charger les stocks. ${FriendlyError.reseau}';
      expect(FriendlyError.nettoyer(deja), deja);
    });
  });

  group('autres causes techniques', () {
    test('délai dépassé, réponse illisible, serveur en panne, session, droits', () {
      expect(FriendlyError.nettoyer('TimeoutException after 0:00:30.000000: Future not completed'), FriendlyError.delai);
      expect(FriendlyError.nettoyer('FormatException: Unexpected character (at character 1)'), FriendlyError.reponse);
      expect(FriendlyError.nettoyer('Erreur de communication avec le serveur (502)'), FriendlyError.serveur);
      expect(FriendlyError.nettoyer('ApiException: Erreur (Code: X, Status: 503)'), FriendlyError.serveur);
      expect(FriendlyError.nettoyer('Erreur (Status: 401)'), FriendlyError.session);
      expect(FriendlyError.nettoyer('Erreur (Status: 403)'), FriendlyError.droits);
      expect(FriendlyError.nettoyer('SocketException: Failed host lookup'), FriendlyError.reseau);
    });

    test('chaque message dit quoi faire (aucun jargon, une action)', () {
      for (final m in [FriendlyError.surcharge, FriendlyError.reseau, FriendlyError.delai, FriendlyError.reponse, FriendlyError.serveur, FriendlyError.session]) {
        expect(m, matches(RegExp(r'(réessayez|Reconnectez|Patientez|contactez)', caseSensitive: false)), reason: m);
        expect(m.toLowerCase(), isNot(anyOf(contains('exception'), contains('json'), contains('syntaxerror'), contains('http'))));
      }
    });
  });

  group('message() depuis une erreur', () {
    test('ApiException : le code HTTP prime sur le texte', () {
      final e = ApiException(message: 'Erreur inconnue', code: 'X', statusCode: 429);
      expect(FriendlyError.message(e), FriendlyError.surcharge);
      expect(FriendlyError.message(e, contexte: 'Impossible de charger les ventes'), 'Impossible de charger les ventes. ${FriendlyError.surcharge}');
    });

    test('ApiException métier (400, 404...) : le message du serveur est conservé', () {
      final e = ApiException(message: 'Produit introuvable', code: 'NOT_FOUND', statusCode: 404);
      expect(FriendlyError.message(e), 'Produit introuvable');
    });

    test('erreur quelconque et erreur vide', () {
      expect(FriendlyError.message(Exception('ClientException: Failed to fetch')), FriendlyError.reseau);
      expect(FriendlyError.message(null), isNotEmpty);
    });
  });

  group('exceptions HTTP : réponse qui n\'est pas du JSON', () {
    // simule ce que renvoyait l'ancien limiteur : du texte brut avec le code 429
    ApiException depuis(int statut, String corps, {Map<String, String> entetes = const {}}) =>
        ApiException.fromResponse(http.Response(corps, statut, headers: entetes));

    test('texte brut en 429 : code RATE_LIMITED, message lisible, délai conseillé lu', () {
      final e = depuis(429, 'Trop de requêtes, veuillez réessayer plus tard.', entetes: {'retry-after': '42'});
      expect(e.code, 'RATE_LIMITED');
      expect(e.message, FriendlyError.surcharge);
      expect(e.retryAfterSeconds, 42);
    });

    test('page d\'erreur HTML d\'un proxy en 502 : message de panne passagère', () {
      expect(depuis(502, '<html><body>Bad Gateway</body></html>').message, FriendlyError.serveur);
    });

    test('nouveau format JSON du serveur : message, code et délai repris', () {
      final e = depuis(429, '{"success":false,"message":"Trop de requêtes en peu de temps. Patientez quelques instants puis réessayez.","code":"RATE_LIMITED","retryAfterSeconds":30}');
      expect(e.message, contains('Patientez'));
      expect(e.retryAfterSeconds, 30);
    });
  });

  group('affichage des erreurs', () {
    Future<void> ouvrir(WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(scaffoldMessengerKey: rootScaffoldMessengerKey, home: const Scaffold(body: SizedBox())));
    }

    testWidgets("l'erreur technique est traduite avant d'être montrée", (tester) async {
      await ouvrir(tester);
      SnackbarHelper.error("Impossible de charger les alertes: Exception: Erreur de connexion: FormatException: SyntaxError: Unexpected token 'T', \"Trop de re\"... is not valid JSON");
      await tester.pump();
      expect(find.textContaining('trop de demandes'), findsOneWidget);
      expect(find.textContaining('SyntaxError'), findsNothing);
      expect(find.textContaining('FormatException'), findsNothing);
      await tester.pump(const Duration(seconds: 7));
    });

    testWidgets('le même message en rafale (plusieurs requêtes qui échouent ensemble) ne s\'affiche qu\'une fois', (tester) async {
      await ouvrir(tester);
      SnackbarHelper.error('Erreur de communication avec le serveur (503)');
      SnackbarHelper.error('Erreur de communication avec le serveur (503)');
      SnackbarHelper.error('ApiException: Autre (Code: X, Status: 503)'); // même explication finale
      await tester.pump();
      expect(find.textContaining('problème momentané'), findsOneWidget);
      await tester.pump(const Duration(seconds: 7));
    });
  });
}

