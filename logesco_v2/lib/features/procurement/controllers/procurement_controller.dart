/**
 * Contrôleur GetX pour la gestion des approvisionnements
 */

import 'dart:async';
import 'package:get/get.dart';
import 'package:logesco_v2/features/suppliers/models/supplier.dart';
// import '../../../core/models/product_model.dart';
// import '../../../core/models/supplier_model.dart';
import '../../products/models/product.dart';
import '../models/procurement_models.dart';
import '../services/procurement_service.dart';
import '../services/pdf_export_service.dart';
import '../services/suggestion_service.dart';

class ProcurementController extends GetxController {
  final ProcurementService _procurementService;
  final ProcurementSuggestionService _suggestionService = ProcurementSuggestionService();

  ProcurementController(this._procurementService);

  // État des commandes
  final RxList<CommandeApprovisionnement> commandes = <CommandeApprovisionnement>[].obs;
  final Rx<CommandeApprovisionnement?> commandeSelectionnee = Rx<CommandeApprovisionnement?>(null);

  // État de chargement
  final RxBool isLoading = false.obs;
  final RxBool isCreating = false.obs;
  final RxBool isUpdating = false.obs;

  // Filtres
  final Rx<Supplier?> fournisseurFiltre = Rx<Supplier?>(null);
  final Rx<CommandeStatut?> statutFiltre = Rx<CommandeStatut?>(null);
  final Rx<DateTime?> dateDebutFiltre = Rx<DateTime?>(null);
  final Rx<DateTime?> dateFinFiltre = Rx<DateTime?>(null);

  // Pagination
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxInt totalCommandes = 0.obs;
  final RxBool hasMoreCommandes = true.obs;

  // Nouvelle commande
  final Rx<Supplier?> fournisseurSelectionne = Rx<Supplier?>(null);
  final RxList<DetailCommandeCreation> detailsCommande = <DetailCommandeCreation>[].obs;
  final Rx<DateTime?> dateLivraisonPrevue = Rx<DateTime?>(null);
  final Rx<ModePaiement> modePaiement = ModePaiement.credit.obs;
  final RxString notes = ''.obs;

  // Alertes
  final RxList<Map<String, dynamic>> alertes = <Map<String, dynamic>>[].obs;
  final RxInt nombreAlertes = 0.obs;

  // Suggestions d'approvisionnement
  final RxList<SuggestionApprovisionnement> suggestions = <SuggestionApprovisionnement>[].obs;
  final RxBool isLoadingSuggestions = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadCommandes();
    loadAlertes();
  }

  /// Charge la liste des commandes avec filtres
  Future<void> loadCommandes({bool refresh = false}) async {
    if (refresh) currentPage.value = 1;

    if (!hasMoreCommandes.value && !refresh) return;

    try {
      isLoading.value = currentPage.value == 1;

      final result = await _procurementService.getCommandes(
        fournisseurId: fournisseurFiltre.value?.id,
        statut: statutFiltre.value?.value,
        dateDebut: dateDebutFiltre.value,
        dateFin: dateFinFiltre.value,
        page: currentPage.value,
      );

      final commandesList = result['commandes'] as List<CommandeApprovisionnement>;
      final pagination = result['pagination'] as Map<String, dynamic>;

      print('🔍 DONNÉES REÇUES: ${commandesList.length} commandes');
      print('   - Total pagination: ${pagination['total']}');
      print('   - Page actuelle: ${pagination['page']}/${pagination['pages']}');

      totalCommandes.value = pagination['total'] as int;
      totalPages.value = pagination['pages'] as int;
      hasMoreCommandes.value = (pagination['page'] as int) < (pagination['pages'] as int);

      if (refresh) {
        commandes.assignAll(commandesList);
        print('✅ LISTE ASSIGNÉE: ${commandes.length} commandes affichées');
      } else {
        commandes.addAll(commandesList);
        print('✅ LISTE AJOUTÉE: ${commandes.length} commandes total (page ${currentPage.value})');
      }

      currentPage.value++;
    } catch (e) {
      print('❌ ERREUR CHARGEMENT: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de charger les commandes: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Charge une commande spécifique
  Future<void> loadCommande(int id) async {
    try {
      isLoading.value = true;

      final commande = await _procurementService.getCommande(id);
      commandeSelectionnee.value = commande;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de charger la commande: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Crée une nouvelle commande
  Future<bool> createCommande() async {
    if (fournisseurSelectionne.value == null || detailsCommande.isEmpty) {
      Get.snackbar(
        'Erreur',
        'Veuillez sélectionner un fournisseur et ajouter des produits',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    try {
      isCreating.value = true;

      final details = detailsCommande
          .map((detail) => {
                'produitId': detail.produit.id,
                'quantiteCommandee': detail.quantite,
                'coutUnitaire': detail.coutUnitaire,
              })
          .toList();

      final commande = await _procurementService.createCommande(
        fournisseurId: fournisseurSelectionne.value!.id,
        dateLivraisonPrevue: dateLivraisonPrevue.value,
        modePaiement: modePaiement.value.value,
        notes: notes.value.isNotEmpty ? notes.value : null,
        details: details,
      );

      commandes.insert(0, commande);
      resetNouvelleCommande();

      Get.snackbar(
        'Succès',
        'Commande créée avec succès',
        snackPosition: SnackPosition.BOTTOM,
      );

      return true;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de créer la commande: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isCreating.value = false;
    }
  }

  ///
//Réceptionne une commande
  Future<bool> recevoirCommande(int commandeId, List<Map<String, dynamic>> details) async {
    try {
      isUpdating.value = true;

      final commande = await _procurementService.recevoirCommande(commandeId, details);

      // Mettre à jour la commande dans la liste
      final index = commandes.indexWhere((c) => c.id == commandeId);
      if (index != -1) {
        commandes[index] = commande;
      }

      // Mettre à jour la commande sélectionnée si c'est la même
      if (commandeSelectionnee.value?.id == commandeId) {
        commandeSelectionnee.value = commande;
      }

      Get.snackbar(
        'Succès',
        'Réception enregistrée avec succès',
        snackPosition: SnackPosition.BOTTOM,
      );

      // Recharger les alertes car le stock a changé
      loadAlertes();

      return true;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible d\'enregistrer la réception: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isUpdating.value = false;
    }
  }

  /// Annule une commande
  Future<bool> annulerCommande(int commandeId) async {
    try {
      isUpdating.value = true;

      final commande = await _procurementService.annulerCommande(commandeId);

      // Mettre à jour la commande dans la liste
      final index = commandes.indexWhere((c) => c.id == commandeId);
      if (index != -1) {
        commandes[index] = commande;
      }

      Get.snackbar(
        'Succès',
        'Commande annulée avec succès',
        snackPosition: SnackPosition.BOTTOM,
      );

      return true;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible d\'annuler la commande: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isUpdating.value = false;
    }
  }

  /// Charge les alertes d'approvisionnement
  Future<void> loadAlertes() async {
    try {
      final result = await _procurementService.getAlertes();

      // Conversion sécurisée de List<dynamic> vers List<Map<String, dynamic>>
      final alertesData = result['alertes'] as List<dynamic>? ?? [];
      final alertesConverties = alertesData.map((alerte) => Map<String, dynamic>.from(alerte as Map)).toList();

      alertes.assignAll(alertesConverties);
      nombreAlertes.value = result['statistiques']?['total'] ?? 0;
    } catch (e) {
      // Erreur silencieuse pour les alertes
      print('Erreur lors du chargement des alertes: $e');
    }
  }

  /// Ajoute un produit à la nouvelle commande
  void ajouterProduit(Product produit, int quantite, double coutUnitaire) {
    // Vérifier si le produit n'est pas déjà dans la liste
    final existingIndex = detailsCommande.indexWhere((d) => d.produit.id == produit.id);

    if (existingIndex != -1) {
      // Mettre à jour la quantité et le coût
      detailsCommande[existingIndex] = DetailCommandeCreation(
        produit: produit,
        quantite: quantite,
        coutUnitaire: coutUnitaire,
      );
    } else {
      // Ajouter un nouveau détail
      detailsCommande.add(DetailCommandeCreation(
        produit: produit,
        quantite: quantite,
        coutUnitaire: coutUnitaire,
      ));
    }
  }

  /// Supprime un produit de la nouvelle commande
  void supprimerProduit(int produitId) {
    detailsCommande.removeWhere((d) => d.produit.id == produitId);
  }

  /// Calcule le montant total de la nouvelle commande
  double get montantTotalNouvelleCommande {
    return detailsCommande.fold(0.0, (total, detail) => total + detail.montantTotal);
  }

  /// Remet à zéro la nouvelle commande
  void resetNouvelleCommande() {
    fournisseurSelectionne.value = null;
    detailsCommande.clear();
    dateLivraisonPrevue.value = null;
    modePaiement.value = ModePaiement.credit;
    notes.value = '';
  }

  /// Applique les filtres
  void appliquerFiltres() {
    currentPage.value = 1;
    loadCommandes(refresh: true);
  }

  /// Réinitialise les filtres
  void resetFiltres() {
    fournisseurFiltre.value = null;
    statutFiltre.value = null;
    dateDebutFiltre.value = null;
    dateFinFiltre.value = null;
    appliquerFiltres();
  }

  /// Charge la page suivante
  void loadNextPage() {
    if (currentPage.value < totalPages.value) {
      currentPage.value++;
      loadCommandes();
    }
  }

  /// Exporte une commande en PDF
  Future<String?> exportCommandeToPdf(CommandeApprovisionnement commande) async {
    try {
      final filePath = await ProcurementPdfExportService.exportCommandeToPdf(commande);

      Get.snackbar(
        'Succès',
        'Commande exportée en PDF',
        snackPosition: SnackPosition.BOTTOM,
      );

      return filePath;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible d\'exporter la commande: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }
  }

  /// Charge les suggestions d'approvisionnement
  Future<void> loadSuggestions({int? fournisseurId, int periodeAnalyse = 30}) async {
    try {
      isLoadingSuggestions.value = true;

      final result = await _suggestionService.getSuggestions(
        fournisseurId: fournisseurId,
        periodeAnalyse: periodeAnalyse,
      );

      suggestions.assignAll(result);
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de charger les suggestions: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoadingSuggestions.value = false;
    }
  }

  /// Génère une commande automatique basée sur les suggestions
  Future<bool> genererCommandeAutomatique({
    required int fournisseurId,
    required List<SuggestionApprovisionnement> suggestionsSelectionnees,
    String modePaiement = 'credit',
    DateTime? dateLivraisonPrevue,
    String? notes,
  }) async {
    try {
      isCreating.value = true;

      final result = await _suggestionService.genererCommandeAutomatique(
        fournisseurId: fournisseurId,
        suggestions: suggestionsSelectionnees,
        modePaiement: modePaiement,
        dateLivraisonPrevue: dateLivraisonPrevue,
        notes: notes,
      );

      // Ajouter la nouvelle commande à la liste
      if (result['commande'] != null) {
        final nouvelleCommande = CommandeApprovisionnement.fromJson(result['commande']);
        commandes.insert(0, nouvelleCommande);
      }

      Get.snackbar(
        'Succès',
        'Commande générée automatiquement avec succès',
        snackPosition: SnackPosition.BOTTOM,
      );

      // Recharger les suggestions pour mettre à jour les données
      loadSuggestions(fournisseurId: fournisseurId);

      return true;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de générer la commande: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isCreating.value = false;
    }
  }

  /// Filtre les suggestions par priorité
  List<SuggestionApprovisionnement> getSuggestionsByPriorite(String priorite) {
    return suggestions.where((s) => s.priorite == priorite).toList();
  }

  /// Récupère les suggestions urgentes
  List<SuggestionApprovisionnement> getSuggestionsUrgentes() {
    return suggestions.where((s) => s.estUrgente).toList();
  }

  /// Calcule le montant total des suggestions sélectionnées
  double calculerMontantSuggestions(List<SuggestionApprovisionnement> suggestionsSelectionnees) {
    return suggestionsSelectionnees.fold(0.0, (total, suggestion) => total + suggestion.montantTotal);
  }
}

/// Classe helper pour la création de détails de commande
class DetailCommandeCreation {
  final Product produit;
  final int quantite;
  final double coutUnitaire;

  DetailCommandeCreation({
    required this.produit,
    required this.quantite,
    required this.coutUnitaire,
  });

  double get montantTotal => quantite * coutUnitaire;
}
