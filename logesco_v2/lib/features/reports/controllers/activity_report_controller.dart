import 'dart:io';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../models/activity_report.dart';
import '../services/activity_report_service.dart';
import '../services/pdf_export_service.dart';
import '../../../core/services/auth_service.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';

/// Contrôleur pour la gestion des bilans comptables d'activités
class ActivityReportController extends GetxController {
  final ActivityReportService _reportService;
  final PdfExportService _pdfService;

  ActivityReportController(
    this._reportService,
    this._pdfService,
  );

  // État réactif
  final _isLoading = false.obs;
  final _isGeneratingPdf = false.obs;
  final _currentReport = Rxn<ActivityReport>();
  final _selectedStartDate = Rxn<DateTime>();
  final _selectedEndDate = Rxn<DateTime>();
  final _selectedPeriod = 'thisMonth'.obs;

  // Getters
  bool get isLoading => _isLoading.value;
  bool get isGeneratingPdf => _isGeneratingPdf.value;
  ActivityReport? get currentReport => _currentReport.value;
  DateTime? get selectedStartDate => _selectedStartDate.value;
  DateTime? get selectedEndDate => _selectedEndDate.value;
  String get selectedPeriod => _selectedPeriod.value;

  @override
  void onInit() {
    super.onInit();
    _initializeDates();
  }

  /// Initialise les dates par défaut (mois en cours)
  void _initializeDates() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    _selectedStartDate.value = startOfMonth;
    _selectedEndDate.value = endOfMonth;
  }

  /// Sélectionne une période prédéfinie
  void selectPeriod(String period) {
    _selectedPeriod.value = period;
    final now = DateTime.now();

    switch (period) {
      case 'today':
        _selectedStartDate.value = DateTime(now.year, now.month, now.day);
        _selectedEndDate.value = DateTime(now.year, now.month, now.day);
        break;
      case 'yesterday':
        final yesterday = now.subtract(const Duration(days: 1));
        _selectedStartDate.value = DateTime(yesterday.year, yesterday.month, yesterday.day);
        _selectedEndDate.value = DateTime(yesterday.year, yesterday.month, yesterday.day);
        break;
      case 'thisWeek':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        _selectedStartDate.value = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        _selectedEndDate.value = DateTime(now.year, now.month, now.day);
        break;
      case 'lastWeek':
        final startOfLastWeek = now.subtract(Duration(days: now.weekday + 6));
        final endOfLastWeek = now.subtract(Duration(days: now.weekday));
        _selectedStartDate.value = DateTime(startOfLastWeek.year, startOfLastWeek.month, startOfLastWeek.day);
        _selectedEndDate.value = DateTime(endOfLastWeek.year, endOfLastWeek.month, endOfLastWeek.day);
        break;
      case 'thisMonth':
        _selectedStartDate.value = DateTime(now.year, now.month, 1);
        _selectedEndDate.value = DateTime(now.year, now.month + 1, 0);
        break;
      case 'lastMonth':
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        _selectedStartDate.value = lastMonth;
        _selectedEndDate.value = DateTime(now.year, now.month, 0);
        break;
      case 'thisQuarter':
        final quarterStart = DateTime(now.year, ((now.month - 1) ~/ 3) * 3 + 1, 1);
        _selectedStartDate.value = quarterStart;
        _selectedEndDate.value = DateTime(now.year, now.month, now.day);
        break;
      case 'thisYear':
        _selectedStartDate.value = DateTime(now.year, 1, 1);
        _selectedEndDate.value = DateTime(now.year, now.month, now.day);
        break;
      case 'lastYear':
        _selectedStartDate.value = DateTime(now.year - 1, 1, 1);
        _selectedEndDate.value = DateTime(now.year - 1, 12, 31);
        break;
    }
  }

  /// Sélectionne une date de début personnalisée
  Future<void> selectStartDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate.value ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('fr', 'FR'),
    );

    if (date != null) {
      _selectedStartDate.value = date;
      _selectedPeriod.value = 'custom';

      // Ajuster la date de fin si nécessaire
      if (_selectedEndDate.value != null && date.isAfter(_selectedEndDate.value!)) {
        _selectedEndDate.value = date;
      }
    }
  }

  /// Sélectionne une date de fin personnalisée
  Future<void> selectEndDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedEndDate.value ?? DateTime.now(),
      firstDate: _selectedStartDate.value ?? DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('fr', 'FR'),
    );

    if (date != null) {
      _selectedEndDate.value = date;
      _selectedPeriod.value = 'custom';
    }
  }

  /// Génère le bilan comptable
  Future<void> generateReport() async {
    if (_selectedStartDate.value == null || _selectedEndDate.value == null) {
      Get.snackbar(
        'Erreur',
        'Veuillez sélectionner une période valide',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return;
    }

    if (_selectedStartDate.value!.isAfter(_selectedEndDate.value!)) {
      Get.snackbar(
        'Erreur',
        'La date de début doit être antérieure à la date de fin',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return;
    }

    try {
      _isLoading.value = true;

      final report = await _reportService.generateActivityReport(
        startDate: _selectedStartDate.value!,
        endDate: _selectedEndDate.value!,
      );

      _currentReport.value = report;

      Get.snackbar(
        'Succès',
        'Bilan comptable généré avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );
    } catch (e) {
      print('❌ Erreur lors de la génération du bilan: $e');
      Get.snackbar(
        'Erreur',
        'Erreur lors de la génération du bilan: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  /// Exporte le bilan en PDF
  Future<void> exportToPdf() async {
    if (_currentReport.value == null) {
      Get.snackbar(
        'Erreur',
        'Aucun bilan à exporter. Veuillez d\'abord générer un bilan.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return;
    }

    try {
      _isGeneratingPdf.value = true;

      final pdfFile = await _pdfService.generateActivityReportPdf(_currentReport.value!);

      Get.snackbar(
        'Succès',
        'PDF généré avec succès: ${pdfFile.path}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
        duration: const Duration(seconds: 4),
      );

      // Proposer d'ouvrir le fichier
      _showPdfActions(pdfFile);
    } catch (e) {
      print('❌ Erreur lors de l\'export PDF: $e');
      Get.snackbar(
        'Erreur',
        'Erreur lors de l\'export PDF: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      _isGeneratingPdf.value = false;
    }
  }

  /// Affiche les actions disponibles pour le PDF
  void _showPdfActions(File pdfFile) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'PDF généré avec succès',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Get.back();
                      await _openPdf(pdfFile);
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Ouvrir'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Get.back();
                      await _sharePdf(pdfFile);
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Partager'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Fermer'),
            ),
          ],
        ),
      ),
    );
  }

  /// Ouvre le PDF avec l'application par défaut
  Future<void> _openPdf(File pdfFile) async {
    try {
      final result = await OpenFile.open(pdfFile.path);
      if (result.type != ResultType.done) {
        Get.snackbar(
          'Information',
          'Impossible d\'ouvrir le PDF automatiquement. Fichier sauvegardé dans: ${pdfFile.path}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.blue.shade100,
          colorText: Colors.blue.shade800,
          duration: const Duration(seconds: 5),
        );
      }
    } catch (e) {
      print('❌ Erreur lors de l\'ouverture du PDF: $e');
      Get.snackbar(
        'Erreur',
        'Impossible d\'ouvrir le PDF: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  /// Partage le PDF
  Future<void> _sharePdf(File pdfFile) async {
    try {
      await Share.shareXFiles(
        [XFile(pdfFile.path)],
        text: 'Bilan comptable d\'activités - ${_currentReport.value?.reportPeriod}',
        subject: 'Bilan comptable - ${_currentReport.value?.companyName}',
      );
    } catch (e) {
      print('❌ Erreur lors du partage du PDF: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de partager le PDF: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  /// Actualise le bilan actuel
  Future<void> refreshReport() async {
    if (_selectedStartDate.value != null && _selectedEndDate.value != null) {
      await generateReport();
    }
  }

  /// Réinitialise le contrôleur
  void reset() {
    _currentReport.value = null;
    _initializeDates();
    _selectedPeriod.value = 'thisMonth';
  }

  /// Obtient le libellé de la période sélectionnée
  String get periodLabel {
    switch (_selectedPeriod.value) {
      case 'today':
        return 'Aujourd\'hui';
      case 'yesterday':
        return 'Hier';
      case 'thisWeek':
        return 'Cette semaine';
      case 'lastWeek':
        return 'Semaine dernière';
      case 'thisMonth':
        return 'Ce mois';
      case 'lastMonth':
        return 'Mois dernier';
      case 'thisQuarter':
        return 'Ce trimestre';
      case 'thisYear':
        return 'Cette année';
      case 'lastYear':
        return 'Année dernière';
      case 'custom':
        if (_selectedStartDate.value != null && _selectedEndDate.value != null) {
          final start = '${_selectedStartDate.value!.day}/${_selectedStartDate.value!.month}/${_selectedStartDate.value!.year}';
          final end = '${_selectedEndDate.value!.day}/${_selectedEndDate.value!.month}/${_selectedEndDate.value!.year}';
          return '$start - $end';
        }
        return 'Période personnalisée';
      default:
        return 'Période inconnue';
    }
  }

  /// Vérifie si les données sont disponibles pour la période
  bool get hasDataForPeriod {
    return _currentReport.value != null &&
        (_currentReport.value!.salesData.totalSales > 0 || _currentReport.value!.financialMovements.totalIncome > 0 || _currentReport.value!.financialMovements.totalExpenses > 0);
  }

  /// Obtient un résumé rapide du statut
  String get quickStatusSummary {
    if (_currentReport.value == null) return 'Aucun bilan généré';

    final report = _currentReport.value!;
    final status = report.summary.overallStatus;
    final revenue = report.salesData.totalRevenueFormatted;
    final profit = report.profitData.netProfitFormatted;

    return '$status - CA: $revenue, Bénéfice: $profit';
  }
}
