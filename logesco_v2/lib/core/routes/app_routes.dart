/// Routes de l'application LOGESCO v2
class AppRoutes {
  // Route de base
  static const String initial = '/';

  // Routes d'authentification
  static const String login = '/login';
  static const String splash = '/splash';

  // Routes principales
  static const String dashboard = '/dashboard';
  static const String products = '/products';
  static const String categories = '/categories-management';
  static const String productsImportExport = '/products/import-export';
  static const String suppliers = '/suppliers';
  static const String customers = '/customers';
  static const String procurement = '/procurement';
  static const String sales = '/sales';
  static const String inventory = '/inventory';
  static const String accounts = '/accounts';

  // Routes de détail
  static const String productDetail = '/products/:id';
  static const String supplierDetail = '/suppliers/:id';
  static const String supplierTransactions = '/suppliers/:supplierId/transactions';
  static const String supplierAccount = '/suppliers/:supplierId/account';
  static const String customerDetail = '/customers/:id';
  static const String customerTransactions = '/customers/:customerId/transactions';
  static const String procurementDetail = '/procurement/:id';
  static const String saleDetail = '/sales/:id';

  // Routes de création/édition
  static const String createProduct = '/products/create';
  static const String editProduct = '/products/:id/edit';
  static const String createSupplier = '/suppliers/create';
  static const String editSupplier = '/suppliers/:id/edit';
  static const String createCustomer = '/customers/create';
  static const String editCustomer = '/customers/:id/edit';
  static const String createProcurement = '/procurement/create';
  static const String createSale = '/sales/create';

  // Routes de rapports
  static const String reports = '/reports';
  static const String stockReport = '/reports/stock';
  static const String salesReport = '/reports/sales';
  static const String accountsReport = '/reports/accounts';
  static const String discountReports = '/reports/discounts';
  static const String activityReport = '/reports/activity';

  // Routes d'analytics
  static const String analytics = '/analytics';
  static const String productAnalytics = '/analytics/products';

  // Routes de dépenses
  static const String expenseCategories = '/expenses/categories';
  static const String createExpenseCategory = '/expenses/categories/create';

  // Routes de paramètres
  static const String settings = '/settings';
  static const String profile = '/profile';
  static const String companySettings = '/settings/company';
  static const String salesPreferences = '/sales/preferences';

  // Routes d'impression
  static const String printing = '/printing';
  static const String receiptHistory = '/printing/history';
  static const String receiptPreview = '/printing/preview';
  static const String receiptDetail = '/printing/receipts/:id';

  // Routes de gestion des utilisateurs
  static const String users = '/users';
  static const String createUser = '/users/create';
  static const String editUser = '/users/:id/edit';
  static const String userDetail = '/users/:id';
  static const String roles = '/roles';
  static const String createRole = '/roles/create';
  static const String editRole = '/roles/:id/edit';

  // Routes de gestion des caisses
  static const String cashRegisters = '/cash-registers';
  static const String createCashRegister = '/cash-registers/create';
  static const String editCashRegister = '/cash-registers/:id/edit';
  static const String cashRegisterDetail = '/cash-registers/:id';

  // Routes des sessions de caisse
  static const String cashSession = '/cash-session';
  static const String cashSessionHistory = '/cash-session/history';

  // Routes d'inventaire de stock
  static const String stockInventory = '/stock-inventory';
  static const String createInventory = '/stock-inventory/create';
  static const String inventoryDetail = '/stock-inventory/:id';
  static const String inventoryCount = '/stock-inventory/:id/count';
  static const String inventoryPrint = '/stock-inventory/:id/print';

  // Routes des mouvements financiers
  static const String financialMovements = '/financial-movements';
  static const String createFinancialMovement = '/financial-movements/create';
  static const String editFinancialMovement = '/financial-movements/:id/edit';
  static const String financialMovementDetail = '/financial-movements/:id';
  static const String financialMovementReports = '/financial-movements/reports';

  // Routes de comptabilité
  static const String accounting = '/accounting';
  static const String accountingDashboard = '/accounting/dashboard';

  // Routes de test et développement
  static const String roleTest = '/role-test';

  // Routes d'abonnement
  static const String subscriptionStatus = '/subscription/status';
  static const String subscriptionActivation = '/subscription/activation';
  static const String subscriptionBlocked = '/subscription/blocked';

  // Routes d'approvisionnement avancées
  static const String procurementSuggestions = '/procurement/suggestions';
  static const String procurementExport = '/procurement/:id/export';

  // Routes de mouvements de stock
  static const String stockMovement = '/inventory/movement';
  static const String stockMovementCreate = '/inventory/movement/create';
}
