import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/app_config.dart';
import '../../../core/services/auth_service.dart';
import 'package:get/get.dart';

class SyncStatus {
  final String mode;
  final bool cloudEnabled;
  final bool cloudAvailable;
  final int pendingCount;
  final Map<String, int> pendingByTable;
  final int failedCount;
  final String? lastSync;
  final String? lastErrorMessage;
  final DateTime? oldestPendingAt;
  final int pullIssuesCount;

  SyncStatus({
    required this.mode,
    required this.cloudEnabled,
    required this.cloudAvailable,
    required this.pendingCount,
    required this.pendingByTable,
    required this.failedCount,
    this.lastSync,
    this.lastErrorMessage,
    this.oldestPendingAt,
    this.pullIssuesCount = 0,
  });

  factory SyncStatus.fromJson(Map<String, dynamic> json) {
    final byTable = <String, int>{};
    final raw = json['pendingByTable'] as Map<String, dynamic>? ?? {};
    raw.forEach((k, v) => byTable[k] = (v as num).toInt());
    return SyncStatus(
      mode: json['mode'] ?? 'local-only',
      cloudEnabled: json['cloudEnabled'] ?? false,
      cloudAvailable: json['cloudAvailable'] ?? false,
      pendingCount: (json['pendingCount'] as num?)?.toInt() ?? 0,
      pendingByTable: byTable,
      failedCount: (json['failedCount'] as num?)?.toInt() ?? 0,
      lastSync: json['lastSync'],
      lastErrorMessage: _parseError(json['lastError']),
      pullIssuesCount: (json['pullIssuesCount'] as num?)?.toInt() ?? 0,
      oldestPendingAt: json['oldestPendingAt'] != null ? DateTime.tryParse(json['oldestPendingAt'].toString())?.toLocal() : null,
    );
  }

  static String? _parseError(dynamic e) {
    if (e is! Map) return null;
    final code = e['code'];
    final msg = e['message'];
    if (msg == null) return null;
    return code != null ? '$code : $msg' : '$msg';
  }

  bool get isType3 => cloudEnabled;
  bool get isOnline => cloudAvailable;
  bool get hasPending => pendingCount > 0;

  /// Délai au-delà duquel des opérations en attente sont jugées anormales
  static const Duration staleThreshold = Duration(hours: 24);

  /// Ancienneté de la plus vieille opération non synchronisée
  Duration? get pendingAge => (hasPending && oldestPendingAt != null) ? DateTime.now().difference(oldestPendingAt!) : null;

  /// true si des données restent sans synchroniser depuis plus de 24 h
  bool get isStale => (pendingAge ?? Duration.zero) >= staleThreshold;

  /// "3 jours", "30 heures"… pour les messages d'alerte
  String get pendingAgeLabel {
    final a = pendingAge;
    if (a == null) return '';
    if (a.inDays >= 2) return '${a.inDays} jours';
    return '${a.inHours} heures';
  }
}

/// Explication d'une erreur de synchronisation, en clair.
class SyncErrorInfo {
  /// doublon | dependance | reseau | schema | donnee | inconnue | attente
  final String code;
  final String titre;
  final String explication;
  final String action;
  final String? technique;

  const SyncErrorInfo({
    required this.code,
    required this.titre,
    required this.explication,
    required this.action,
    this.technique,
  });

  factory SyncErrorInfo.fromJson(Map<String, dynamic> json) => SyncErrorInfo(
        code: (json['code'] ?? 'inconnue').toString(),
        titre: (json['titre'] ?? '').toString(),
        explication: (json['explication'] ?? '').toString(),
        action: (json['action'] ?? '').toString(),
        technique: json['technique']?.toString(),
      );
}

/// Un élément non synchronisé : envoi en attente / refusé, ou ligne reçue du cloud non appliquée.
class SyncDetailItem {
  /// envoi | reception
  final String source;
  final String table;
  final String tableLabel;
  final String operationLabel;
  final String summary;

  /// pending | failed
  final String status;
  final DateTime? createdAt;
  final int attempts;
  final SyncErrorInfo error;

  const SyncDetailItem({
    required this.source,
    required this.table,
    required this.tableLabel,
    required this.operationLabel,
    required this.summary,
    required this.status,
    required this.error,
    this.createdAt,
    this.attempts = 0,
  });

  bool get isFailed => status == 'failed';
  bool get isReception => source == 'reception';

  factory SyncDetailItem.fromJson(Map<String, dynamic> json) => SyncDetailItem(
        source: (json['source'] ?? 'envoi').toString(),
        table: (json['table'] ?? '').toString(),
        tableLabel: (json['tableLabel'] ?? json['table'] ?? '').toString(),
        operationLabel: (json['operationLabel'] ?? '').toString(),
        summary: (json['summary'] ?? '').toString(),
        status: (json['status'] ?? 'pending').toString(),
        createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString())?.toLocal() : null,
        attempts: (json['attempts'] as num?)?.toInt() ?? 0,
        error: SyncErrorInfo.fromJson((json['error'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{}),
      );

  /// Texte à copier pour le support
  String toReportLine() {
    String two(int n) => n.toString().padLeft(2, '0');
    final d = createdAt;
    final date = d != null ? ' [${two(d.day)}/${two(d.month)} ${two(d.hour)}:${two(d.minute)}]' : '';
    final buf = StringBuffer('- $tableLabel · $operationLabel$date : $summary');
    if (isFailed) buf.write('\n    Problème : ${error.titre}\n    Explication : ${error.explication}\n    Action : ${error.action}');
    if ((error.technique ?? '').isNotEmpty) buf.write('\n    Technique : ${error.technique}');
    return buf.toString();
  }
}

class SyncStatusService {
  final String _baseUrl = AppConfig.baseUrl;

  Map<String, String> _headers() {
    final token = Get.find<AuthService>().token;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<SyncStatus?> getStatus() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/sync/status'), headers: _headers())
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          return SyncStatus.fromJson(json['data']);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Détail de chaque élément non synchronisé (null si le serveur est trop ancien pour le fournir)
  Future<List<SyncDetailItem>?> getDetails() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/sync/details'), headers: _headers())
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body);
      if (json['success'] != true || json['data'] == null) return null;
      final items = (json['data']['items'] as List<dynamic>? ?? const []);
      return items.map((e) => SyncDetailItem.fromJson((e as Map).cast<String, dynamic>())).toList();
    } catch (_) {
      return null;
    }
  }

  /// Retourne null en cas de succès, sinon le motif de l'échec.
  Future<String?> triggerSync() async {
    try {
      // Le backend retente la connexion jusqu'à 3 fois (30 s chacune) avant de renoncer
      final response = await http
          .post(Uri.parse('$_baseUrl/sync/trigger'), headers: _headers())
          .timeout(const Duration(seconds: 150));
      final json = jsonDecode(response.body);
      if (response.statusCode == 200 && json['success'] == true) return null;
      return (json['message'] as String?) ?? 'Échec de la synchronisation';
    } catch (_) {
      return 'Le serveur local ne répond pas';
    }
  }
}
