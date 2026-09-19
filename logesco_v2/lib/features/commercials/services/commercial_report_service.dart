import 'package:get/get.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/services/auth_service.dart';
import '../../../core/config/app_config.dart';
import '../../boutiques/controllers/boutique_controller.dart';

/// Ligne de vente agrégée pour un commercial sur une période — inclut la
/// zone et la ville pour permettre un regroupement à ces deux niveaux côté
/// client sans appel réseau supplémentaire (voir CommercialReportController).
class CommercialSalesRow {
  final int commercialId;
  final String commercialNom;
  final String? commercialPrenom;
  final int zoneId;
  final String zoneNom;
  final int villeId;
  final String villeNom;
  final double montant;
  final int count;

  CommercialSalesRow({
    required this.commercialId,
    required this.commercialNom,
    this.commercialPrenom,
    required this.zoneId,
    required this.zoneNom,
    required this.villeId,
    required this.villeNom,
    required this.montant,
    required this.count,
  });

  String get commercialNomComplet =>
      commercialPrenom != null && commercialPrenom!.isNotEmpty ? '$commercialNom $commercialPrenom' : commercialNom;

  factory CommercialSalesRow.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic v) => v == null ? 0.0 : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0);
    int parseInt(dynamic v) => v == null ? 0 : (v is num ? v.toInt() : int.tryParse(v.toString()) ?? 0);

    return CommercialSalesRow(
      commercialId: parseInt(json['commercialId']),
      commercialNom: json['commercialNom']?.toString() ?? '',
      commercialPrenom: json['commercialPrenom']?.toString(),
      zoneId: parseInt(json['zoneId']),
      zoneNom: json['zoneNom']?.toString() ?? '',
      villeId: parseInt(json['villeId']),
      villeNom: json['villeNom']?.toString() ?? '',
      montant: parseDouble(json['montant']),
      count: parseInt(json['count']),
    );
  }
}

class CommercialReportSummary {
  final double totalAmount;
  final int totalCount;
  final int commerciauxActifsCount;

  CommercialReportSummary({required this.totalAmount, required this.totalCount, required this.commerciauxActifsCount});

  factory CommercialReportSummary.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic v) => v == null ? 0.0 : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0);
    int parseInt(dynamic v) => v == null ? 0 : (v is num ? v.toInt() : int.tryParse(v.toString()) ?? 0);

    return CommercialReportSummary(
      totalAmount: parseDouble(json['totalAmount']),
      totalCount: parseInt(json['totalCount']),
      commerciauxActifsCount: parseInt(json['commerciauxActifsCount']),
    );
  }
}

/// Service pour le rapport « ventes par commercial / zone / ville ».
class CommercialReportService extends GetxService {
  Future<CommercialReportSummary> getSummary(DateTime startDate, DateTime endDate) async {
    final data = await _get('/commercial-reports/summary', startDate, endDate);
    return CommercialReportSummary.fromJson(data as Map<String, dynamic>);
  }

  Future<List<CommercialSalesRow>> getByCommercial(DateTime startDate, DateTime endDate) async {
    final data = await _get('/commercial-reports/by-commercial', startDate, endDate);
    return (data as List<dynamic>).map((j) => CommercialSalesRow.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<dynamic> _get(String path, DateTime startDate, DateTime endDate) async {
    final token = await Get.find<AuthService>().getToken();
    if (token == null) throw Exception('Token d\'authentification manquant');

    final queryParams = <String, String>{
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
    final boutiqueId = BoutiqueController.getActiveBoutiqueId();
    if (boutiqueId != null) queryParams['boutiqueId'] = boutiqueId.toString();

    final uri = Uri.parse('${AppConfig.currentBaseUrl}$path').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: {'Authorization': 'Bearer $token'});

    if (response.statusCode != 200) {
      throw Exception('Erreur lors de la récupération du rapport commerciaux ($path)');
    }
    return json.decode(response.body)['data'];
  }
}
