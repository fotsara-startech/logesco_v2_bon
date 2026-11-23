import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/app_config.dart';
import '../../../core/services/auth_service.dart';

/// Erreur renvoyée par l'API comptable (message déjà lisible, code métier optionnel)
class LedgerException implements Exception {
  final String message;
  final String? code;
  LedgerException(this.message, {this.code});
  @override
  String toString() => message;
}

/// Accès à l'API de comptabilité en partie double (/compta).
/// Toutes les méthodes renvoient le champ `data` de la réponse, ou lèvent une [LedgerException].
class LedgerService {
  final AuthService _authService;
  LedgerService(this._authService);

  String get _base => '${AppConfig.currentBaseUrl}/compta';

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    if (token == null) throw LedgerException('Session expirée');
    return {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'};
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final q = <String, String>{};
    query?.forEach((k, v) {
      if (v != null && v.toString().isNotEmpty) q[k] = v.toString();
    });
    return Uri.parse('$_base$path').replace(queryParameters: q.isEmpty ? null : q);
  }

  dynamic _decode(http.Response r) {
    dynamic body;
    try {
      body = json.decode(utf8.decode(r.bodyBytes));
    } catch (_) {
      body = null;
    }
    if (r.statusCode >= 200 && r.statusCode < 300 && body is Map) return body['data'];
    final message = body is Map ? (body['message'] ?? body['error'] ?? 'Erreur ${r.statusCode}').toString() : 'Erreur ${r.statusCode}';
    throw LedgerException(message, code: body is Map ? body['code']?.toString() : null);
  }

  Future<dynamic> _get(String path, [Map<String, dynamic>? query]) async =>
      _decode(await http.get(_uri(path, query), headers: await _headers()));

  Future<dynamic> _send(String method, String path, [Map<String, dynamic>? body]) async {
    final request = http.Request(method, _uri(path))..headers.addAll(await _headers());
    if (body != null) request.body = json.encode(body);
    return _decode(await http.Response.fromStream(await request.send()));
  }

  // Paramètres et ouverture
  Future<Map<String, dynamic>> getParametres() async => Map<String, dynamic>.from(await _get('/parametres'));
  Future<Map<String, dynamic>> updateParametres(Map<String, dynamic> p) async => Map<String, dynamic>.from(await _send('PUT', '/parametres', p));
  Future<Map<String, dynamic>> enregistrerOuverture(Map<String, dynamic> p) async => Map<String, dynamic>.from(await _send('POST', '/ouverture', p));

  // Plan comptable
  Future<List<Map<String, dynamic>>> comptes({String? q}) async =>
      List<Map<String, dynamic>>.from((await _get('/comptes', {'q': q, 'actif': 'true'})) as List);
  Future<Map<String, dynamic>> creerCompte(Map<String, dynamic> p) async => Map<String, dynamic>.from(await _send('POST', '/comptes', p));

  // Journaux et exercices
  Future<List<Map<String, dynamic>>> journaux() async => List<Map<String, dynamic>>.from((await _get('/journaux')) as List);
  Future<List<Map<String, dynamic>>> exercices() async => List<Map<String, dynamic>>.from((await _get('/exercices')) as List);
  Future<Map<String, dynamic>> creerExercice(Map<String, dynamic> p) async => Map<String, dynamic>.from(await _send('POST', '/exercices', p));
  Future<Map<String, dynamic>> changerPeriode(int exerciceId, int mois, String statut) async =>
      Map<String, dynamic>.from(await _send('PUT', '/exercices/$exerciceId/periodes/$mois', {'statut': statut}));

  // Écritures
  Future<Map<String, dynamic>> ecritures({String? journalCode, String? statut, int? boutiqueId, int page = 1}) async =>
      Map<String, dynamic>.from(await _get('/ecritures', {'journalCode': journalCode, 'statut': statut, 'boutiqueId': boutiqueId, 'page': page, 'limit': 50}));
  Future<Map<String, dynamic>> ecriture(int id) async => Map<String, dynamic>.from(await _get('/ecritures/$id'));
  Future<Map<String, dynamic>> creerEcriture(Map<String, dynamic> p) async => Map<String, dynamic>.from(await _send('POST', '/ecritures', p));
  Future<Map<String, dynamic>> modifierEcriture(int id, Map<String, dynamic> p) async => Map<String, dynamic>.from(await _send('PUT', '/ecritures/$id', p));
  Future<void> supprimerEcriture(int id) async => _send('DELETE', '/ecritures/$id');
  Future<Map<String, dynamic>> validerEcriture(int id) async => Map<String, dynamic>.from(await _send('POST', '/ecritures/$id/valider'));
  Future<Map<String, dynamic>> contrepasser(int id, {String? date, String? motif}) async =>
      Map<String, dynamic>.from(await _send('POST', '/ecritures/$id/contrepasser', {'dateEcriture': date, 'motif': motif}));

  // Écritures automatiques et contrôles
  Future<Map<String, dynamic>> generer() async => Map<String, dynamic>.from(await _send('POST', '/generer'));
  Future<Map<String, dynamic>?> derniereGeneration() async {
    final r = await _get('/generation');
    return r == null ? null : Map<String, dynamic>.from(r);
  }
  Future<Map<String, dynamic>> controles() async => Map<String, dynamic>.from(await _get('/controles'));

  Future<Map<String, dynamic>> propositionsOuverture() async => Map<String, dynamic>.from(await _get('/ouverture/propositions'));
  Future<Map<String, dynamic>> audit({String? action, int page = 1}) async =>
      Map<String, dynamic>.from(await _get('/audit', {'action': action, 'page': page, 'limit': 100}));

  // Immobilisations, clôture
  Future<List<Map<String, dynamic>>> immobilisations() async => List<Map<String, dynamic>>.from((await _get('/immobilisations')) as List);
  Future<Map<String, dynamic>> creerImmobilisation(Map<String, dynamic> p) async => Map<String, dynamic>.from(await _send('POST', '/immobilisations', p));
  Future<Map<String, dynamic>> planAmortissement(int id) async => Map<String, dynamic>.from(await _get('/immobilisations/$id/plan'));
  Future<Map<String, dynamic>> ceder(int id, String date, int prix) async =>
      Map<String, dynamic>.from(await _send('POST', '/immobilisations/$id/ceder', {'date': date, 'prix': prix}));
  Future<Map<String, dynamic>> dotations(int exerciceId) async => Map<String, dynamic>.from(await _send('POST', '/exercices/$exerciceId/dotations'));
  Future<int> valeurStock() async => ((await _get('/stocks/valeur')) as Map)['valeur'] as int;
  Future<Map<String, dynamic>> cloturer(int exerciceId, int valeurStock) async =>
      Map<String, dynamic>.from(await _send('POST', '/exercices/$exerciceId/cloturer', {'valeurStock': valeurStock}));

  // États (tableaux génériques, résumé, exports)
  Future<Map<String, dynamic>> resume({int? annee, int? mois, int? boutiqueId}) async =>
      Map<String, dynamic>.from(await _get('/resume', {'annee': annee, 'mois': mois, 'boutiqueId': boutiqueId}));

  /// Un état sous forme de tableau { titre, sousTitre, colonnes[{cle, libelle, type}], lignes[] }
  Future<Map<String, dynamic>> tableau(String chemin, Map<String, dynamic> query) async =>
      Map<String, dynamic>.from(await _get(chemin, {...query, 'format': 'tableau'}));

  /// Télécharge un état en CSV ou Excel : octets du fichier
  Future<List<int>> telecharger(String chemin, Map<String, dynamic> query, String format) async {
    final r = await http.get(_uri(chemin, {...query, 'format': format}), headers: await _headers());
    if (r.statusCode != 200) {
      try {
        throw LedgerException((json.decode(utf8.decode(r.bodyBytes)) as Map)['message'].toString());
      } on LedgerException {
        rethrow;
      } catch (_) {
        throw LedgerException('Erreur ${r.statusCode}');
      }
    }
    return r.bodyBytes;
  }

  Future<Map<String, dynamic>> lettrageAutomatique(String type) async =>
      Map<String, dynamic>.from(await _send('POST', '/lettrage/auto', {'type': type}));

  Future<Map<String, dynamic>> grandLivre(String compte, {String? dateDebut, String? dateFin, int? boutiqueId}) async =>
      Map<String, dynamic>.from(await _get('/grand-livre', {'compte': compte, 'dateDebut': dateDebut, 'dateFin': dateFin, 'boutiqueId': boutiqueId}));
  Future<Map<String, dynamic>> balance({String? dateDebut, String? dateFin, int? boutiqueId}) async =>
      Map<String, dynamic>.from(await _get('/balance', {'dateDebut': dateDebut, 'dateFin': dateFin, 'boutiqueId': boutiqueId}));
}
