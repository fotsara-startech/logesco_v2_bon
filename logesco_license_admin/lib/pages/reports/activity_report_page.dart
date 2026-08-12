import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/financial_summary.dart';
import '../../core/services/database_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/stats_card.dart';

enum _PeriodPreset { thisMonth, lastMonth, thisYear, custom }

class ActivityReportPage extends ConsumerStatefulWidget {
  const ActivityReportPage({super.key});

  @override
  ConsumerState<ActivityReportPage> createState() => _ActivityReportPageState();
}

class _ActivityReportPageState extends ConsumerState<ActivityReportPage> {
  FinancialSummary? _summary;
  bool _isLoading = true;
  _PeriodPreset _preset = _PeriodPreset.thisMonth;
  late DateTime _from;
  late DateTime _to;
  final _currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: 'XAF', decimalDigits: 0);

  static const List<Color> _pieColors = [
    Colors.red,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.brown,
    Colors.indigo,
  ];

  @override
  void initState() {
    super.initState();
    _applyPreset(_PeriodPreset.thisMonth);
  }

  void _applyPreset(_PeriodPreset preset) {
    final now = DateTime.now();
    DateTime from;
    DateTime to;
    switch (preset) {
      case _PeriodPreset.thisMonth:
        from = DateTime(now.year, now.month, 1);
        to = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case _PeriodPreset.lastMonth:
        from = DateTime(now.year, now.month - 1, 1);
        to = DateTime(now.year, now.month, 0, 23, 59, 59);
        break;
      case _PeriodPreset.thisYear:
        from = DateTime(now.year, 1, 1);
        to = DateTime(now.year, 12, 31, 23, 59, 59);
        break;
      case _PeriodPreset.custom:
        from = _from;
        to = _to;
        break;
    }
    setState(() {
      _preset = preset;
      _from = from;
      _to = to;
    });
    _loadSummary();
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 3650)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _from, end: _to),
    );
    if (picked != null) {
      setState(() {
        _preset = _PeriodPreset.custom;
        _from = picked.start;
        _to = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
      });
      _loadSummary();
    }
  }

  Future<void> _loadSummary() async {
    setState(() => _isLoading = true);
    try {
      final summary = await DatabaseService.instance.getFinancialSummary(from: _from, to: _to);
      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('État de l\'activité'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSummary,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _summary == null
              ? const Center(child: Text('Aucune donnée'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPeriodSelector(),
                      const SizedBox(height: 24),
                      _buildSummaryCards(),
                      const SizedBox(height: 32),
                      _buildExpensesByCategory(),
                      const SizedBox(height: 32),
                      _buildRevenueByClient(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildPeriodSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Période :', style: Theme.of(context).textTheme.titleMedium),
            ChoiceChip(
              label: const Text('Ce mois-ci'),
              selected: _preset == _PeriodPreset.thisMonth,
              onSelected: (_) => _applyPreset(_PeriodPreset.thisMonth),
            ),
            ChoiceChip(
              label: const Text('Mois dernier'),
              selected: _preset == _PeriodPreset.lastMonth,
              onSelected: (_) => _applyPreset(_PeriodPreset.lastMonth),
            ),
            ChoiceChip(
              label: const Text('Cette année'),
              selected: _preset == _PeriodPreset.thisYear,
              onSelected: (_) => _applyPreset(_PeriodPreset.thisYear),
            ),
            ChoiceChip(
              label: Text(_preset == _PeriodPreset.custom
                  ? '${DateFormat('dd/MM/yyyy').format(_from)} → ${DateFormat('dd/MM/yyyy').format(_to)}'
                  : 'Personnalisé'),
              selected: _preset == _PeriodPreset.custom,
              onSelected: (_) => _pickCustomRange(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final summary = _summary!;
    final netColor = summary.netResult >= 0 ? AppTheme.successColor : AppTheme.errorColor;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 700;
        final mainCards = [
          StatsCard(title: 'Revenus totaux', value: _currencyFormat.format(summary.totalRevenue), icon: Icons.trending_up, color: AppTheme.successColor),
          StatsCard(title: 'Dépenses totales', value: _currencyFormat.format(summary.totalExpenses), icon: Icons.trending_down, color: AppTheme.errorColor),
          StatsCard(title: 'Résultat net', value: _currencyFormat.format(summary.netResult), icon: Icons.account_balance, color: netColor),
        ];
        final secondaryCards = [
          StatsCard(title: 'Revenus licences', value: _currencyFormat.format(summary.licenseRevenue), icon: Icons.key, color: Colors.blue),
          StatsCard(title: 'Revenus services', value: _currencyFormat.format(summary.serviceRevenue), icon: Icons.build_outlined, color: Colors.orange),
        ];

        if (isNarrow) {
          return Column(
            children: [
              for (final c in mainCards) ...[c, const SizedBox(height: 12)],
              for (final c in secondaryCards) ...[c, const SizedBox(height: 12)],
            ],
          );
        }
        return Column(
          children: [
            Row(children: [for (final c in mainCards) ...[Expanded(child: c), const SizedBox(width: 16)]]),
            const SizedBox(height: 16),
            Row(children: [for (final c in secondaryCards) ...[Expanded(child: c), const SizedBox(width: 16)]]),
          ],
        );
      },
    );
  }

  Widget _buildExpensesByCategory() {
    final entries = _summary!.expensesByCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Dépenses par catégorie', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        if (entries.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Aucune dépense sur cette période'),
            ),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 600;
                  final chart = SizedBox(
                    height: 220,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: [
                          for (int i = 0; i < entries.length; i++)
                            PieChartSectionData(
                              value: entries[i].value,
                              color: _pieColors[i % _pieColors.length],
                              title: '',
                              radius: 60,
                            ),
                        ],
                      ),
                    ),
                  );
                  final legend = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int i = 0; i < entries.length; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(width: 12, height: 12, color: _pieColors[i % _pieColors.length]),
                              const SizedBox(width: 8),
                              Expanded(child: Text(entries[i].key)),
                              Text(_currencyFormat.format(entries[i].value), style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                    ],
                  );
                  if (isNarrow) {
                    return Column(children: [chart, const SizedBox(height: 16), legend]);
                  }
                  return Row(
                    children: [
                      Expanded(child: chart),
                      const SizedBox(width: 24),
                      Expanded(child: legend),
                    ],
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRevenueByClient() {
    final revenues = _summary!.revenueByClient;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Chiffre d\'affaires par client', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        if (revenues.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Aucun revenu sur cette période'),
            ),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Client')),
                    DataColumn(label: Text('Revenus licences'), numeric: true),
                    DataColumn(label: Text('Revenus services'), numeric: true),
                    DataColumn(label: Text('Total'), numeric: true),
                  ],
                  rows: revenues
                      .map((r) => DataRow(cells: [
                            DataCell(Text(r.clientName, style: const TextStyle(fontWeight: FontWeight.w500))),
                            DataCell(Text(_currencyFormat.format(r.licenseRevenue))),
                            DataCell(Text(_currencyFormat.format(r.serviceRevenue))),
                            DataCell(Text(_currencyFormat.format(r.total), style: const TextStyle(fontWeight: FontWeight.bold))),
                          ]))
                      .toList(),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
