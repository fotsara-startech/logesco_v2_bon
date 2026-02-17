import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/utils/snackbar_utils.dart';
import '../models/models.dart';
import '../services/printing_service.dart';
import '../services/receipt_preview_service.dart';
import '../../company_settings/services/company_settings_service.dart';
import '../../company_settings/models/company_profile.dart';
import '../../../core/services/auth_service.dart';

/// Contrôleur pour la gestion des impressions et réimpressions
class PrintingController extends GetxController {
  final PrintingService _printingService = Get.find<PrintingService>();
  final ReceiptPreviewService _previewService = Get.put(ReceiptPreviewService());
  final CompanySettingsService _companyService = CompanySettingsService(Get.find<AuthService>());

  // État des reçus
  final RxList<Receipt> _receipts = <Receipt>[].obs;
  final Rx<Receipt?> _currentReceipt = Rx<Receipt?>(null);
  final RxBool _isLoading = false.obs;
  final RxBool _isSearching = false.obs;
  final RxBool _isGenerating = false.obs;

  // État de la recherche
  final RxString _searchQuery = ''.obs;
  final Rx<ReceiptAdvancedFilter> _currentFilter = ReceiptAdvancedFilter.empty().obs;
  final RxInt _currentPage = 1.obs;
  final RxInt _totalPages = 1.obs;
  final RxBool _hasMoreData = true.obs;
  final RxInt _totalReceipts = 0.obs;
  final Rx<ReceiptFilterPreset?> _activePreset = Rx<ReceiptFilterPreset?>(null);

  // Contrôleurs de texte pour la recherche
  final TextEditingController searchController = TextEditingController();
  final TextEditingController saleNumberController = TextEditingController();
  final TextEditingController customerNameController = TextEditingController();

  // État du profil d'entreprise
  final Rx<CompanyProfile?> _companyProfile = Rx<CompanyProfile?>(null);

  // État de la prévisualisation
  final Rx<PrintFormat> _selectedFormat = PrintFormat.thermal.obs;
  final RxString _previewContent = ''.obs;

  // Getters
  List<Receipt> get receipts => _receipts;
  Receipt? get currentReceipt => _currentReceipt.value;
  bool get isLoading => _isLoading.value;
  bool get isSearching => _isSearching.value;
  bool get isGenerating => _isGenerating.value;

  String get searchQuery => _searchQuery.value;
  ReceiptAdvancedFilter get currentFilter => _currentFilter.value;
  int get currentPage => _currentPage.value;
  int get totalPages => _totalPages.value;
  bool get hasMoreData => _hasMoreData.value;

  CompanyProfile? get companyProfile => _companyProfile.value;
  PrintFormat get selectedFormat => _selectedFormat.value;
  String get previewContent => _previewContent.value;

  // Alias pour compatibilité avec les vues
  Receipt? get selectedReceipt => _currentReceipt.value;
  bool get isReprinting => _isGenerating.value;

  // Getters pour la recherche et pagination
  int get totalReceipts => _totalReceipts.value;
  ReceiptFilterPreset? get activePreset => _activePreset.value;
  bool get hasActiveFilters => _currentFilter.value.hasFilters;
  int get activeFiltersCount => _currentFilter.value.activeFiltersCount;
  bool get hasMorePages => _hasMoreData.value;
  bool get hasPreviousPages => _currentPage.value > 1;

  @override
  void onInit() {
    super.onInit();
    _loadCompanyProfile();
    // Désactiver temporairement le chargement automatique des reçus pour éviter l'erreur
    // searchReceipts();
  }

  /// Charge le profil d'entreprise
  Future<void> _loadCompanyProfile() async {
    try {
      final response = await _companyService.getCompanyProfile();
      if (response.success && response.data != null) {
        _companyProfile.value = response.data;
        print('✅ Profil d\'entreprise chargé pour l\'impression');
      } else {
        print('⚠️ Aucun profil d\'entreprise configuré');
      }
    } catch (e) {
      print('❌ Erreur lors du chargement du profil d\'entreprise: $e');
    }
  }

  /// Recherche des reçus
  Future<void> searchReceipts({bool refresh = false}) async {
    if (refresh) {
      _currentPage.value = 1;
      _hasMoreData.value = true;
      _receipts.clear();
    }

    if (!_hasMoreData.value) return;

    _isSearching.value = true;

    try {
      final searchCriteria = ReceiptSearchCriteria(
        saleNumber: _searchQuery.value.isNotEmpty ? _searchQuery.value : null,
        customerName: _currentFilter.value.customerNamePattern,
        startDate: _currentFilter.value.dateRange?.start,
        endDate: _currentFilter.value.dateRange?.end,
        isReprint: _currentFilter.value.reprintStatus == ReprintStatus.reprintsOnly,
      );

      final sortOptions = ReceiptSortOptions.defaultSort();

      final paginationOptions = ReceiptPaginationOptions(
        page: _currentPage.value,
        limit: 20,
      );

      final request = ReceiptSearchRequest(
        criteria: searchCriteria,
        sortOptions: sortOptions,
        paginationOptions: paginationOptions,
      );

      final response = await _printingService.searchReceipts(request: request);

      if (response.success && response.data != null) {
        final searchResponse = response.data!;

        if (refresh) {
          _receipts.assignAll(searchResponse.receipts);
        } else {
          _receipts.addAll(searchResponse.receipts);
        }

        _currentPage.value = searchResponse.currentPage;
        _totalPages.value = searchResponse.totalPages;
        _hasMoreData.value = searchResponse.hasNextPage;
        _totalReceipts.value = searchResponse.totalCount;
      } else {
        SnackbarUtils.showError(response.message ?? 'Erreur lors de la recherche des reçus');
      }
    } catch (e) {
      print('❌ Erreur recherche reçus: $e');

      // Gestion spécifique des erreurs de cast
      if (e.toString().contains('type \'Null\' is not a subtype of type \'String\'')) {
        SnackbarUtils.showError('Données de reçus corrompues. Contactez l\'administrateur.');
      } else if (e.toString().contains('Connection refused') || e.toString().contains('Failed host lookup')) {
        SnackbarUtils.showError('Impossible de se connecter au serveur des reçus');
      } else {
        SnackbarUtils.showError('Erreur lors de la recherche des reçus: ${e.toString().substring(0, 50)}...');
      }
    } finally {
      _isSearching.value = false;
    }
  }

  /// Charge plus de reçus (pagination)
  Future<void> loadMoreReceipts() async {
    if (_hasMoreData.value && !_isSearching.value) {
      _currentPage.value++;
      await searchReceipts();
    }
  }

  /// Récupère un reçu par son ID
  Future<void> getReceiptById(String receiptId) async {
    _isLoading.value = true;

    try {
      final response = await _printingService.getReceiptById(receiptId);
      if (response.success && response.data != null) {
        _currentReceipt.value = response.data;
      } else {
        SnackbarUtils.showError(response.message ?? 'Erreur lors de la récupération du reçu');
      }
    } catch (e) {
      SnackbarUtils.showError('Erreur lors de la récupération du reçu');
      print('❌ Erreur récupération reçu: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Récupère un reçu par ID de vente
  Future<void> getReceiptBySaleId(String saleId) async {
    _isLoading.value = true;

    try {
      final response = await _printingService.getReceiptBySaleId(saleId);
      if (response.success && response.data != null) {
        _currentReceipt.value = response.data;
      } else {
        SnackbarUtils.showError(response.message ?? 'Aucun reçu trouvé pour cette vente');
      }
    } catch (e) {
      SnackbarUtils.showError('Erreur lors de la récupération du reçu');
      print('❌ Erreur récupération reçu par vente: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Génère un nouveau reçu pour une vente
  Future<bool> generateReceiptForSale(String saleId, {PrintFormat? format, CompanyProfile? companyProfile}) async {
    _isGenerating.value = true;

    try {
      // Utiliser le profil d'entreprise passé en paramètre s'il est disponible
      if (companyProfile != null) {
        _companyProfile.value = companyProfile;
        // Définir le profil partagé pour le service d'impression
        PrintingService.setCompanyProfile(companyProfile);
        print('📋 Utilisation du profil d\'entreprise fourni: ${companyProfile.name}');
      } else {
        SnackbarUtils.showError('Profil d\'entreprise non configuré\n'
            'Allez dans Paramètres > Entreprise pour configurer les informations de votre entreprise');
        return false;
      }

      final request = GenerateReceiptRequest(
        saleId: saleId,
        format: format ?? _selectedFormat.value,
        includeCompanyInfo: true, // Toujours inclure les infos d'entreprise
      );

      final response = await _printingService.generateReceipt(request: request);

      if (response.success && response.data != null) {
        // Stocker le reçu généré
        _currentReceipt.value = response.data!.receipt;

        SnackbarUtils.showSuccess('Reçu généré avec succès');

        // Rafraîchir la liste des reçus
        await searchReceipts(refresh: true);

        return true;
      } else {
        SnackbarUtils.showError(response.message ?? 'Erreur lors de la génération du reçu');
        return false;
      }
    } catch (e) {
      SnackbarUtils.showError('Erreur lors de la génération du reçu');
      print('❌ Erreur génération reçu: $e');
      return false;
    } finally {
      _isGenerating.value = false;
    }
  }

  /// Génère la prévisualisation d'un reçu
  Widget generatePreview(Receipt receipt, PrintFormat format) {
    try {
      _selectedFormat.value = format;

      return _previewService.createPreviewWidget(
        receipt: receipt.copyWith(format: format),
        showFormatInfo: true,
      );
    } catch (e) {
      SnackbarUtils.showError('Erreur lors de la génération de la prévisualisation');
      print('❌ Erreur prévisualisation: $e');
      return const Center(
        child: Text('Erreur de prévisualisation'),
      );
    }
  }

  /// Met à jour la requête de recherche
  void setSearchQuery(String query) {
    _searchQuery.value = query;
  }

  /// Applique les filtres de recherche
  void applyFilter(ReceiptAdvancedFilter filter) {
    _currentFilter.value = filter;
    searchReceipts(refresh: true);
  }

  /// Efface les filtres
  void clearFilters() {
    _currentFilter.value = ReceiptAdvancedFilter.empty();
    _searchQuery.value = '';
    searchReceipts(refresh: true);
  }

  /// Change le format sélectionné
  void setSelectedFormat(PrintFormat format) {
    _selectedFormat.value = format;
  }

  /// Rafraîchit le profil d'entreprise
  Future<void> refreshCompanyProfile() async {
    await _loadCompanyProfile();
  }

  /// Efface le reçu actuel
  void clearCurrentReceipt() {
    _currentReceipt.value = null;
    _previewContent.value = '';
  }

  /// Sélectionne un reçu pour affichage détaillé
  void selectReceipt(Receipt receipt) {
    _currentReceipt.value = receipt;
  }

  /// Vérifie si un reçu peut être réimprimé
  bool canReprintReceipt(Receipt receipt) {
    // Logique métier pour déterminer si un reçu peut être réimprimé
    // Par exemple, vérifier les permissions, l'âge du reçu, etc.
    return true; // Pour l'instant, tous les reçus peuvent être réimprimés
  }

  /// Obtient la liste des formats disponibles
  List<PrintFormat> getAvailableFormats() {
    return PrintFormat.values;
  }

  /// Méthodes pour la gestion des filtres prédéfinis
  List<ReceiptFilterPreset> getAvailablePresets() {
    return ReceiptFilterPreset.values;
  }

  void applyPresetFilter(ReceiptFilterPreset preset) {
    _activePreset.value = preset;
    _currentFilter.value = preset.apply();
    searchReceipts(refresh: true);
  }

  /// Méthodes de recherche et filtrage
  void clearSearchCriteria() {
    searchController.clear();
    saleNumberController.clear();
    customerNameController.clear();
    _searchQuery.value = '';
    _currentFilter.value = ReceiptAdvancedFilter.empty();
    _activePreset.value = null;
    searchReceipts(refresh: true);
  }

  void updateSearchCriteria({
    String? saleNumber,
    String? customerName,
  }) {
    _searchQuery.value = saleNumber ?? '';
    _currentFilter.value = _currentFilter.value.copyWith(
      saleNumberPattern: saleNumber?.isNotEmpty == true ? saleNumber : null,
      customerNamePattern: customerName?.isNotEmpty == true ? customerName : null,
    );
  }

  /// Méthodes de pagination
  void loadNextPage() {
    if (_hasMoreData.value && !_isSearching.value) {
      _currentPage.value++;
      searchReceipts();
    }
  }

  void loadPreviousPage() {
    if (_currentPage.value > 1 && !_isSearching.value) {
      _currentPage.value--;
      searchReceipts();
    }
  }

  /// Méthode de rafraîchissement
  Future<void> refresh() async {
    await searchReceipts(refresh: true);
  }

  /// Imprime directement le reçu sur l'imprimante avec boîte de dialogue
  Future<void> printReceiptDirect(Receipt receipt) async {
    try {
      print('🖨️ Impression du reçu ${receipt.saleNumber}');

      // Générer le PDF du reçu
      final pdf = await _generateReceiptPdf(receipt);

      // Afficher la boîte de dialogue d'impression et imprimer
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf,
        name: 'Reçu ${receipt.saleNumber}',
      );

      print('✅ Impression lancée');
    } catch (e) {
      print('❌ Erreur impression directe: $e');
      SnackbarUtils.showError('Erreur lors de l\'impression: $e');
    }
  }

  /// Génère le PDF du reçu en utilisant les templates prédéfinis
  Future<Uint8List> _generateReceiptPdf(Receipt receipt) async {
    try {
      // Générer directement un PDF formaté selon les templates prédéfinis
      return await _generateFallbackPdf(receipt);
    } catch (e) {
      print('❌ Erreur génération PDF: $e');
      rethrow;
    }
  }

  /// Génère un PDF de secours si la génération normale échoue
  Future<Uint8List> _generateFallbackPdf(Receipt receipt) async {
    final pdf = pw.Document();

    // Déterminer la taille de la page selon le format
    late PdfPageFormat pageFormat;
    switch (_selectedFormat.value) {
      case PrintFormat.thermal:
        pageFormat = PdfPageFormat.roll80;
        break;
      case PrintFormat.a5:
        pageFormat = PdfPageFormat.a5;
        break;
      case PrintFormat.a4:
        pageFormat = PdfPageFormat.a4;
        break;
    }

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: pw.EdgeInsets.all(8),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // En-tête
              pw.Text(
                _companyProfile.value?.name ?? 'ENTREPRISE',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 6),

              // Titre reçu
              pw.Text(
                'Recu de vente',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 8),

              // Informations du reçu
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('N° Vente: ${receipt.saleNumber}', style: pw.TextStyle(fontSize: 9)),
                    pw.Text('Date: ${receipt.saleDate.day.toString().padLeft(2, '0')}/${receipt.saleDate.month.toString().padLeft(2, '0')}/${receipt.saleDate.year}', style: pw.TextStyle(fontSize: 9)),
                    pw.Text('Heure: ${receipt.saleDate.hour.toString().padLeft(2, '0')}:${receipt.saleDate.minute.toString().padLeft(2, '0')}', style: pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ),
              pw.SizedBox(height: 8),

              // Ligne de séparation
              pw.Divider(),
              pw.SizedBox(height: 4),

              // Articles
              if (receipt.items.isNotEmpty)
                pw.Column(
                  children: [
                    pw.Table(
                      border: pw.TableBorder.all(width: 0.5),
                      children: [
                        // En-tête
                        pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: pw.EdgeInsets.all(3),
                              child: pw.Text('Désignation', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                            ),
                            pw.Padding(
                              padding: pw.EdgeInsets.all(3),
                              child: pw.Text('Qté', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                            ),
                            pw.Padding(
                              padding: pw.EdgeInsets.all(3),
                              child: pw.Text('P.U.', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                            ),
                            pw.Padding(
                              padding: pw.EdgeInsets.all(3),
                              child: pw.Text('Montant', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                            ),
                          ],
                        ),
                        // Articles
                        ...receipt.items.map((item) => pw.TableRow(
                              children: [
                                pw.Padding(
                                  padding: pw.EdgeInsets.all(3),
                                  child: pw.Text(item.productName.length > 20 ? '${item.productName.substring(0, 17)}...' : item.productName, style: pw.TextStyle(fontSize: 8)),
                                ),
                                pw.Padding(
                                  padding: pw.EdgeInsets.all(3),
                                  child: pw.Text('${item.quantity}', style: pw.TextStyle(fontSize: 8)),
                                ),
                                pw.Padding(
                                  padding: pw.EdgeInsets.all(3),
                                  child: pw.Text('${item.unitPrice.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 8)),
                                ),
                                pw.Padding(
                                  padding: pw.EdgeInsets.all(3),
                                  child: pw.Text('${item.totalPrice.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 8)),
                                ),
                              ],
                            )),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                  ],
                ),

              // Ligne de séparation
              pw.Divider(),
              pw.SizedBox(height: 4),

              // Totaux
              pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Total:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('${receipt.totalAmount.toStringAsFixed(0)} FCFA', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Payé:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('${receipt.paidAmount.toStringAsFixed(0)} FCFA', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  if (receipt.remainingAmount > 0)
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Reste:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text('${receipt.remainingAmount.toStringAsFixed(0)} FCFA', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ],
                    )
                  else if (receipt.paidAmount > receipt.totalAmount)
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Monnaie:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text('${(receipt.paidAmount - receipt.totalAmount).toStringAsFixed(0)} FCFA', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                ],
              ),
              pw.SizedBox(height: 8),

              // Pied de page
              pw.Divider(),
              pw.SizedBox(height: 4),
              pw.Text(
                'Merci pour votre achat!',
                style: pw.TextStyle(fontSize: 9),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 20),
            ],
          );
        },
      ),
    );

    return Uint8List.fromList(await pdf.save());
  }

  @override
  void onClose() {
    searchController.dispose();
    saleNumberController.dispose();
    customerNameController.dispose();
    super.onClose();
  }
}
