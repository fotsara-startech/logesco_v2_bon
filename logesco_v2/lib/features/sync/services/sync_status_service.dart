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

  SyncStatus({
    required this.mode,
    required this.cloudEnabled,
    required this.cloudAvailable,
    required this.pendingCount,
    required this.pendingByTable,
    required this.failedCount,
    this.lastSync,
    this.lastErrorMessage,
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
