import 'package:get/get.dart';
import 'dart:typed_data';

import '../models/receipt_model.dart';
import '../models/print_format.dart' as print_models;
import '../widgets/receipt_template_factory.dart';
import '../../company_settings/models/company_profile.dart';
import '../../sales/models/sale.dart';
import '../../customers/models/customer.dart';

/// Service pour la génération de reçus dans différents formats
class ReceiptGenerationService {
  /// Génère un reçu à partir d'une vente
  Future<ReceiptGenerationResponse> generateReceiptFromSale({
    required Sale sale,
    required CompanyProfile companyInfo,
    print_models.PrintFormat format = print_models.PrintFormat.a4,
    print_models.PrintTemplate? customTemplate,
  }) async {
    try {
      // Créer le modèle de reçu
      final receipt = Receipt.fromSale(
        sale: sale,
        companyInfo: companyInfo,
        format: format,
      );

      return await generateReceipt(
        receipt: receipt,
        customTemplate: customTemplate,
      );
    } catch (e) {
      return ReceiptGenerationResponse.error(
        receipt: Receipt.fromSale(
          sale: sale,
          companyInfo: companyInfo,
          format: format,
        ),
        error: 'printing_erreur_lors_generation_recu_3'.trParams({'e': '${e}'}),
      );
    }
  }

  /// Génère un reçu pour un approvisionnement de compte
  Future<ReceiptGenerationResponse> generateDepositReceipt({
    required int clientId,
    required Customer customer,
    required double depositAmount,
    required double initialBalance,
    required double finalBalance,
    required CompanyProfile companyInfo,
    String? note,
    print_models.PrintFormat format = print_models.PrintFormat.thermal,
    print_models.PrintTemplate? customTemplate,
  }) async {
    try {
      // Créer le modèle de reçu d'approvisionnement
      final receipt = Receipt.fromDeposit(
        clientId: clientId,
        customer: customer,
        depositAmount: depositAmount,
        initialBalance: initialBalance,
        finalBalance: finalBalance,
        companyInfo: companyInfo,
        note: note,
        format: format,
      );

      return await generateReceipt(
        receipt: receipt,
        customTemplate: customTemplate,
      );
    } catch (e) {
      return ReceiptGenerationResponse.error(
        receipt: Receipt.fromDeposit(
          clientId: clientId,
          customer: customer,
          depositAmount: depositAmount,
          initialBalance: initialBalance,
          finalBalance: finalBalance,
          companyInfo: companyInfo,
          note: note,
          format: format,
        ),
        error: 'printing_erreur_lors_generation_recu_approvisionnement'.trParams({'e': '${e}'}),
      );
    }
  }

  /// Génère un reçu complet avec le format approprié
  Future<ReceiptGenerationResponse> generateReceipt({
    required Receipt receipt,
    print_models.PrintTemplate? customTemplate,
  }) async {
    try {
      // Valider les données
      if (!_validateReceiptData(receipt)) {
        return ReceiptGenerationResponse.error(
          receipt: receipt,
          error: 'printing_donnees_recu_invalides'.tr,
        );
      }

      switch (receipt.format) {
        case print_models.PrintFormat.a4:
        case print_models.PrintFormat.a5:
        case print_models.PrintFormat.matriciel:
          return await _generatePdfReceipt(receipt, customTemplate);

        case print_models.PrintFormat.thermal:
          return await _generateThermalReceipt(receipt, customTemplate);
      }
    } catch (e) {
      return ReceiptGenerationResponse.error(
        receipt: receipt,
        error: 'printing_erreur_lors_generation'.trParams({'e': '${e}'}),
      );
    }
  }

  /// Génère un reçu PDF pour formats A4/A5
  Future<ReceiptGenerationResponse> _generatePdfReceipt(
    Receipt receipt,
    print_models.PrintTemplate? customTemplate,
  ) async {
    try {
      // Pour l'instant, on simule la génération PDF
      // Dans un vrai projet, on utiliserait une bibliothèque PDF comme pdf ou printing
      final pdfUrl = 'receipts/${receipt.id}.pdf';

      return ReceiptGenerationResponse.success(
        receipt: receipt,
        pdfUrl: pdfUrl,
      );
    } catch (e) {
      return ReceiptGenerationResponse.error(
        receipt: receipt,
        error: 'printing_erreur_generation_pdf'.trParams({'e': '${e}'}),
      );
    }
  }

  /// Génère un reçu thermique
  Future<ReceiptGenerationResponse> _generateThermalReceipt(
    Receipt receipt,
    print_models.PrintTemplate? customTemplate,
  ) async {
    try {
      // Générer les données d'impression thermique
      final thermalData = _generateThermalPrintData(receipt, customTemplate);

      return ReceiptGenerationResponse.success(
        receipt: receipt,
        thermalData: thermalData,
      );
    } catch (e) {
      return ReceiptGenerationResponse.error(
        receipt: receipt,
        error: 'printing_erreur_generation_thermique'.trParams({'e': '${e}'}),
      );
    }
  }

  /// Génère les données d'impression thermique (commandes ESC/POS)
  String _generateThermalPrintData(Receipt receipt, print_models.PrintTemplate? customTemplate) {
    final buffer = StringBuffer();

    // DEBUG - Vérifier les données de paiement
    // print('️ [THERMAL] Génération données thermiques');
    // print('️ [THERMAL] Receipt ID: ${receipt.id}');
    // print('️ [THERMAL] Total: ${receipt.totalAmount}');
    // print('️ [THERMAL] Paid: ${receipt.paidAmount}');
    // print('️ [THERMAL] Remaining: ${receipt.remainingAmount}');
    // print('️ [THERMAL] isReprint: ${receipt.isReprint}');

    // Commandes ESC/POS pour imprimante thermique
    buffer.writeln('\x1B\x40'); // Initialiser l'imprimante
    buffer.writeln('\x1B\x61\x01'); // Centrer le texte

    // En-tête entreprise
    buffer.writeln('\x1B\x21\x30'); // Double hauteur et largeur
    buffer.writeln(receipt.companyInfo.name.toUpperCase());
    buffer.writeln('\x1B\x21\x00'); // Taille normale

    if (receipt.companyInfo.address.isNotEmpty) {
      buffer.writeln(receipt.companyInfo.address);
    }

    if (receipt.companyInfo.location?.isNotEmpty == true) {
      buffer.writeln(receipt.companyInfo.location!);
    }

    if (receipt.companyInfo.phone?.isNotEmpty == true) {
      buffer.writeln('Tel: ${receipt.companyInfo.phone}');
    }

    if (receipt.companyInfo.nuiRccm?.isNotEmpty == true) {
      buffer.writeln('NUI: ${receipt.companyInfo.nuiRccm}');
    }

    // Séparateur
    buffer.writeln('================================');

    // Titre du reçu
    buffer.writeln('\x1B\x21\x10'); // Double hauteur
    // Afficher le type de reçu selon le contexte
    if (receipt.saleNumber.startsWith('DEP-')) {
      buffer.writeln('RECU D\'APPROVISIONNEMENT');
    } else if (receipt.saleNumber.startsWith('SUI-')) {
      buffer.writeln('printing_recu_suivi_compte_2'.tr);
    } else if (receipt.isProforma) {
      buffer.writeln('FACTURE PROFORMA');
    } else {
      buffer.writeln('printing_recu_vente_2'.tr);
    }
    buffer.writeln('\x1B\x21\x00'); // Taille normale

    // Indicateur de réimpression
    if (receipt.isReprint && receipt.reprintIndicator.isNotEmpty) {
      buffer.writeln(receipt.reprintIndicator);
    }

    buffer.writeln('================================');

    // Informations de vente
    buffer.writeln('\x1B\x61\x00'); // Aligner à gauche
    // Afficher le numéro selon le type de reçu
    if (receipt.saleNumber.startsWith('DEP-')) {
      buffer.writeln('printing_n_depot_2'.trParams({'saleNumber': '${receipt.saleNumber}'}));
    } else if (receipt.saleNumber.startsWith('SUI-')) {
      buffer.writeln('N° Suivi:${receipt.saleNumber}');
    } else {
      buffer.writeln('printing_n_vente_2'.trParams({'saleNumber': '${receipt.saleNumber}'}));
    }
    buffer.writeln('Date:${receipt.saleDate.day.toString().padLeft(2, '0')}/'
        '${receipt.saleDate.month.toString().padLeft(2, '0')}/'
        '${receipt.saleDate.year}');
    buffer.writeln('Heure:${receipt.saleDate.hour.toString().padLeft(2, '0')}:'
        '${receipt.saleDate.minute.toString().padLeft(2, '0')}');

    if (receipt.customer != null) {
      // Tronquer le nom du client à 15 caractères comme dans l'aperçu
      final customerName = receipt.customer!.nom.length > 15 ? '${receipt.customer!.nom.substring(0, 12)}...' : receipt.customer!.nom;
      buffer.writeln('printing_client_2'.trParams({'customerName': '${customerName}'}));

      // Afficher NUI si renseigné
      if (receipt.customer!.nui?.isNotEmpty == true) {
        buffer.writeln('NUI:${receipt.customer!.nui}');
      }

      // Afficher RCCM si renseigné
      if (receipt.customer!.rccm?.isNotEmpty == true) {
        buffer.writeln('RCCM:${receipt.customer!.rccm}');
      }
    }

    buffer.writeln('Paiement:${receipt.paymentMethod}');

    buffer.writeln('================================');

    // Articles ou informations de solde
    if (receipt.saleNumber.startsWith('DEP-') || receipt.saleNumber.startsWith('SUI-')) {
      // Pour les approvisionnements et suivis de compte, afficher les informations de solde
      buffer.writeln('DETAILS:');
      buffer.writeln('');

      final item = receipt.items.first;
      // displayPrice contient le solde initial, discountAmount contient le solde final
      final initialBalance = item.displayPrice;
      final finalBalance = item.discountAmount;

      buffer.writeln('Solde initial: ${initialBalance.toStringAsFixed(0)} FCFA');
      buffer.writeln('');
      buffer.writeln('Solde final: ${finalBalance.toStringAsFixed(0)} FCFA');
      buffer.writeln('');

      // Pour les suivis de compte, afficher la référence de vente
      if (receipt.saleNumber.startsWith('SUI-') && item.productReference.isNotEmpty) {
        buffer.writeln(item.productReference);
        buffer.writeln('');
      }

      // Afficher la note si présente (pour les approvisionnements)
      if (receipt.saleNumber.startsWith('DEP-') && item.productReference.isNotEmpty && !item.productReference.contains('Approvisionnement de compte')) {
        buffer.writeln('Note: ${item.productReference}');
        buffer.writeln('');
      }
    } else {
      // Pour les ventes normales, afficher les articles
      buffer.writeln('ARTICLES:');
      buffer.writeln('');

      for (int i = 0; i < receipt.items.length; i++) {
        final item = receipt.items[i];
        // Tronquer le nom du produit à 20 caractères
        final productName = item.productName.length > 20 ? '${item.productName.substring(0, 17)}...' : item.productName;
        // Ajouter la référence entre parenthèses sur la même ligne
        final ref = item.productReference.isNotEmpty ? ' (${item.productReference})' : '';
        buffer.writeln('${i + 1}. $productName$ref');
        buffer.writeln('   ${item.quantity} x ${item.formattedUnitPrice} = ${item.formattedTotalPrice}');
        buffer.writeln('');
      }
    }

    buffer.writeln('--------------------------------');

    // Totaux
    if (receipt.saleNumber.startsWith('DEP-')) {
      // Pour les approvisionnements
      buffer.writeln('\x1B\x21\x10'); // Double hauteur
      buffer.writeln('printing_montant_verse_fcfa'.trParams({'toStringAsFixed': '${receipt.totalAmount.toStringAsFixed(0)}'}));
      buffer.writeln('\x1B\x21\x00'); // Taille normale
    } else if (receipt.saleNumber.startsWith('SUI-')) {
      // Pour les suivis de compte
      buffer.writeln('\x1B\x21\x10'); // Double hauteur
      buffer.writeln('printing_montant_utilise_fcfa'.trParams({'toStringAsFixed': '${receipt.totalAmount.toStringAsFixed(0)}'}));
      buffer.writeln('\x1B\x21\x00'); // Taille normale
    } else {
      // Pour les ventes normales
      buffer.writeln('Sous-total: ${receipt.subtotal.toStringAsFixed(0)} FCFA');

      if (receipt.discountAmount > 0) {
        buffer.writeln('Remise: -${receipt.discountAmount.toStringAsFixed(0)} FCFA');
      }

      buffer.writeln('--------------------------------');
      buffer.writeln('\x1B\x21\x10'); // Double hauteur
      buffer.writeln('TOTAL: ${receipt.totalAmount.toStringAsFixed(0)} FCFA');
      buffer.writeln('\x1B\x21\x00'); // Taille normale
      buffer.writeln('Paye: ${receipt.paidAmount.toStringAsFixed(0)} FCFA');

      // CORRECTION : Afficher la monnaie si le montant payé > total
      if (receipt.paidAmount > receipt.totalAmount) {
        final change = (receipt.paidAmount - receipt.totalAmount).toStringAsFixed(0);
        print('🖨️ [THERMAL] Affichage Monnaie: $change FCFA');
        buffer.writeln('Monnaie: $change FCFA');
      } else {
        print('🖨️ [THERMAL] Pas de monnaie (Paid: ${receipt.paidAmount}, Total: ${receipt.totalAmount})');
      }

      // CORRECTION : Afficher le reste si > 0
      if (receipt.remainingAmount > 0) {
        final remaining = receipt.remainingAmount.toStringAsFixed(0);
        print('🖨️ [THERMAL] Affichage Reste: $remaining FCFA');
        buffer.writeln('Reste: $remaining FCFA');
      } else {
        print('🖨️ [THERMAL] Pas de reste (Remaining: ${receipt.remainingAmount})');
      }
    }

    buffer.writeln('================================');

    // Pied de page
    buffer.writeln('\x1B\x61\x01'); // Centrer
    buffer.writeln('\x1B\x21\x10'); // Double hauteur
    buffer.writeln('printing_merci_votre_confiance'.tr);
    buffer.writeln('\x1B\x21\x00'); // Taille normale

    // Informations de réimpression
    if (receipt.isReprint && receipt.lastReprintDate != null) {
      buffer.writeln('');
      buffer.writeln('Reimprime le ${receipt.lastReprintDate!.day.toString().padLeft(2, '0')}/'
          '${receipt.lastReprintDate!.month.toString().padLeft(2, '0')}/'
          '${receipt.lastReprintDate!.year}');

      if (receipt.reprintBy?.isNotEmpty == true) {
        buffer.writeln('printing_par'.trParams({'reprintBy': '${receipt.reprintBy}'}));
      }
    }

    buffer.writeln('');

    // Couper le papier
    buffer.writeln('\x1D\x56\x00');

    return buffer.toString();
  }

  /// Valide les données avant génération
  bool _validateReceiptData(Receipt receipt) {
    if (receipt.items.isEmpty) return false;
    if (receipt.companyInfo.name.isEmpty) return false;
    if (receipt.saleNumber.isEmpty) return false;
    return true;
  }

  /// Génère un aperçu du reçu pour l'interface utilisateur
  Future<Uint8List?> generatePreviewImage({
    required Receipt receipt,
    print_models.PrintTemplate? customTemplate,
    double scale = 1.0,
  }) async {
    try {
      // Pour l'instant, on retourne null
      // Dans un vrai projet, on convertirait le widget en image
      return null;
    } catch (e) {
      print('Erreur génération aperçu: $e');
      return null;
    }
  }

  /// Estime la taille du fichier généré
  int estimateFileSize({
    required Receipt receipt,
    required print_models.PrintFormat format,
  }) {
    switch (format) {
      case print_models.PrintFormat.a4:
        return 50000; // ~50KB pour un PDF A4
      case print_models.PrintFormat.a5:
        return 30000; // ~30KB pour un PDF A5
      case print_models.PrintFormat.thermal:
        return 2000; // ~2KB pour les données thermiques
      case print_models.PrintFormat.matriciel:
        return 40000; // ~40KB pour un PDF matriciel (texte pur, sans images)
    }
  }

  /// Obtient les formats supportés
  List<print_models.PrintFormat> getSupportedFormats() {
    return ReceiptTemplateFactory.getSupportedFormats();
  }

  /// Vérifie si un format nécessite une génération PDF
  bool requiresPdfGeneration(print_models.PrintFormat format) {
    return ReceiptTemplateFactory.requiresPdfGeneration(format);
  }
}
