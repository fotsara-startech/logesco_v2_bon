/// Module de gestion des comptes clients et fournisseurs
///
/// Ce module fournit toutes les fonctionnalités pour gérer les comptes,
/// les transactions de crédit/débit et les limites de crédit.

// Modèles
export 'models/account.dart';

// Services
export 'services/account_service.dart';
export 'services/account_api_service.dart';

// Contrôleurs
export 'controllers/account_controller.dart';

// Vues
export 'views/accounts_list_view.dart';
export 'views/account_detail_view.dart';

// Widgets
export 'widgets/compte_client_card.dart';
export 'widgets/compte_fournisseur_card.dart';
export 'widgets/accounts_filter_dialog.dart';
export 'widgets/transaction_form_dialog.dart';
export 'widgets/credit_limit_dialog.dart';
export 'widgets/transaction_list_item.dart';

// Bindings
export 'bindings/account_binding.dart';
