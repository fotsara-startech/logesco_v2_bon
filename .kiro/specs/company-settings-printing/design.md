# Design Document

## Overview

Ce document décrit la conception technique pour le module de configuration des paramètres d'entreprise et le système d'impression avec réimpression des reçus. La solution comprend deux modules principaux qui s'intègrent avec l'architecture existante de Logesco V2.

## Architecture

### Company Settings Module
- **Backend**: API REST pour la gestion des paramètres d'entreprise
- **Frontend**: Interface Flutter avec formulaires de configuration
- **Storage**: Base de données pour la persistance des informations

### Printing System Module
- **Backend**: API pour la récupération des données de vente et génération de reçus
- **Frontend**: Interface Flutter pour l'impression et la réimpression
- **Templates**: Système de templates pour différents formats d'impression

## Components and Interfaces

### Backend Components

#### Company Settings API (`/api/company-settings`)
```javascript
// Routes principales
GET    /api/company-settings          // Récupérer les paramètres
PUT    /api/company-settings          // Mettre à jour les paramètres
POST   /api/company-settings/validate // Valider les données
```

#### Printing API (`/api/printing`)
```javascript
// Routes d'impression
GET    /api/printing/receipts         // Liste des reçus
GET    /api/printing/receipts/:id     // Détails d'un reçu
POST   /api/printing/receipts/:id/reprint // Réimprimer un reçu
GET    /api/printing/templates        // Templates disponibles
```

### Frontend Components

#### Company Settings Module
```dart
// Structure des composants Flutter
lib/features/company_settings/
├── models/
│   └── company_profile.dart
├── services/
│   └── company_settings_service.dart
├── controllers/
│   └── company_settings_controller.dart
├── views/
│   └── company_settings_page.dart
└── bindings/
    └── company_settings_binding.dart
```

#### Printing Module
```dart
// Structure des composants Flutter
lib/features/printing/
├── models/
│   ├── receipt_model.dart
│   └── print_format.dart
├── services/
│   └── printing_service.dart
├── controllers/
│   └── printing_controller.dart
├── views/
│   ├── receipt_history_page.dart
│   └── receipt_preview_page.dart
└── widgets/
    ├── receipt_template.dart
    └── format_selector.dart
```

## Data Models

### Company Profile Model
```dart
class CompanyProfile {
  final String? id;
  final String name;
  final String address;
  final String location;
  final String phone;
  final String email;
  final String nuiRccm;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}
```

### Receipt Model (Extended)
```dart
class Receipt {
  final String id;
  final String saleId;
  final CompanyProfile companyInfo;
  final List<SaleItem> items;
  final double totalAmount;
  final String paymentMethod;
  final DateTime saleDate;
  final Customer? customer;
  final PrintFormat format;
  final bool isReprint;
  final int reprintCount;
}
```

### Print Format Model
```dart
enum PrintFormat {
  a4,
  a5,
  thermal
}

class PrintTemplate {
  final PrintFormat format;
  final double width;
  final double height;
  final Map<String, dynamic> layoutConfig;
}
```

## Error Handling

### Company Settings Errors
- **Validation Errors**: Champs requis manquants, formats invalides
- **Permission Errors**: Accès non autorisé aux paramètres
- **Network Errors**: Échec de sauvegarde ou récupération

### Printing Errors
- **Receipt Not Found**: Reçu introuvable pour réimpression
- **Template Errors**: Format d'impression non supporté
- **Generation Errors**: Échec de génération du reçu

### Error Response Format
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Nom de l'entreprise requis",
    "field": "name"
  }
}
```

## Testing Strategy

### Unit Tests
- Validation des modèles de données
- Logique métier des contrôleurs
- Services de communication API

### Integration Tests
- Tests des API endpoints
- Tests de génération de reçus
- Tests de sauvegarde des paramètres

### UI Tests
- Navigation entre les pages
- Validation des formulaires
- Prévisualisation des reçus

## Security Considerations

### Authentication & Authorization
- Vérification des rôles utilisateur pour les paramètres d'entreprise
- Tokens JWT pour l'authentification API
- Validation côté serveur pour toutes les opérations

### Data Protection
- Chiffrement des informations sensibles
- Validation et sanitisation des entrées
- Audit trail pour les modifications

## Performance Considerations

### Caching Strategy
- Cache des paramètres d'entreprise en mémoire
- Cache des templates d'impression
- Optimisation des requêtes de recherche de reçus

### Database Optimization
- Index sur les champs de recherche (date, customer_id, sale_id)
- Pagination pour l'historique des reçus
- Archivage des anciens reçus

## Integration Points

### Existing Systems
- **Sales Module**: Récupération des données de vente pour impression
- **Customer Module**: Informations client sur les reçus
- **Auth System**: Contrôle d'accès aux fonctionnalités
- **Dashboard**: Liens vers les nouveaux modules

### External Dependencies
- **PDF Generation**: Pour les formats A4/A5
- **Thermal Printing**: Bibliothèques spécialisées
- **File Storage**: Stockage des templates et reçus générés