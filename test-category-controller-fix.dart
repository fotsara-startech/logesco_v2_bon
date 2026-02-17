import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Simuler les imports nécessaires
class CategoryService extends GetxService {
  Future<List<dynamic>> getCategories() async {
    // Simulation
    return [];
  }
  
  Future<dynamic> createCategory(dynamic category) async {
    return category;
  }
  
  Future<dynamic> updateCategory(dynamic category) async {
    return category;
  }
  
  Future<void> deleteCategory(int id) async {
    // Simulation
  }
}

class Category {
  final int? id;
  final String nom;
  final String? description;
  final DateTime dateCreation;
  final DateTime dateModification;

  Category({
    this.id,
    required this.nom,
    this.description,
    DateTime? dateCreation,
    DateTime? dateModification,
  })  : dateCreation = dateCreation ?? DateTime.now(),
        dateModification = dateModification ?? DateTime.now();

  Category copyWith({
    int? id,
    String? nom,
    String? description,
    DateTime? dateCreation,
    DateTime? dateModification,
  }) {
    return Category(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      description: description ?? this.description,
      dateCreation: dateCreation ?? this.dateCreation,
      dateModification: dateModification ?? DateTime.now(),
    );
  }
}

class CategoryController extends GetxController {
  final CategoryService _categoryService = Get.find<CategoryService>();

  final RxList<Category> categories = <Category>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final Rx<Category?> selectedCategory = Rx<Category?>(null);

  @override
  void onInit() {
    super.onInit();
    print('🏗️ CategoryController initialisé');
    loadCategories();
  }

  Future<void> loadCategories({bool showLoading = true}) async {
    try {
      if (showLoading) {
        isLoading.value = true;
      }
      error.value = '';

      print('🔄 Chargement des catégories...');
      final result = await _categoryService.getCategories();

      categories.assignAll(result.cast<Category>());
      print('✅ ${categories.length} catégories chargées');
    } catch (e) {
      error.value = 'Erreur lors du chargement: ${e.toString()}';
      print('❌ Erreur chargement catégories: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> addCategory(String nom, {String? description}) async {
    return true;
  }

  Future<bool> updateCategory(Category category, String newNom, {String? newDescription}) async {
    return true;
  }

  Future<bool> deleteCategory(Category category) async {
    return true;
  }

  void selectCategory(Category? category) {
    selectedCategory.value = category;
  }

  void clearSelection() {
    selectedCategory.value = null;
  }

  bool get hasSelection => selectedCategory.value != null;

  Future<void> refresh() async {
    await loadCategories(showLoading: false);
  }
}

// Test des bindings
class ProductBinding extends Bindings {
  @override
  void dependencies() {
    // Service catégorie (singleton)
    Get.lazyPut<CategoryService>(
      () => CategoryService(),
      fenix: true,
    );

    // Contrôleur des catégories (créé à la demande)
    Get.lazyPut<CategoryController>(
      () => CategoryController(),
      fenix: true,
    );
  }
}

// Test de la page
class TestCategoriesPage extends StatelessWidget {
  const TestCategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CategoryController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Catégories'),
      ),
      body: Obx(() {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (controller.isLoading.value)
                const CircularProgressIndicator()
              else
                const Icon(Icons.check_circle, color: Colors.green, size: 64),
              const SizedBox(height: 16),
              Text(
                controller.isLoading.value 
                  ? 'Chargement...' 
                  : 'CategoryController fonctionne !',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text('Catégories: ${controller.categories.length}'),
              if (controller.error.value.isNotEmpty)
                Text(
                  'Erreur: ${controller.error.value}',
                  style: const TextStyle(color: Colors.red),
                ),
            ],
          ),
        );
      }),
    );
  }
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Test CategoryController',
      initialBinding: ProductBinding(),
      home: const TestCategoriesPage(),
    );
  }
}