# Ajout du filtre de dates pour les comptes clients et fournisseurs

## Objectif
Permettre de filtrer les transactions des comptes clients et fournisseurs par période :
- Aujourd'hui
- Cette semaine
- Ce mois
- Cette année
- Période personnalisée (entre deux dates)

## Fichiers à modifier

### 1. Vue du compte client
**Fichier** : `logesco_v2/lib/features/customers/views/customer_account_view.dart`

**Modifications** :
1. Ajouter un état pour la période sélectionnée
2. Ajouter une barre de filtres de période (similaire au dashboard consolidé)
3. Filtrer les transactions affichées selon la période
4. Recalculer le solde en fonction des transactions filtrées

### 2. Vue du compte fournisseur
**Fichier** : `logesco_v2/lib/features/suppliers/views/supplier_account_view.dart` (à vérifier)

**Modifications similaires** :
1. Même système de filtres
2. Filtrage des transactions
3. Recalcul du solde

### 3. Contrôleur (optionnel)
Si le filtrage doit être fait côté backend, modifier :
- `CustomerController` pour passer les paramètres de date
- `AccountService` pour accepter les paramètres dateDebut/dateFin

## Implémentation proposée

### Composant de filtre réutilisable

```dart
enum PeriodFilter { today, week, month, year, custom, all }

class DateFilterBar extends StatelessWidget {
  final PeriodFilter selectedPeriod;
  final DateTimeRange? customRange;
  final Function(PeriodFilter) onPeriodChanged;
  final VoidCallback onCustomRangePick;

  const DateFilterBar({
    super.key,
    required this.selectedPeriod,
    this.customRange,
    required this.onPeriodChanged,
    required this.onCustomRangePick,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _PeriodChip(
              label: 'Tout',
              selected: selectedPeriod == PeriodFilter.all,
              onTap: () => onPeriodChanged(PeriodFilter.all),
            ),
            const SizedBox(width: 8),
            _PeriodChip(
              label: "Aujourd'hui",
              selected: selectedPeriod == PeriodFilter.today,
              onTap: () => onPeriodChanged(PeriodFilter.today),
            ),
            const SizedBox(width: 8),
            _PeriodChip(
              label: 'Cette semaine',
              selected: selectedPeriod == PeriodFilter.week,
              onTap: () => onPeriodChanged(PeriodFilter.week),
            ),
            const SizedBox(width: 8),
            _PeriodChip(
              label: 'Ce mois',
              selected: selectedPeriod == PeriodFilter.month,
              onTap: () => onPeriodChanged(PeriodFilter.month),
            ),
            const SizedBox(width: 8),
            _PeriodChip(
              label: 'Cette année',
              selected: selectedPeriod == PeriodFilter.year,
              onTap: () => onPeriodChanged(PeriodFilter.year),
            ),
            const SizedBox(width: 8),
            _PeriodChip(
              label: customRange != null
                  ? '${_fmtDate(customRange!.start)} – ${_fmtDate(customRange!.end)}'
                  : 'Personnalisée',
              selected: selectedPeriod == PeriodFilter.custom,
              icon: Icons.date_range,
              onTap: onCustomRangePick,
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
```

### Logique de filtrage

```dart
List<TransactionCompte> _getFilteredTransactions() {
  if (_selectedPeriod == PeriodFilter.all) {
    return _controller.customerTransactions;
  }

  final (dateDebut, dateFin) = _getPeriodDates();
  if (dateDebut == null || dateFin == null) {
    return _controller.customerTransactions;
  }

  return _controller.customerTransactions.where((transaction) {
    final date = transaction.dateTransaction;
    return date.isAfter(dateDebut.subtract(const Duration(days: 1))) &&
           date.isBefore(dateFin.add(const Duration(days: 1)));
  }).toList();
}

(DateTime?, DateTime?) _getPeriodDates() {
  final now = DateTime.now();
  switch (_selectedPeriod) {
    case PeriodFilter.today:
      return (DateTime(now.year, now.month, now.day), now);
    case PeriodFilter.week:
      final start = now.subtract(Duration(days: now.weekday - 1));
      return (DateTime(start.year, start.month, start.day), now);
    case PeriodFilter.month:
      return (DateTime(now.year, now.month, 1), now);
    case PeriodFilter.year:
      return (DateTime(now.year, 1, 1), now);
    case PeriodFilter.custom:
      return _customRange != null
          ? (_customRange!.start, _customRange!.end)
          : (null, null);
    case PeriodFilter.all:
      return (null, null);
  }
}
```

### Calcul du solde filtré

```dart
double _calculateFilteredBalance() {
  final filteredTransactions = _getFilteredTransactions();
  if (filteredTransactions.isEmpty) return 0.0;
  
  // Le solde est celui de la dernière transaction de la période
  return filteredTransactions.first.soldeApres;
}
```

## Avantages de cette approche

1. **Filtrage côté client** : Pas besoin de modifier le backend
2. **Réutilisable** : Le composant `DateFilterBar` peut être utilisé partout
3. **Performant** : Les transactions sont déjà chargées, on filtre juste en mémoire
4. **UX cohérente** : Même interface que le dashboard consolidé

## Alternative : Filtrage côté backend

Si les comptes ont beaucoup de transactions, il serait préférable de :
1. Modifier l'API pour accepter `dateDebut` et `dateFin`
2. Filtrer les transactions en SQL
3. Retourner seulement les transactions de la période

**Avantage** : Moins de données transférées
**Inconvénient** : Plus de requêtes réseau

## Prochaines étapes

1. Créer le widget `DateFilterBar` réutilisable
2. Intégrer dans `customer_account_view.dart`
3. Intégrer dans `supplier_account_view.dart`
4. Tester avec différentes périodes
5. Vérifier que le solde est correctement recalculé
