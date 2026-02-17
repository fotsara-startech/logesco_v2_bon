# Design Document - Module Mouvements Financiers

## Overview

Le module de mouvements financiers est conçu pour tracer et gérer toutes les sorties d'argent de la boutique LOGESCO. Il s'intègre dans l'architecture existante (GetX, Clean Architecture) et utilise les patterns établis pour fournir une interface intuitive pour la gestion des dépenses.

## Architecture

### Structure des Dossiers

```
lib/features/financial_movements/
├── models/
│   ├── financial_movement.dart
│   ├── movement_category.dart
│   └── movement_enums.dart
├── controllers/
│   ├── financial_movement_controller.dart
│   └── movement_category_controller.dart
├── services/
│   ├── financial_movement_service.dart
│   └── movement_report_service.dart
├── views/
│   ├── financial_movements_page.dart
│   ├── movement_form_page.dart
│   ├── movement_detail_page.dart
│   └── movement_reports_page.dart
├── widgets/
│   ├── movement_card.dart
│   ├── category_selector.dart
│   ├── movement_filters.dart
│   └── amount_input.dart
└── bindings/
    └── financial_movement_binding.dart
```

### Backend Structure

```
backend/
├── src/
│   ├── models/
│   │   ├── financial-movement.js
│   │   └── movement-category.js
│   ├── routes/
│   │   └── financial-movements.js
│   ├── services/
│   │   ├── financial-movement-service.js
│   │   └── movement-report-service.js
│   └── dto/
│       └── financial-movement-dto.js
```

## Components and Interfaces

### 1. Modèles de Données

#### Financial Movement

```dart
class FinancialMovement {
  final int id;
  final String reference;
  final double amount;
  final int categoryId;
  final String description;
  final DateTime date;
  final int userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? notes;
  final MovementCategory? category;
  final String? userName;
}
```

#### Movement Category

```dart
class MovementCategory {
  final int id;
  final String name;
  final String displayName;
  final String color;
  final String icon;
  final bool isDefault;
  final bool isActive;
}
```

### 2. Services

#### Financial Movement Service

```dart
abstract class FinancialMovementService {
  Future<List<FinancialMovement>> getMovements({
    DateTime? startDate,
    DateTime? endDate,
    int? categoryId,
    String? search,
    int page = 1,
    int limit = 20,
  });
  
  Future<FinancialMovement> createMovement(CreateMovementRequest request);
  Future<FinancialMovement> updateMovement(int id, UpdateMovementRequest request);
  Future<void> deleteMovement(int id);
  Future<FinancialMovement> getMovementById(int id);
}
```

#### Movement Report Service

```dart
abstract class MovementReportService {
  Future<MovementSummary> getSummary(DateTime startDate, DateTime endDate);
  Future<List<CategorySummary>> getCategorySummary(DateTime startDate, DateTime endDate);
  Future<List<DailySummary>> getDailySummary(DateTime startDate, DateTime endDate);
  Future<String> exportReportToPdf(MovementReportRequest request);
  Future<String> exportReportToExcel(MovementReportRequest request);
}
```

### 3. Contrôleurs

#### Financial Movements Controller

```dart
class FinancialMovementsController extends GetxController {
  final RxList<FinancialMovement> movements = <FinancialMovement>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final Rx<MovementCategory?> selectedCategory = Rx<MovementCategory?>(null);
  final Rx<DateRange?> dateRange = Rx<DateRange?>(null);
  
  // Méthodes principales
  Future<void> loadMovements();
  Future<void> createMovement(CreateMovementRequest request);
  Future<void> updateMovement(int id, UpdateMovementRequest request);
  Future<void> deleteMovement(int id);
  void applyFilters();
  void clearFilters();
}
```

## Data Models

### Base de Données

#### Table: financial_movements

```sql
CREATE TABLE financial_movements (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  reference VARCHAR(50) UNIQUE NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  category_id INTEGER NOT NULL,
  description TEXT NOT NULL,
  date DATE NOT NULL,
  user_id INTEGER NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  notes TEXT,
  FOREIGN KEY (category_id) REFERENCES movement_categories(id),
  FOREIGN KEY (user_id) REFERENCES utilisateurs(id)
);
```

#### Table: movement_categories

```sql
CREATE TABLE movement_categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name VARCHAR(50) UNIQUE NOT NULL,
  display_name VARCHAR(100) NOT NULL,
  color VARCHAR(7) DEFAULT '#6B7280',
  icon VARCHAR(50) DEFAULT 'receipt',
  is_default BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT TRUE
);
```

### Catégories par Défaut

```sql
INSERT INTO movement_categories (name, display_name, color, icon, is_default, is_active) VALUES
('achats', 'Achats de marchandises', '#EF4444', 'shopping_cart', TRUE, TRUE),
('charges', 'Charges et frais', '#F59E0B', 'receipt_long', TRUE, TRUE),
('salaires', 'Salaires et personnel', '#10B981', 'people', TRUE, TRUE),
('maintenance', 'Maintenance et réparations', '#8B5CF6', 'build', TRUE, TRUE),
('transport', 'Transport et livraison', '#06B6D4', 'local_shipping', TRUE, TRUE),
('autres', 'Autres dépenses', '#6B7280', 'more_horiz', TRUE, TRUE);
```

## Error Handling

### Types d'Erreurs

1. **ValidationError**: Données invalides (montant négatif, date future, etc.)
2. **PermissionError**: Accès non autorisé au module
3. **DatabaseError**: Problème lors de l'accès aux données
4. **NotFoundError**: Mouvement ou catégorie introuvable

### Gestion des Erreurs

```dart
class MovementErrorHandler {
  static void handleError(dynamic error) {
    if (error is ValidationError) {
      Get.snackbar('Erreur de validation', error.message);
    } else if (error is PermissionError) {
      Get.snackbar('Accès refusé', 'Vous n\'avez pas les permissions nécessaires');
    } else {
      Get.snackbar('Erreur', 'Une erreur inattendue s\'est produite');
    }
  }
}
```

## Testing Strategy

### Tests Unitaires

1. **Modèles**: Validation des données, sérialisation/désérialisation
2. **Services**: Logique métier, appels API
3. **Contrôleurs**: Gestion d'état, interactions utilisateur
4. **Utilitaires**: Formatage, calculs, validations

### Tests d'Intégration

1. **API**: Endpoints CRUD pour les mouvements
2. **Base de données**: Opérations CRUD, contraintes
3. **Interface utilisateur**: Navigation, formulaires, affichage

### Tests End-to-End

1. **Flux complet**: Création → Modification → Suppression d'un mouvement
2. **Rapports**: Génération et export de rapports
3. **Filtres**: Application et suppression de filtres
4. **Permissions**: Contrôle d'accès selon les rôles

## Performance Considerations

### Optimisations Frontend

1. **Pagination**: Chargement par lots de 20 mouvements
2. **Lazy Loading**: Chargement différé des détails
3. **Mise en cache**: Cache des catégories et données statiques
4. **Debouncing**: Recherche avec délai pour éviter les appels excessifs

### Optimisations Backend

1. **Indexation**: Index sur date, category_id, user_id
2. **Requêtes optimisées**: Jointures efficaces, limitation des résultats
3. **Compression**: Compression des réponses API
4. **Cache**: Cache des rapports fréquemment demandés

## Security Considerations

### Authentification et Autorisation

1. **JWT**: Tokens pour l'authentification
2. **RBAC**: Contrôle d'accès basé sur les rôles
3. **Permissions**: Vérification des permissions pour chaque action
4. **Audit**: Traçabilité de toutes les actions

### Validation des Données

1. **Frontend**: Validation immédiate des formulaires
2. **Backend**: Validation serveur pour toutes les données
3. **Sanitisation**: Nettoyage des entrées utilisateur
4. **Limites**: Limitation des tailles et formats

### Protection des Données

1. **Chiffrement**: Données sensibles chiffrées en base
2. **HTTPS**: Communication sécurisée
3. **Logs**: Journalisation sécurisée sans données sensibles
4. **Backup**: Sauvegarde régulière des données financières