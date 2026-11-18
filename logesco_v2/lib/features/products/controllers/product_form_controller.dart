import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logesco_v2/core/utils/snackbar_helper.dart';
import '../../../core/utils/exceptions.dart';
import '../models/product.dart';
import '../models/category_model.dart';
import '../services/api_product_service.dart';
import '../services/category_service.dart';
import '../../../shared/constants/currency.dart';

/// Contrôleur pour le formulaire de création/édition de produit
class ProductFormController extends GetxController {
  final ApiProductService _productService;
  final CategoryService _categoryService;

  /// Les services sont ceux de l'application ; des remplaçants peuvent être fournis (tests)
  ProductFormController({ApiProductService? productService, CategoryService? categoryService})
      : _productService = productService ?? Get.find<ApiProductService>(),
        _categoryService = categoryService ?? Get.find<CategoryService>();

  // Contrôleurs de formulaire
  late final TextEditingController referenceController;
  late final TextEditingController nomController;
  late final TextEditingController descriptionController;
  late final TextEditingController prixUnitaireController;
  late final TextEditingController prixAchatController;
  late final TextEditingController codeBarreController;
  late final TextEditingController categorieController;
  late final TextEditingController categorieSearchController;
  late final TextEditingController seuilStockController;
  late final TextEditingController remiseMaxController;

  // Clé du formulaire pour validation
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Observables
  final RxBool isLoading = false.obs;
  final RxBool estActif = true.obs;
  final RxBool estService = false.obs;

  /// Le type (produit / service) a-t-il été choisi ? En création, tant que ce n'est pas fait, le reste du
  /// formulaire reste caché. Toujours vrai en modification et en duplication (le type est connu).
  final RxBool typeDefini = false.obs;
  final RxBool gestionPeremption = false.obs;
  final RxList<Category> categories = <Category>[].obs;
  final RxList<Category> filteredCategories = <Category>[].obs;
  final RxString selectedCategory = ''.obs;
  final RxString categorieSearchText = ''.obs;
  final RxBool isEditing = false.obs;
  final Rx<Product?> editingProduct = Rx<Product?>(null);

  // Messages d'erreur pour validation
  final RxString referenceError = ''.obs;
  final RxString nomError = ''.obs;
  final RxString prixError = ''.obs;
  final RxString prixAchatError = ''.obs;
  final RxString seuilError = ''.obs;
  final RxString remiseMaxError = ''.obs;

  /// Avertissement (non bloquant) quand le prix de vente saisi est inférieur au prix d'achat saisi
  final RxString avertissementPrix = ''.obs;

  // Gestion de la référence automatique
  final RxBool isAutoReference = true.obs;
  final RxBool isGeneratingReference = false.obs;

  // Gestion de l'image produit
  final RxString currentImageUrl = ''.obs;
  final RxBool isUploadingImage = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeControllers();
    _initializeAsync();
  }

  /// Initialisation asynchrone
  Future<void> _initializeAsync() async {
    await _loadCategories();
    _checkIfEditing();

    // Générer une référence automatique si on est en mode création
    if (!isEditing.value) {
      await generateReference();
    }
  }

  @override
  void onClose() {
    _disposeControllers();
    super.onClose();
  }

  /// Initialise les contrôleurs de texte
  void _initializeControllers() {
    referenceController = TextEditingController();
    nomController = TextEditingController();
    descriptionController = TextEditingController();
    prixUnitaireController = TextEditingController();
    prixAchatController = TextEditingController();
    codeBarreController = TextEditingController();
    categorieController = TextEditingController();
    categorieSearchController = TextEditingController();
    seuilStockController = TextEditingController(text: '0');
    remiseMaxController = TextEditingController(text: '0');

    // Écouter les changements pour validation en temps réel
    referenceController.addListener(_validateReference);
    nomController.addListener(_validateNom);
    prixUnitaireController.addListener(_validatePrix);
    prixAchatController.addListener(_validatePrixAchat);
    prixUnitaireController.addListener(_verifierCoherencePrix);
    prixAchatController.addListener(_verifierCoherencePrix);
    seuilStockController.addListener(_validateSeuil);
    remiseMaxController.addListener(_validateRemiseMax);
  }

  /// Libère les contrôleurs
  void _disposeControllers() {
    referenceController.dispose();
    nomController.dispose();
    descriptionController.dispose();
    prixUnitaireController.dispose();
    prixAchatController.dispose();
    codeBarreController.dispose();
    categorieController.dispose();
    categorieSearchController.dispose();
    seuilStockController.dispose();
    remiseMaxController.dispose();
  }

  /// Charge les catégories disponibles depuis la base de données
  Future<void> _loadCategories() async {
    try {
      final categoriesList = await _categoryService.getCategories();
      categories.assignAll(categoriesList);
    } catch (e) {
      // En cas d'erreur, on continue avec une liste vide
      categories.clear();
    }
  }

  /// Vérifie si on est en mode édition
  void _checkIfEditing() {
    final arguments = Get.arguments;

    // Gérer le cas où l'argument est un Map (duplication ou édition)
    if (arguments is Map<String, dynamic>) {
      final isDuplicate = arguments['duplicate'] == true;

      if (isDuplicate && arguments['product'] != null) {
        // Mode duplication : extraire le produit du Map
        try {
          final productData = arguments['product'];
          Product product;

          if (productData is Product) {
            product = productData;
          } else if (productData is Map<String, dynamic>) {
            product = Product.fromJson(productData);
          } else {
            return;
          }

          // Mode duplication : pré-remplir le formulaire mais pas en mode édition
          isEditing.value = false;
          editingProduct.value = null;
          _populateFormForDuplication(product);
        } catch (e, stackTrace) {
          // Erreur lors de la duplication du produit
        }
      } else {
        // Mode édition : le Map contient directement les données du produit
        try {
          final product = Product.fromJson(arguments);
          isEditing.value = true;
          editingProduct.value = product;
          _populateFormWithProduct(product);
        } catch (e) {
          // Erreur lors de la conversion du Map en Product
        }
      }
    }
    // Gérer le cas où l'argument est déjà un Product (édition normale)
    else if (arguments is Product) {
      isEditing.value = true;
      editingProduct.value = arguments;
      _populateFormWithProduct(arguments);
    }
  }

  /// Remplit le formulaire pour la duplication d'un produit
  void _populateFormForDuplication(Product product) {
    // Activer la génération automatique mais permettre à l'utilisateur de la désactiver
    isAutoReference.value = true;

    // Remplir les autres champs
    nomController.text = product.nom;
    descriptionController.text = product.description ?? '';
    prixUnitaireController.text = product.prixUnitaire.toString();
    prixAchatController.text = product.prixAchat?.toString() ?? '';
    codeBarreController.text = ''; // Ne pas copier le code barre (doit être unique)
    categorieController.text = product.categorie ?? '';
    seuilStockController.text = product.seuilStockMinimum.toString();
    remiseMaxController.text = product.remiseMaxAutorisee.toString();
    estActif.value = product.estActif;
    estService.value = product.estService;
    typeDefini.value = true;
    gestionPeremption.value = product.gestionPeremption;

    // Gérer la catégorie
    final productCategory = product.categorie ?? '';
    if (productCategory.isEmpty) {
      selectedCategory.value = '';
    } else {
      final existingCategory = categories.firstWhereOrNull((cat) => cat.nom == productCategory);
      if (existingCategory != null) {
        selectedCategory.value = existingCategory.nom;
      } else {
        selectedCategory.value = productCategory;
      }
    }

    // Générer une nouvelle référence automatiquement
    generateReference();
  }

  /// Remplit le formulaire avec les données du produit
  void _populateFormWithProduct(Product product) {
    // Désactiver la génération automatique lors de l'édition
    isAutoReference.value = false;

    referenceController.text = product.reference;
    nomController.text = product.nom;
    descriptionController.text = product.description ?? '';
    prixUnitaireController.text = product.prixUnitaire.toString();
    prixAchatController.text = product.prixAchat?.toString() ?? '';
    codeBarreController.text = product.codeBarre ?? '';
    categorieController.text = product.categorie ?? '';
    seuilStockController.text = product.seuilStockMinimum.toString();
    remiseMaxController.text = product.remiseMaxAutorisee.toString();
    estActif.value = product.estActif;
    estService.value = product.estService;
    typeDefini.value = true;
    gestionPeremption.value = product.gestionPeremption;
    currentImageUrl.value = product.imageUrl ?? '';

    // Vérifier que la catégorie existe dans la liste avant de l'assigner
    final productCategory = product.categorie ?? '';
    if (productCategory.isEmpty) {
      selectedCategory.value = '';
    } else {
      // Chercher la catégorie par nom dans la liste
      final existingCategory = categories.firstWhereOrNull((cat) => cat.nom == productCategory);
      if (existingCategory != null) {
        selectedCategory.value = existingCategory.nom;
      } else {
        // Si la catégorie n'existe pas dans la liste, garder le nom mais signaler
        selectedCategory.value = productCategory;
        print('⚠️ Catégorie "$productCategory" du produit non trouvée dans la liste');
      }
    }
  }

  /// Validation de la référence
  void _validateReference() {
    final reference = referenceController.text.trim();
    if (reference.isEmpty) {
      referenceError.value = 'financialmovements_reference_est_obligatoire'.tr;
    } else {
      referenceError.value = '';
    }
  }

  /// Validation du nom
  void _validateNom() {
    final nom = nomController.text.trim();
    if (nom.isEmpty) {
      nomError.value = 'categories_name_required'.tr;
    } else if (nom.length < 2) {
      nomError.value = 'roles_name_min_length'.tr;
    } else {
      nomError.value = '';
    }
  }

  /// Validation du prix
  void _validatePrix() {
    final prixText = prixUnitaireController.text.trim();
    if (prixText.isEmpty) {
      prixError.value = 'products_prix_est_obligatoire'.tr;
    } else {
      final prix = double.tryParse(prixText);
      if (prix == null) {
        prixError.value = 'products_prix_doit_etre_nombre_valide'.tr;
      } else if (prix <= 0) {
        prixError.value = 'products_prix_doit_etre_positif'.tr;
      } else {
        prixError.value = '';
      }
    }
  }

  /// Prévient (sans bloquer) si le prix de vente est inférieur au prix d'achat : chaque vente ferait perdre de l'argent
  void _verifierCoherencePrix() {
    final vente = double.tryParse(prixUnitaireController.text.trim());
    final achat = double.tryParse(prixAchatController.text.trim());
    final perte = Product.perteParUnite(vente: vente, achat: achat, estService: estService.value);
    avertissementPrix.value = perte > 0
        ? "Attention : le prix de vente (${CurrencyConstants.formatAmount(vente!)}) est inférieur au prix d'achat (${CurrencyConstants.formatAmount(achat!)}). "
            'products_chaque_vente_fera_perdre_par_unite'.trParams({'formatAmount': '${CurrencyConstants.formatAmount(perte)}'})
        : '';
  }

  /// Validation du prix d'achat
  void _validatePrixAchat() {
    final prixAchatText = prixAchatController.text.trim();
    if (prixAchatText.isNotEmpty) {
      final prixAchat = double.tryParse(prixAchatText);
      if (prixAchat == null) {
        prixAchatError.value = 'products_prix_achat_doit_etre_nombre_valide'.tr;
      } else if (prixAchat < 0) {
        prixAchatError.value = 'products_prix_achat_ne_peut_pas_etre'.tr;
      } else {
        prixAchatError.value = '';
      }
    } else {
      prixAchatError.value = '';
    }
  }

  /// Validation du seuil de stock
  void _validateSeuil() {
    final seuilText = seuilStockController.text.trim();
    if (seuilText.isEmpty) {
      seuilError.value = 'products_seuil_stock_est_obligatoire'.tr;
    } else {
      final seuil = int.tryParse(seuilText);
      if (seuil == null) {
        seuilError.value = 'products_seuil_doit_etre_nombre_entier'.tr;
      } else if (seuil < 0) {
        seuilError.value = 'products_seuil_ne_peut_pas_etre_negatif'.tr;
      } else {
        seuilError.value = '';
      }
    }
  }

  /// Validation de la remise maximale autorisée
  void _validateRemiseMax() {
    final remiseText = remiseMaxController.text.trim();
    if (remiseText.isEmpty) {
      remiseMaxController.text = '0';
      remiseMaxError.value = '';
    } else {
      final remise = double.tryParse(remiseText);
      if (remise == null) {
        remiseMaxError.value = 'products_remise_doit_etre_nombre_valide'.tr;
      } else if (remise < 0) {
        remiseMaxError.value = 'sales_discount_negative'.tr;
      } else {
        remiseMaxError.value = '';
      }
    }
  }

  /// Vérifie si le formulaire est valide
  bool get isFormValid {
    return typeDefini.value &&
        referenceError.value.isEmpty &&
        nomError.value.isEmpty &&
        prixError.value.isEmpty &&
        prixAchatError.value.isEmpty &&
        seuilError.value.isEmpty &&
        remiseMaxError.value.isEmpty &&
        referenceController.text.trim().isNotEmpty &&
        nomController.text.trim().isNotEmpty &&
        prixUnitaireController.text.trim().isNotEmpty &&
        seuilStockController.text.trim().isNotEmpty;
  }

  /// Met à jour la catégorie sélectionnée
  void updateSelectedCategory(String? category) {
    selectedCategory.value = category ?? '';
    categorieController.text = category ?? '';
    categorieSearchText.value = '';
    categorieSearchController.clear();
  }

  /// Met à jour les catégories filtrées en fonction du texte de recherche
  void updateCategorieSearch(String searchText) {
    categorieSearchText.value = searchText;
    if (searchText.isEmpty) {
      filteredCategories.clear();
      return;
    }

    final searchLower = searchText.toLowerCase().trim();
    final filtered = categories.where((cat) => cat.nom.toLowerCase().contains(searchLower) || (cat.description != null && cat.description!.toLowerCase().contains(searchLower))).toList();

    filteredCategories.assignAll(filtered);
  }

  /// Actualise la liste des catégories
  Future<void> refreshCategories() async {
    await _loadCategories();
  }

  /// Bascule l'état actif
  void toggleEstActif() {
    estActif.value = !estActif.value;
  }

  /// Applique le type choisi (produit physique ou service).
  ///
  /// Un service n'a ni stock, ni prix d'achat, ni seuil minimum, ni péremption : ces champs sont vidés et cachés.
  /// En modification, revenir au type d'origine retrouve les valeurs d'origine du produit.
  void appliquerType(bool service) {
    estService.value = service;
    typeDefini.value = true;
    _verifierCoherencePrix();
    if (service) {
      seuilStockController.text = '0';
      prixAchatController.clear();
      gestionPeremption.value = false;
      return;
    }
    final origine = editingProduct.value;
    if (isEditing.value && origine != null && !origine.estService) {
      prixAchatController.text = origine.prixAchat?.toString() ?? '';
      seuilStockController.text = origine.seuilStockMinimum.toString();
      gestionPeremption.value = origine.gestionPeremption;
    }
  }

  /// Bascule le type service (conservé pour compatibilité)
  void toggleEstService() => appliquerType(!estService.value);

  /// Le type diffère de celui du produit enregistré (modification seulement)
  bool get typeModifie => isEditing.value && editingProduct.value != null && editingProduct.value!.estService != estService.value;

  /// Bascule la gestion de péremption
  void toggleGestionPeremption() {
    // Un service ne peut pas avoir de gestion de péremption
    if (estService.value) {
      SnackbarHelper.info('products_service_ne_peut_pas_avoir_gestion'.tr);
      return;
    }
    gestionPeremption.value = !gestionPeremption.value;
  }

  /// Bascule entre référence automatique et manuelle
  void toggleAutoReference() {
    // Empêcher la modification en mode édition
    if (isEditing.value) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (Get.isRegistered<ProductFormController>()) {
          SnackbarHelper.info('products_reference_ne_peut_pas_etre_modifiee'.tr);
        }
      });
      return;
    }

    isAutoReference.value = !isAutoReference.value;
    if (isAutoReference.value) {
      generateReference();
    } else {
      referenceController.clear();
    }
  }

  /// Génère une nouvelle référence automatique
  Future<void> generateReference() async {
    if (!isAutoReference.value) return;

    try {
      isGeneratingReference.value = true;

      // Essayer d'abord avec l'API
      try {
        final newReference = await _productService.generateProductReference();
        referenceController.text = newReference;
        referenceError.value = '';
      } catch (apiError) {
        // En cas d'échec de l'API, générer localement
        final localReference = _generateLocalReference();
        referenceController.text = localReference;
        referenceError.value = '';

        // Afficher un message informatif (avec délai pour éviter les conflits)
        Future.delayed(const Duration(milliseconds: 100), () {
          if (Get.isRegistered<ProductFormController>()) {
            SnackbarHelper.info('products_reference_generee_localement_serveur_indisponible'.tr, duration: const Duration(seconds: 3));
          }
        });
      }
    } catch (e) {
      referenceError.value = 'products_erreur_lors_generation_reference'.tr;
    } finally {
      isGeneratingReference.value = false;
    }
  }

  /// Génère une référence localement en cas d'échec de l'API
  String _generateLocalReference() {
    final now = DateTime.now();
    final yearSuffix = now.year.toString().substring(2); // Derniers 2 chiffres de l'année
    final timestamp = now.millisecondsSinceEpoch.toString().substring(8); // Derniers chiffres du timestamp
    return 'PRD$yearSuffix$timestamp';
  }

  /// Vérifie l'unicité de la référence
  Future<bool> _checkReferenceUniqueness() async {
    try {
      final reference = referenceController.text.trim();

      // Si on est en mode édition et que la référence n'a pas changé, pas besoin de vérifier
      if (isEditing.value && editingProduct.value != null) {
        if (reference == editingProduct.value!.reference) {
          return true; // La référence n'a pas changé, donc elle est valide
        }
      }

      final excludeId = isEditing.value ? editingProduct.value?.id : null;

      final isUnique = await _productService.isReferenceUnique(
        reference,
        excludeId: excludeId,
      );

      if (!isUnique) {
        referenceError.value = 'products_reference_existe_deja'.tr;
        return false;
      }

      return true;
    } catch (e) {
      // En cas d'erreur de l'API (endpoint manquant), on accepte la référence si on est en édition
      if (isEditing.value && editingProduct.value != null) {
        final reference = referenceController.text.trim();
        if (reference == editingProduct.value!.reference) {
          return true; // La référence n'a pas changé
        }
      }

      referenceError.value = 'products_erreur_lors_verification_reference'.tr;
      return false;
    }
  }

  /// Sauvegarde le produit
  Future<void> saveProduct() async {
    if (!isFormValid) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (Get.isRegistered<ProductFormController>()) {
          SnackbarHelper.error('products_veuillez_corriger_erreurs_dans_formulaire'.tr);
        }
      });
      return;
    }

    try {
      isLoading.value = true;

      // En mode édition, vérifier que la référence n'a pas été modifiée
      if (isEditing.value && editingProduct.value != null) {
        final currentReference = referenceController.text.trim();
        if (currentReference != editingProduct.value!.reference) {
          referenceError.value = 'products_reference_ne_peut_pas_etre_modifiee'.tr;
          Future.delayed(const Duration(milliseconds: 100), () {
            if (Get.isRegistered<ProductFormController>()) {
              SnackbarHelper.error('product_form_reference_not_editable'.tr);
            }
          });
          return;
        }
      }

      final productForm = ProductForm(
        reference: referenceController.text.trim(),
        nom: nomController.text.trim(),
        description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
        prixUnitaire: double.parse(prixUnitaireController.text.trim()),
        prixAchat: estService.value || prixAchatController.text.trim().isEmpty ? null : double.parse(prixAchatController.text.trim()),
        codeBarre: codeBarreController.text.trim().isEmpty ? null : codeBarreController.text.trim(),
        categorie: selectedCategory.value.isEmpty ? null : selectedCategory.value,
        seuilStockMinimum: estService.value ? 0 : int.parse(seuilStockController.text.trim()),
        remiseMaxAutorisee: double.parse(remiseMaxController.text.trim().isEmpty ? '0' : remiseMaxController.text.trim()),
        estActif: estActif.value,
        estService: estService.value,
        gestionPeremption: estService.value ? false : gestionPeremption.value,
      );

      Product savedProduct;
      String successMessage;

      if (isEditing.value && editingProduct.value != null) {
        savedProduct = await _productService.updateProduct(
          editingProduct.value!.id,
          productForm,
        );
        successMessage = 'products_produit_modifie_avec_succes'.tr;
      } else {
        savedProduct = await _productService.createProduct(productForm);
        successMessage = 'products_produit_cree_avec_succes'.tr;
      }

      // Retourner à la liste des produits AVANT d'afficher le snackbar
      Get.back(result: savedProduct);

      // Afficher le message de succès avec un délai
      Future.delayed(const Duration(milliseconds: 300), () {
        SnackbarHelper.success(successMessage, duration: const Duration(seconds: 2));
      });
    } catch (e) {
      String message = 'products_erreur_lors_sauvegarde_produit'.tr;
      if (e is ApiException) {
        message = e.message;
      }

      // Afficher l'erreur avec un délai pour éviter les conflits
      Future.delayed(const Duration(milliseconds: 100), () {
        if (Get.isRegistered<ProductFormController>()) {
          SnackbarHelper.error(message, duration: const Duration(seconds: 4));
        }
      });
    } finally {
      isLoading.value = false;
    }
  }

  /// Upload l'image du produit depuis un chemin local
  Future<void> uploadImage(String filePath) async {
    final productId = editingProduct.value?.id;
    if (productId == null) return;
    try {
      isUploadingImage.value = true;
      final fileName = await _productService.uploadProductImage(productId, filePath);
      if (fileName != null) {
        currentImageUrl.value = fileName;
        SnackbarHelper.success('products_image_mise_jour'.tr);
      }
    } catch (e) {
      SnackbarHelper.error('products_erreur_lors_upload_image'.tr);
    } finally {
      isUploadingImage.value = false;
    }
  }

  /// Supprime l'image du produit
  Future<void> deleteImage() async {
    final productId = editingProduct.value?.id;
    if (productId == null) return;
    try {
      isUploadingImage.value = true;
      final ok = await _productService.deleteProductImage(productId);
      if (ok) {
        currentImageUrl.value = '';
        SnackbarHelper.success('products_image_supprimee'.tr);
      }
    } catch (e) {
      SnackbarHelper.error('products_erreur_lors_suppression_image'.tr);
    } finally {
      isUploadingImage.value = false;
    }
  }

  /// Annule et retourne à la liste
  void cancel() {
    Get.back();
  }

  /// Réinitialise le formulaire
  void resetForm() {
    referenceController.clear();
    nomController.clear();
    descriptionController.clear();
    prixUnitaireController.clear();
    prixAchatController.clear();
    codeBarreController.clear();
    categorieController.clear();
    seuilStockController.text = '0';
    remiseMaxController.text = '0';
    estActif.value = true;
    estService.value = false;
    typeDefini.value = isEditing.value;
    gestionPeremption.value = false;
    selectedCategory.value = '';
    isAutoReference.value = true;

    // Effacer les erreurs
    referenceError.value = '';
    nomError.value = '';
    prixError.value = '';
    prixAchatError.value = '';
    seuilError.value = '';
    remiseMaxError.value = '';

    // Générer une nouvelle référence automatique
    if (!isEditing.value) {
      generateReference();
    }
  }
}
