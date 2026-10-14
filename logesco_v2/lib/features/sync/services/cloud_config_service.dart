import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/app_config.dart';
import '../../../core/services/auth_service.dart';

/// Ce que le serveur montre d'un lien de connexion : jamais le mot de passe.
class CloudInfo {
  final String hote;
  final String base;
  final String utilisateur;

  const CloudInfo({required this.hote, required this.base, required this.utilisateur});

  static CloudInfo? depuis(dynamic json) {
    if (json is! Map) return null;
    return CloudInfo(
      hote: (json['hote'] ?? '').toString(),
      base: (json['base'] ?? '').toString(),
      utilisateur: (json['utilisateur'] ?? '').toString(),
    );
  }
}

/// Où en est la connexion au cloud (`GET /sync/cloud-config`)
class CloudConfig {
  /// Le serveur tourne avec un cloud (sinon : 100 % local)
  final bool active;
  final CloudInfo? infoActive;

  /// Un lien est enregistré dans le fichier de configuration
  final bool enregistree;
  final CloudInfo? infoEnregistree;

  /// Le lien enregistré n'est pas celui avec lequel le serveur tourne : il doit redémarrer
  final bool redemarrageNecessaire;

  const CloudConfig({
    required this.active,
    this.infoActive,
    required this.enregistree,
    this.infoEnregistree,
    required this.redemarrageNecessaire,
  });

  factory CloudConfig.fromJson(Map<String, dynamic> json) => CloudConfig(
        active: json['active'] == true,
        infoActive: CloudInfo.depuis(json['infoActive']),
        enregistree: json['enregistree'] == true,
        infoEnregistree: CloudInfo.depuis(json['infoEnregistree']),
        redemarrageNecessaire: json['redemarrageNecessaire'] == true,
      );
}

/// Résultat du test d'un lien (`POST /sync/cloud-config/test`)
class CloudTestResult {
  final bool ok;
  final String message;
  final CloudInfo? info;

  /// La base contient les tables de LOGESCO
  final bool schemaPret;
  final List<String> tablesManquantes;

  /// Ce que le cloud contient déjà (produits, clients, ventes) ; null si le schéma est absent
  final Map<String, int>? donnees;

  const CloudTestResult({
    required this.ok,
    required this.message,
    this.info,
    this.schemaPret = false,
    this.tablesManquantes = const [],
    this.donnees,
  });

  factory CloudTestResult.fromJson(Map<String, dynamic> json) {
    final d = json['donnees'];
    return CloudTestResult(
      ok: json['ok'] == true,
      message: (json['message'] ?? '').toString(),
      info: CloudInfo.depuis(json['info']),
      schemaPret: json['schemaPret'] == true,
      tablesManquantes: (json['tablesManquantes'] as List<dynamic>? ?? const []).map((e) => e.toString()).toList(),
      donnees: d is Map ? d.map((k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0)) : null,
    );
  }

  /// Le cloud contient déjà des données (autres postes ou historique)
  bool get cloudDejaRempli => donnees != null && donnees!.values.any((n) => n > 0);
}

/// Saisie du lien Neon depuis l'application, au lieu de modifier le fichier .env à la main.
/// Toutes les erreurs sont levées avec le message du serveur (déjà en clair, sans mot de passe).
class CloudConfigService {
  final String _baseUrl = AppConfig.baseUrl;

  Map<String, String> _headers() {
    final token = Get.find<AuthService>().token;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _lire(http.Response r, String repli) {
    Map<String, dynamic> json;
    try {
      json = jsonDecode(r.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception(repli);
    }
    if (r.statusCode != 200 || json['success'] != true) {
      throw Exception((json['message'] as String?) ?? repli);
    }
    return json;
  }

  Future<CloudConfig> lire() async {
    final r = await http.get(Uri.parse('$_baseUrl/sync/cloud-config'), headers: _headers()).timeout(const Duration(seconds: 10));
    return CloudConfig.fromJson((_lire(r, 'Impossible de lire la connexion au cloud')['data'] as Map).cast<String, dynamic>());
  }

  /// Teste le lien sans rien enregistrer
  Future<CloudTestResult> tester(String url) async {
    final r = await http
        .post(Uri.parse('$_baseUrl/sync/cloud-config/test'), headers: _headers(), body: jsonEncode({'url': url}))
        .timeout(const Duration(seconds: 40));
    return CloudTestResult.fromJson((_lire(r, 'Le test de connexion a échoué')['data'] as Map).cast<String, dynamic>());
  }

  /// Teste puis enregistre le lien. Le serveur doit ensuite redémarrer pour l'utiliser.
  Future<CloudConfig> enregistrer(String url) async {
    final r = await http
        .post(Uri.parse('$_baseUrl/sync/cloud-config'), headers: _headers(), body: jsonEncode({'url': url}))
        .timeout(const Duration(seconds: 40));
    return CloudConfig.fromJson((_lire(r, "Le lien n'a pas pu être enregistré")['data'] as Map).cast<String, dynamic>());
  }
}

/// Vérification rapide d'un lien Neon AVANT de contacter le serveur (le serveur refait une validation stricte).
/// Renvoie le message à afficher, ou null si le lien paraît correct.
String? verifierLienNeon(String saisie) {
  final lien = saisie.trim();
  if (lien.isEmpty) return 'Collez le lien de connexion de la base Neon.';
  // Espace ou caractère de contrôle (<= 32), guillemet double (34), apostrophe (39), accent grave (96), antislash (92)
  if (lien.runes.any((c) => c <= 32 || c == 34 || c == 39 || c == 96 || c == 92)) {
    return "Le lien contient des espaces ou des guillemets : recopiez-le tel que Neon l'affiche, sur une seule ligne.";
  }
  if (!RegExp(r'^postgres(ql)?://', caseSensitive: false).hasMatch(lien)) {
    return 'Le lien doit commencer par postgresql:// (copiez « Connection string » dans la console Neon).';
  }
  final uri = Uri.tryParse(lien);
  if (uri == null || uri.host.isEmpty) return "Le lien n'est pas valide : vérifiez qu'il est complet.";
  if (uri.userInfo.isEmpty || !uri.userInfo.contains(':') || uri.userInfo.endsWith(':')) {
    return "Le lien ne contient pas le nom d'utilisateur et le mot de passe.";
  }
  if (uri.path.length <= 1) return "Le lien ne contient pas le nom de la base de données (à la fin, après l'adresse).";
  return null;
}
