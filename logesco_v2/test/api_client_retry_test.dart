import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:logesco_v2/core/api/api_client.dart';
import 'package:logesco_v2/core/utils/exceptions.dart';
import 'package:logesco_v2/core/utils/friendly_error.dart';

/// Client dont le « serveur » répond selon un scénario ; compte les appels.
class _Serveur {
  int appels = 0;
  final http.Response Function(int appel, http.Request requete) reponse;
  _Serveur(this.reponse);

  ApiClient client() {
    final c = ApiClient(
      client: MockClient((req) async {
        appels++;
        return reponse(appels, req);
      }),
      pauseReprise: (_, __) => Duration.zero, // pas d'attente réelle dans les tests
    );
    c.onInit();
    return c;
  }
}

http.Response _json(String corps, [int statut = 200]) => http.Response(corps, statut, headers: {'content-type': 'application/json'});
http.Response _texte429() => http.Response('Trop de requêtes, veuillez réessayer plus tard.', 429);

void main() {
  group('lecture (GET) : une erreur passagère est retentée avant d\'être montrée', () {
    test('429 « Trop de requêtes » (texte brut) deux fois puis succès : l\'utilisateur ne voit rien', () async {
      final s = _Serveur((n, _) => n <= 2 ? _texte429() : _json('{"success":true,"data":[1,2]}'));
      final r = await s.client().get<Map<String, dynamic>>('/inventory');
      expect(r.isSuccess, isTrue);
      expect(s.appels, 3, reason: '1 essai + 2 reprises');
    });

    test('429 qui dure : erreur lisible (pas « Unexpected token T »), après 3 essais au total', () async {
      final s = _Serveur((_, __) => _texte429());
      await expectLater(
        s.client().get<Map<String, dynamic>>('/inventory'),
        throwsA(isA<ApiException>()
            .having((e) => e.code, 'code', 'RATE_LIMITED')
            .having((e) => e.statusCode, 'statut', 429)
            .having((e) => e.message, 'message', FriendlyError.surcharge)),
      );
      expect(s.appels, 3);
    });

    test('réseau coupé ou serveur qui se réveille (« Failed to fetch ») : retenté, puis message clair', () async {
      final s = _Serveur((_, __) => throw http.ClientException('Failed to fetch, uri=https://logesco-smart-energy.onrender.com/api/v1/inventory'));
      await expectLater(
        s.client().get<Map<String, dynamic>>('/inventory'),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', FriendlyError.reseau).having((e) => e.statusCode, 'statut', 0)),
      );
      expect(s.appels, 3);
    });

    test('serveur indisponible un instant (503) puis revenu : transparent', () async {
      final s = _Serveur((n, _) => n == 1 ? http.Response('Service Unavailable', 503) : _json('{"success":true,"data":{}}'));
      final r = await s.client().get<Map<String, dynamic>>('/inventory/summary');
      expect(r.isSuccess, isTrue);
      expect(s.appels, 2);
    });

    test('le délai demandé par le serveur (Retry-After) est lu', () async {
      final s = _Serveur((_, __) => http.Response('{"success":false,"message":"Trop de requêtes en peu de temps. Patientez quelques instants puis réessayez.","code":"RATE_LIMITED","retryAfterSeconds":30}', 429,
          headers: {'content-type': 'application/json', 'retry-after': '30'}));
      await expectLater(
        s.client().get<Map<String, dynamic>>('/x'),
        throwsA(isA<ApiException>().having((e) => e.retryAfterSeconds, 'retryAfter', 30).having((e) => e.message, 'message', contains('Patientez'))),
      );
    });
  });

  group('ce qui ne doit PAS être retenté', () {
    test('une écriture (POST) : jamais retentée automatiquement (un doublon serait pire qu\'une erreur)', () async {
      final s = _Serveur((_, __) => _texte429());
      await expectLater(s.client().post<Map<String, dynamic>>('/ventes', {'a': 1}), throwsA(isA<ApiException>().having((e) => e.code, 'code', 'RATE_LIMITED')));
      expect(s.appels, 1);
    });

    test('PUT et DELETE non plus', () async {
      final s = _Serveur((_, __) => throw http.ClientException('Failed to fetch'));
      await expectLater(s.client().put<Map<String, dynamic>>('/x/1', {}), throwsA(isA<ApiException>()));
      await expectLater(s.client().delete<Map<String, dynamic>>('/x/1'), throwsA(isA<ApiException>()));
      expect(s.appels, 2, reason: 'un appel chacun');
    });

    test('erreur métier (404, 400) : le message du serveur est conservé, pas de reprise', () async {
      final s = _Serveur((_, __) => _json('{"success":false,"message":"Produit introuvable"}', 404));
      await expectLater(s.client().get<Map<String, dynamic>>('/produits/9'), throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Produit introuvable')));
      expect(s.appels, 1);
    });

    test('réponse 200 illisible : message clair et aucune reprise (ce n\'est pas passager)', () async {
      final s = _Serveur((_, __) => http.Response('<html>pas du json</html>', 200));
      await expectLater(s.client().get<Map<String, dynamic>>('/x'), throwsA(isA<ApiException>().having((e) => e.message, 'message', FriendlyError.reponse)));
      expect(s.appels, 1);
    });
  });
}
