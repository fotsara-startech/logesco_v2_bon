/// Chiffre d'affaires d'un client sur une période (licences + services),
/// calculé à la volée — jamais persisté.
class ClientRevenue {
  final String clientId;
  final String clientName;
  final double licenseRevenue;
  final double serviceRevenue;

  const ClientRevenue({
    required this.clientId,
    required this.clientName,
    required this.licenseRevenue,
    required this.serviceRevenue,
  });

  double get total => licenseRevenue + serviceRevenue;
}

/// État de l'activité sur une période (revenus, dépenses, résultat net),
/// calculé à la volée — jamais persisté.
class FinancialSummary {
  final DateTime from;
  final DateTime to;
  final double licenseRevenue;
  final double serviceRevenue;
  final double totalExpenses;
  final Map<String, double> expensesByCategory;
  final List<ClientRevenue> revenueByClient;

  const FinancialSummary({
    required this.from,
    required this.to,
    required this.licenseRevenue,
    required this.serviceRevenue,
    required this.totalExpenses,
    required this.expensesByCategory,
    required this.revenueByClient,
  });

  double get totalRevenue => licenseRevenue + serviceRevenue;
  double get netResult => totalRevenue - totalExpenses;
}
