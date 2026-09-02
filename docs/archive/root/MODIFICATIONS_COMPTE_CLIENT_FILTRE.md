# Modifications à apporter au compte client pour ajouter le filtre de dates

## Fichier : `logesco_v2/lib/features/customers/views/customer_account_view.dart`

### 1. Ajouter les imports

```dart
import '../../../shared/widgets/date_filter_bar.dart';
```

### 2. Ajouter les variables d'état dans `_CustomerAccountViewState`

```dart
class _CustomerAccountViewState extends State<CustomerAccountView> {
  final CustomerController _controller = Get.find<CustomerController>();
  Customer? _customer;
  
  // AJOUT : Variables pour le filtre de dates
  PeriodFilter _selectedPeriod = PeriodFilter.all;
  DateTimeRange? _customRange;

  // ... reste du code
}
```

### 3. Ajouter les méthodes de filtrage

```dart
// AJOUT : Méthode pour obtenir les transactions filtrées
List<TransactionCompte> _getFilteredTransactions() {
  return DateFilterHelper.filterByDate(
    _controller.customerTransactions,
    (transaction) => transaction.dateTransaction,
    _selectedPeriod,
    _customRange,
  );
}

// AJOUT : Méthode pour calculer le solde filtré
double _calculateFilteredBalance() {
  final filteredTransactions = _getFilteredTransactions();
  if (filteredTransactions.isEmpty) return 0.0;
  return filteredTransactions.first.soldeApres;
}

// AJOUT : Méthode pour changer la période
void _onPeriodChanged(PeriodFilter period) {
  setState(() {
    _selectedPeriod = period;
    if (period != PeriodFilter.custom) {
      _customRange = null;
    }
  });
}

// AJOUT : Méthode pour sélectionner une période personnalisée
Future<void> _pickCustomRange() async {
  final now = DateTime.now();
  final range = await showDateRangePicker(
    context: context,
    firstDate: DateTime(2020),
    lastDate: now,
    initialDateRange: _customRange ??
        DateTimeRange(
          start: now.subtract(const Duration(days: 30)),
          end: now,
        ),
  );
  if (range != null) {
    setState(() {
      _customRange = range;
      _selectedPeriod = PeriodFilter.custom;
    });
  }
}
```

### 4. Modifier le `build` pour ajouter la barre de filtre

```dart
@override
Widget build(BuildContext context) {
  if (_customer == null) {
    return Scaffold(
      appBar: AppBar(title: Text('error'.tr)),
      body: Center(child: Text('customers_not_found'.tr)),
    );
  }

  return Scaffold(
    appBar: AppBar(
      title: Text('customers_account'.trParams({'name': _customer!.nomComplet})),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadTransactions,
          tooltip: 'refresh'.tr,
        ),
      ],
    ),
    body: Obx(() {
      if (_controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      return RefreshIndicator(
        onRefresh: _loadTransactions,
        child: Column(
          children: [
            _buildAccountSummary(),
            const Divider(height: 1),
            // AJOUT : Barre de filtre de dates
            DateFilterBar(
              selectedPeriod: _selectedPeriod,
              customRange: _customRange,
              onPeriodChanged: _onPeriodChanged,
              onCustomRangePick: _pickCustomRange,
            ),
            const Divider(height: 1),
            Expanded(child: _buildTransactionsList()),
          ],
        ),
      );
    }),
  );
}
```

### 5. Modifier `_buildAccountSummary` pour utiliser le solde filtré

```dart
Widget _buildAccountSummary() {
  // MODIFICATION : Utiliser le solde filtré au lieu du solde global
  double solde = _calculateFilteredBalance();

  final bool aDette = solde < 0;
  final double montantDette = aDette ? -solde : 0.0;
  final double creditDisponible = !aDette ? solde : 0.0;

  // ... reste du code inchangé
}
```

### 6. Modifier `_buildTransactionsList` pour utiliser les transactions filtrées

```dart
Widget _buildTransactionsList() {
  // MODIFICATION : Utiliser les transactions filtrées
  final filteredTransactions = _getFilteredTransactions();
  
  if (filteredTransactions.isEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            _selectedPeriod == PeriodFilter.all
                ? 'customers_no_transactions'.tr
                : 'Aucune transaction pour cette période',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  return ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: filteredTransactions.length,
    itemBuilder: (context, index) {
      final transaction = filteredTransactions[index];
      return _buildTransactionItem(transaction);
    },
  );
}
```

## Résultat attendu

Après ces modifications :
1. Une barre de filtres apparaîtra entre le résumé du compte et la liste des transactions
2. L'utilisateur pourra sélectionner : Tout, Aujourd'hui, Cette semaine, Ce mois, Cette année, ou Personnalisée
3. Le solde affiché sera recalculé en fonction de la période sélectionnée
4. Seules les transactions de la période sélectionnée seront affichées
5. Le filtre "Personnalisée" ouvrira un sélecteur de plage de dates

## Même approche pour le compte fournisseur

Appliquer les mêmes modifications au fichier du compte fournisseur (si existant) :
- `logesco_v2/lib/features/suppliers/views/supplier_account_view.dart`
