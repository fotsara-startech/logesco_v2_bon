import 'package:get/get.dart';
import '../services/commercial_report_service.dart';

enum CommercialReportGroupBy { commercial, zone, ville }

/// Ligne agrégée pour l'affichage, quel que soit le niveau de regroupement
/// choisi (commercial / zone / ville).
class CommercialReportGroup {
  final String label;
  final double montant;
  final int count;

  CommercialReportGroup({required this.label, required this.montant, required this.count});
}

/// Contrôleur du rapport « ventes par commercial / zone / ville ».
///
/// Le backend renvoie une seule liste plate (une ligne par commercial, avec
/// sa zone et sa ville). Le regroupement par zone ou par ville se fait ici,
/// côté Dart, en ré-agrégeant cette même liste — inutile de retourner au
/// serveur pour changer de niveau d'affichage.
class CommercialReportController extends GetxController {
  final CommercialReportService _service = Get.find<CommercialReportService>();

  final Rx<DateTime?> startDate = Rx<DateTime?>(null);
  final Rx<DateTime?> endDate = Rx<DateTime?>(null);
  final Rx<CommercialReportGroupBy> groupBy = CommercialReportGroupBy.commercial.obs;

  final RxBool isLoading = false.obs;
  final RxList<CommercialSalesRow> _rows = <CommercialSalesRow>[].obs;
  final Rx<CommercialReportSummary?> summary = Rx<CommercialReportSummary?>(null);

  @override
  void onInit() {
    super.onInit();
    final now = DateTime.now();
    startDate.value = DateTime(now.year, now.month, 1);
    endDate.value = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    loadReport();
  }

  bool get hasData => _rows.isNotEmpty;

  // Le backend renvoie une ligne par [commercial, zone au moment de la
  // vente] : un commercial réaffecté en cours de période peut donc
  // apparaître sur plusieurs lignes. Les trois niveaux de regroupement
  // ré-agrègent tous cette même liste plate, y compris « par commercial ».
  List<CommercialReportGroup> get groupedRows {
    switch (groupBy.value) {
      case CommercialReportGroupBy.commercial:
        return _groupBy(_rows, (r) => 'c${r.commercialId}', labelOf: (r) => r.commercialNomComplet);
      case CommercialReportGroupBy.zone:
        return _groupBy(_rows, (r) => 'z${r.zoneId}', labelOf: (r) => '${r.zoneNom}, ${r.villeNom}');
      case CommercialReportGroupBy.ville:
        return _groupBy(_rows, (r) => 'v${r.villeId}', labelOf: (r) => r.villeNom);
    }
  }

  List<CommercialReportGroup> _groupBy(
    List<CommercialSalesRow> rows,
    String Function(CommercialSalesRow) keyOf, {
    required String Function(CommercialSalesRow) labelOf,
  }) {
    final Map<String, CommercialReportGroup> acc = {};
    for (final r in rows) {
      final key = keyOf(r);
      final existing = acc[key];
      acc[key] = CommercialReportGroup(
        label: labelOf(r),
        montant: (existing?.montant ?? 0) + r.montant,
        count: (existing?.count ?? 0) + r.count,
      );
    }
    final list = acc.values.toList();
    list.sort((a, b) => b.montant.compareTo(a.montant));
    return list;
  }

  void setGroupBy(CommercialReportGroupBy value) => groupBy.value = value;

  void setPredefinedPeriod(String period) {
    final now = DateTime.now();
    switch (period) {
      case 'today':
        startDate.value = DateTime(now.year, now.month, now.day);
        endDate.value = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'thisWeek':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        startDate.value = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        endDate.value = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'thisMonth':
        startDate.value = DateTime(now.year, now.month, 1);
        endDate.value = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case 'lastMonth':
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        startDate.value = lastMonth;
        endDate.value = DateTime(lastMonth.year, lastMonth.month + 1, 0, 23, 59, 59);
        break;
      case 'thisYear':
        startDate.value = DateTime(now.year, 1, 1);
        endDate.value = DateTime(now.year, 12, 31, 23, 59, 59);
        break;
      default:
        startDate.value = DateTime(now.year, now.month, 1);
        endDate.value = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    }
    loadReport();
  }

  Future<void> loadReport() async {
    if (startDate.value == null || endDate.value == null) return;

    try {
      isLoading.value = true;
      final results = await Future.wait([
        _service.getSummary(startDate.value!, endDate.value!),
        _service.getByCommercial(startDate.value!, endDate.value!),
      ]);
      summary.value = results[0] as CommercialReportSummary;
      _rows.assignAll(results[1] as List<CommercialSalesRow>);
    } catch (e) {
      summary.value = null;
      _rows.clear();
    } finally {
      isLoading.value = false;
    }
  }
}
