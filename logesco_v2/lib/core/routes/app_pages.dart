import 'package:get/get.dart';
import 'app_routes.dart';
import '../../features/auth/views/login_page.dart';
import '../../features/auth/views/splash_page.dart';

import '../../features/dashboard/views/modern_dashboard_page.dart';
import '../../features/products/views/product_list_view.dart';
import '../../features/products/views/product_form_view.dart';
import '../../features/products/views/product_detail_view.dart';
import '../../features/products/views/categories_page.dart';

import '../../features/products/bindings/category_binding.dart';
import '../../features/products/bindings/product_binding.dart';
import '../../features/accounts/views/accounts_list_view.dart';
import '../../features/accounts/views/account_detail_view.dart';
import '../../features/accounts/bindings/account_binding.dart';
import '../../features/dashboard/bindings/dashboard_binding.dart';
import '../../features/customers/views/customer_list_view.dart';
import '../../features/customers/views/customer_form_view.dart';
import '../../features/customers/views/customer_detail_view.dart';
import '../../features/customers/views/customer_account_view.dart';
import '../../features/customers/bindings/customer_binding.dart';
import '../../features/suppliers/views/supplier_list_view.dart';
import '../../features/suppliers/views/supplier_form_view.dart';
import '../../features/suppliers/views/supplier_detail_view.dart';
import '../../features/suppliers/views/supplier_transactions_view.dart';
import '../../features/suppliers/views/supplier_account_view.dart';
import '../../features/suppliers/bindings/supplier_binding.dart';
import '../../features/inventory/views/inventory_getx_page.dart';
import '../../features/inventory/views/stock_adjustment_page.dart';
import '../../features/inventory/views/stock_detail_page.dart';
import '../../features/inventory/views/stock_movement_page.dart';
import '../../features/inventory/views/bulk_stock_adjustment_page.dart' as bulk;
import '../../features/inventory/bindings/inventory_binding.dart';
import '../../features/inventory/models/stock_model.dart';
import '../../features/procurement/views/procurement_page.dart';
import '../../features/procurement/views/suggestions_page.dart';
import '../../features/procurement/bindings/procurement_binding.dart';
import '../../features/sales/views/sales_page.dart';
import '../../features/sales/views/create_sale_page.dart';
import '../../features/sales/pages/sales_preferences_page.dart';
import '../../features/sales/bindings/sales_binding.dart';
import '../../features/company_settings/views/company_settings_page.dart';
import '../../features/company_settings/bindings/company_settings_binding.dart';
import '../../features/printing/views/receipt_history_page.dart';
import '../../features/printing/views/receipt_preview_page.dart';
import '../../features/printing/views/receipt_detail_page.dart';
import '../../features/printing/bindings/printing_binding.dart';
import '../../features/users/views/user_list_view.dart';
import '../../features/users/views/user_form_view.dart';
import '../../features/users/bindings/user_binding.dart';
import '../../features/users/views/roles_page.dart';
import '../../features/users/views/role_form_page.dart';
import '../../features/users/bindings/role_binding.dart';
import '../../features/reports/views/discount_report_view.dart';
import '../../features/reports/views/activity_report_page.dart';
import '../../features/reports/bindings/activity_report_binding.dart';
import '../../features/subscription/views/subscription_status_page.dart';
import '../../features/subscription/views/license_activation_page.dart';
import '../../features/subscription/views/subscription_blocked_page.dart';
import '../../features/expenses/views/expense_categories_page.dart';
import '../../features/expenses/views/create_expense_category_page.dart';
import '../middleware/auth_middleware.dart';
import '../middleware/subscription_middleware.dart';
import '../../features/cash_registers/views/cash_register_list_view.dart';
import '../../features/cash_registers/views/cash_register_form_view.dart';
import '../../features/cash_registers/views/cash_session_view.dart';
import '../../features/cash_registers/views/cash_session_history_view.dart';
import '../../features/cash_registers/bindings/cash_register_binding.dart';
import '../../features/cash_registers/bindings/cash_session_binding.dart';
import '../../features/stock_inventory/views/stock_inventory_list_view.dart';
import '../../features/stock_inventory/views/inventory_form_view.dart';
import '../../features/stock_inventory/views/inventory_detail_view.dart';
import '../../features/stock_inventory/views/inventory_count_view.dart';
import '../../features/stock_inventory/bindings/stock_inventory_binding.dart';
import '../../features/financial_movements/views/financial_movements_page.dart';
import '../../features/financial_movements/views/movement_form_page.dart';
import '../../features/financial_movements/views/movement_detail_page.dart';
import '../../features/financial_movements/views/movement_reports_page.dart';
import '../../features/financial_movements/models/financial_movement.dart';
import '../../features/financial_movements/bindings/financial_movement_binding.dart';
import '../../features/accounting/views/accounting_dashboard_page.dart';
import '../../features/accounting/bindings/accounting_binding.dart';
import '../../features/analytics/views/product_analytics_page.dart';
import '../../features/analytics/bindings/analytics_binding.dart';
// import '../../features/users/views/role_test_view.dart';

/// Configuration des pages et routes avec GetX
class AppPages {
  static final List<GetPage> pages = [
    // Page de démarrage
    GetPage(
      name: AppRoutes.initial,
      page: () => const SplashPage(),
    ),

    // Authentification
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashPage(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginPage(),
    ),

    // Dashboard principal
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const ModernDashboardPage(),
      binding: DashboardBinding(),
      middlewares: [SubscriptionMiddleware()],
    ),

    // Gestion des produits
    GetPage(
      name: AppRoutes.products,
      page: () => const ProductListView(),
      binding: ProductBinding(),
      middlewares: [SubscriptionMiddleware()],
    ),
    GetPage(
      name: AppRoutes.createProduct,
      page: () => const ProductFormView(),
      binding: ProductBinding(),
    ),
    GetPage(
      name: AppRoutes.editProduct,
      page: () => const ProductFormView(),
      binding: ProductBinding(),
    ),
    GetPage(
      name: AppRoutes.productDetail,
      page: () => const ProductDetailView(),
      binding: ProductBinding(),
    ),
    GetPage(
      name: AppRoutes.categories,
      page: () {
        // print('🔍 Route categories appelée - Chargement CategoriesPage');
        return const CategoriesPage();
      },
      binding: CategoryBinding(),
    ),

    // Gestion des comptes
    GetPage(
      name: AppRoutes.accounts,
      page: () => const AccountsListView(),
      binding: AccountBinding(),
    ),
    GetPage(
      name: '/accounts/clients/:id',
      page: () => const AccountDetailView(),
      binding: AccountBinding(),
    ),
    GetPage(
      name: '/accounts/suppliers/:id',
      page: () => const AccountDetailView(),
      binding: AccountBinding(),
    ),

    // Gestion des clients
    GetPage(
      name: AppRoutes.customers,
      page: () => const CustomerListView(),
      binding: CustomerBinding(),
    ),
    GetPage(
      name: AppRoutes.createCustomer,
      page: () => const CustomerFormView(),
      binding: CustomerBinding(),
    ),
    GetPage(
      name: AppRoutes.editCustomer,
      page: () => const CustomerFormView(),
      binding: CustomerBinding(),
    ),
    GetPage(
      name: AppRoutes.customerDetail,
      page: () => const CustomerDetailView(),
      binding: CustomerBinding(),
    ),
    // SOLUTION 2: Vue du compte client centralisé
    GetPage(
      name: AppRoutes.customerTransactions,
      page: () => const CustomerAccountView(),
      binding: CustomerBinding(),
    ),

    // Gestion des fournisseurs
    GetPage(
      name: AppRoutes.suppliers,
      page: () => const SupplierListView(),
      binding: SupplierBinding(),
    ),
    GetPage(
      name: AppRoutes.createSupplier,
      page: () => const SupplierFormView(),
      binding: SupplierBinding(),
    ),
    GetPage(
      name: AppRoutes.editSupplier,
      page: () => const SupplierFormView(),
      binding: SupplierBinding(),
    ),
    GetPage(
      name: AppRoutes.supplierDetail,
      page: () => const SupplierDetailView(),
      binding: SupplierBinding(),
    ),
    GetPage(
      name: AppRoutes.supplierTransactions,
      page: () => const SupplierTransactionsView(),
      binding: SupplierBinding(),
    ),
    GetPage(
      name: AppRoutes.supplierAccount,
      page: () => const SupplierAccountView(),
      binding: SupplierBinding(),
    ),

    // Gestion de l'inventaire
    GetPage(
      name: AppRoutes.inventory,
      page: () => const InventoryGetxPage(),
      binding: InventoryBinding(),
      middlewares: [SubscriptionMiddleware()],
    ),
    GetPage(
      name: '/inventory/adjustment',
      page: () => StockAdjustmentPage(
        initialStock: Get.arguments as Stock?,
      ),
      binding: InventoryBinding(),
    ),
    GetPage(
      name: '/inventory/stock/:id',
      page: () => StockDetailPage(
        stock: Get.arguments as Stock,
      ),
      binding: InventoryBinding(),
    ),
    GetPage(
      name: '/inventory/bulk-adjustment',
      page: () => const bulk.BulkStockAdjustmentPage(),
      binding: InventoryBinding(),
    ),
    GetPage(
      name: AppRoutes.stockMovement,
      page: () => StockMovementPage(
        initialStock: Get.arguments as Stock?,
      ),
      binding: InventoryBinding(),
    ),

    // Gestion des approvisionnements
    GetPage(
      name: AppRoutes.procurement,
      page: () => const ProcurementPage(),
      binding: ProcurementBinding(),
    ),
    GetPage(
      name: AppRoutes.procurementSuggestions,
      page: () => const SuggestionsPage(),
      binding: ProcurementBinding(),
    ),

    // Gestion des ventes
    GetPage(
      name: AppRoutes.sales,
      page: () => const SalesPage(),
      binding: SalesBinding(),
      middlewares: [SubscriptionMiddleware()],
    ),
    GetPage(
      name: AppRoutes.createSale,
      page: () => const CreateSalePage(),
      binding: SalesBinding(),
    ),
    GetPage(
      name: AppRoutes.salesPreferences,
      page: () => const SalesPreferencesPage(),
      binding: SalesBinding(),
    ),

    // Paramètres d'entreprise
    GetPage(
      name: AppRoutes.companySettings,
      page: () => const CompanySettingsPage(),
      binding: CompanySettingsBinding(),
    ),

    // Impression et réimpression
    GetPage(
      name: AppRoutes.printing,
      page: () => const ReceiptHistoryPage(),
      binding: PrintingBinding(),
    ),
    GetPage(
      name: AppRoutes.receiptHistory,
      page: () => const ReceiptHistoryPage(),
      binding: PrintingBinding(),
    ),
    GetPage(
      name: AppRoutes.receiptPreview,
      page: () => const ReceiptPreviewPage(),
      binding: PrintingBinding(),
    ),
    GetPage(
      name: AppRoutes.receiptDetail,
      page: () => const ReceiptDetailPage(),
      binding: PrintingBinding(),
    ),

    // Gestion des utilisateurs
    GetPage(
      name: AppRoutes.users,
      page: () => const UserListView(),
      binding: UserBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.createUser,
      page: () => const UserFormView(),
      binding: UserBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.editUser,
      page: () => const UserFormView(),
      binding: UserBinding(),
      middlewares: [AuthMiddleware()],
    ),

    // Gestion des rôles
    GetPage(
      name: AppRoutes.roles,
      page: () => const RolesPage(),
      binding: RoleBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.createRole,
      page: () => const RoleFormPage(),
      binding: RoleBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.editRole,
      page: () => const RoleFormPage(),
      binding: RoleBinding(),
      middlewares: [AuthMiddleware()],
    ),

    // Gestion des caisses
    GetPage(
      name: AppRoutes.cashRegisters,
      page: () => const CashRegisterListView(),
      binding: CashRegisterBinding(),
    ),
    GetPage(
      name: AppRoutes.createCashRegister,
      page: () => const CashRegisterFormView(),
      binding: CashRegisterBinding(),
    ),
    GetPage(
      name: AppRoutes.editCashRegister,
      page: () => const CashRegisterFormView(),
      binding: CashRegisterBinding(),
    ),

    // Sessions de caisse
    GetPage(
      name: AppRoutes.cashSession,
      page: () => const CashSessionView(),
      binding: CashSessionBinding(),
      middlewares: [SubscriptionMiddleware()],
    ),
    GetPage(
      name: AppRoutes.cashSessionHistory,
      page: () => const CashSessionHistoryView(),
      binding: CashSessionBinding(),
      middlewares: [AuthMiddleware(), SubscriptionMiddleware()],
    ),

    // Inventaire de stock
    GetPage(
      name: AppRoutes.stockInventory,
      page: () => const StockInventoryListView(),
      binding: StockInventoryBinding(),
    ),
    GetPage(
      name: AppRoutes.createInventory,
      page: () => const InventoryFormView(),
      binding: StockInventoryBinding(),
    ),
    GetPage(
      name: AppRoutes.inventoryDetail,
      page: () => const InventoryDetailView(),
      binding: StockInventoryBinding(),
    ),
    GetPage(
      name: AppRoutes.inventoryCount,
      page: () => const InventoryCountView(),
      binding: StockInventoryBinding(),
    ),

    // Mouvements financiers
    GetPage(
      name: AppRoutes.financialMovements,
      page: () => const FinancialMovementsPage(),
      binding: FinancialMovementBinding(),
    ),
    GetPage(
      name: AppRoutes.createFinancialMovement,
      page: () => const MovementFormPage(),
      binding: FinancialMovementBinding(),
    ),
    GetPage(
      name: AppRoutes.editFinancialMovement,
      page: () => MovementFormPage(movement: Get.arguments as FinancialMovement?),
      binding: FinancialMovementBinding(),
    ),
    GetPage(
      name: AppRoutes.financialMovementReports,
      page: () => const MovementReportsPage(),
      binding: FinancialMovementBinding(),
    ),
    GetPage(
      name: AppRoutes.financialMovementDetail,
      page: () => const MovementDetailPage(),
      binding: FinancialMovementBinding(),
    ),

    // Comptabilité
    GetPage(
      name: AppRoutes.accounting,
      page: () => const AccountingDashboardPage(),
      binding: AccountingBinding(),
    ),
    GetPage(
      name: AppRoutes.accountingDashboard,
      page: () => const AccountingDashboardPage(),
      binding: AccountingBinding(),
    ),

    // Rapports de remises
    GetPage(
      name: AppRoutes.discountReports,
      page: () => const DiscountReportView(),
      middlewares: [AuthMiddleware()],
    ),

    // Bilan comptable d'activités
    GetPage(
      name: AppRoutes.activityReport,
      page: () => const ActivityReportPage(),
      binding: ActivityReportBinding(),
      middlewares: [AuthMiddleware()],
    ),

    // Analytics
    GetPage(
      name: AppRoutes.productAnalytics,
      page: () => const ProductAnalyticsPage(),
      binding: AnalyticsBinding(),
      middlewares: [SubscriptionMiddleware()],
    ),

    // Catégories de dépenses
    GetPage(
      name: AppRoutes.expenseCategories,
      page: () => const ExpenseCategoriesPage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.createExpenseCategory,
      page: () => const CreateExpenseCategoryPage(),
      middlewares: [AuthMiddleware()],
    ),

    // Routes d'abonnement
    GetPage(
      name: AppRoutes.subscriptionStatus,
      page: () => const SubscriptionStatusPage(),
    ),
    GetPage(
      name: AppRoutes.subscriptionActivation,
      page: () => const LicenseActivationPage(),
    ),
    GetPage(
      name: AppRoutes.subscriptionBlocked,
      page: () => const SubscriptionBlockedPage(),
    ),

    // Test et développement
  ];
}
