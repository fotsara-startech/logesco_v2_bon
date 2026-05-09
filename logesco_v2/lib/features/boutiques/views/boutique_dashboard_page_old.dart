import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/boutique_service.dart';

enum PeriodFilter { today, week, month, year, custom }

/// Dashboard consolidé multi-boutique
class BoutiqueDashboardPage extends StatefulWidget {
  const BoutiqueDashboardPage({super.key});

  @override
  State<BoutiqueDashboardPage> createState() => _BoutiqueDashboardPageState();
}

class _BoutiqueDashboardPageState extends State<BoutiqueDashboardPage> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  PeriodFilter _selectedPeriod = PeriodFilter.month;
  DateTimeRange? _customRange;

  @override
  void initState() {
    super.initState();
    _load();
  }

  (String?, String?) _getPeriodDates() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case PeriodFilter.today:
        final d = _dateStr(now);
        return (d, d);
      case PeriodFilter.week:
        final start = now.subtract(Duration(days: now.weekday - 1));
        return (_dateStr(start), _dateStr(now));
      case PeriodFilter.month:
        return (_dateStr(DateTime(now.year, now.month, 1)), _dateStr(now));
      case PeriodFilter.year:
        return (_dateStr(DateTime(now.year, 1, 1)), _dateStr(now));
      case PeriodFilter.custom:
        if (_customRange != null) {
          return (_dateStr(_customRange!.start), _dateStr(_customRange!.end));
        }
        return (null, null);
    }
  }

  String _dateStr(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service = Get.find<BoutiqueService>();
      final (dateDebut, dateFin) = _getPeriodDates();
      final result = await service.getDashboardConsolide(
        dateDebut: dateDebut,
        dateFin: dateFin,
      );
      setState(() => _data = result);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

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
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: const Color(0xFF1565C0),
              ),
        ),
        child: child!,
      ),
    );
    if (range != null) {
      setState(() {
        _customRange = range;
        _selectedPeriod = PeriodFilter.custom;
      });
      _load();
    }
  }

  String get _periodLabel {
    switch (_selectedPeriod) {
      case PeriodFilter.today:
        return "Aujourd'hui";
      case PeriodFilter.week:
        return 'Cette semaine';
      case PeriodFilter.month:
        return 'Ce mois';
      case PeriodFilter.year:
        return 'Cette année';
      case PeriodFilter.custom:
        if (_customRange != null) {
          return '${_fmtDate(_customRange!.start)} – ${_fmtDate(_customRange!.end)}';
        }
        return 'Personnalisée';
    }
  }

  String _fmtDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard consolidé'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Column(
        children: [
          _buildPeriodFilter(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('Erreur: $_error', style: const TextStyle(color: Colors.red)))
                    : _data == null
                        ? const Center(child: Text('Aucune donnée'))
                        : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _PeriodChip(
                  label: "Aujourd'hui",
                  selected: _selectedPeriod == PeriodFilter.today,
                  onTap: () {
                    setState(() => _selectedPeriod = PeriodFilter.today);
                    _load();
                  },
                ),
                const SizedBox(width: 8),
                _PeriodChip(
                  label: 'Cette semaine',
                  selected: _selectedPeriod == PeriodFilter.week,
                  onTap: () {
                    setState(() => _selectedPeriod = PeriodFilter.week);
                    _load();
                  },
                ),
                const SizedBox(width: 8),
                _PeriodChip(
                  label: 'Ce mois',
                  selected: _selectedPeriod == PeriodFilter.month,
                  onTap: () {
                    setState(() => _selectedPeriod = PeriodFilter.month);
                    _load();
                  },
                ),
                const SizedBox(width: 8),
                _PeriodChip(
                  label: 'Cette année',
                  selected: _selectedPeriod == PeriodFilter.year,
                  onTap: () {
                    setState(() => _selectedPeriod = PeriodFilter.year);
                    _load();
                  },
                ),
                const SizedBox(width: 8),
                _PeriodChip(
                  label: _selectedPeriod == PeriodFilter.custom && _customRange != null ? '${_fmtDate(_customRange!.start)} – ${_fmtDate(_customRange!.end)}' : 'Personnalisée',
                  selected: _selectedPeriod == PeriodFilter.custom,
                  icon: Icons.date_range,
                  onTap: _pickCustomRange,
                ),
              ],
            ),
          ),
          if (_selectedPeriod != PeriodFilter.custom)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _periodLabel,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final totaux = _data!['totaux'] as Map<String, dynamic>? ?? {};
    final boutiques = (_data!['boutiques'] as List<dynamic>? ?? []).map((e) => e as Map<String, dynamic>).toList();

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Totaux globaux
            const _SectionTitle(title: 'Totaux globaux', icon: Icons.bar_chart),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _StatCard(
                  label: 'Chiffre d\'affaires',
                  value: _formatMoney(totaux['chiffreAffaires']),
                  icon: Icons.trending_up,
                  color: Colors.green,
                ),
                _StatCard(
                  label: 'Montant encaissé',
                  value: _formatMoney(totaux['montantEncaisse']),
                  icon: Icons.payments,
                  color: Colors.blue,
                ),
                _StatCard(
                  label: 'Nombre de ventes',
                  value: '${totaux['nbVentes'] ?? 0}',
                  icon: Icons.receipt_long,
                  color: Colors.orange,
                ),
                _StatCard(
                  label: 'Mouvements financiers',
                  value: _formatMoney(totaux['totalMouvementsFinanciers']),
                  icon: Icons.account_balance_wallet,
                  color: Colors.purple,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Par boutique
            const _SectionTitle(title: 'Par boutique', icon: Icons.store),
            const SizedBox(height: 12),
            ...boutiques.map((b) => _BoutiqueStatCard(data: b)),
          ],
        ),
      ),
    );
  }

  String _formatMoney(dynamic val) {
    final n = (val as num? ?? 0).toDouble();
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M FCFA';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K FCFA';
    return '${n.toStringAsFixed(0)} FCFA';
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF1565C0);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? primary : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? primary : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: selected ? Colors.white : Colors.grey[700]),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected ? Colors.white : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BoutiqueStatCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _BoutiqueStatCard({required this.data});

  String _fmt(dynamic val) {
    final n = (val as num? ?? 0).toDouble();
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
    return n.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final boutique = data['boutique'] as Map<String, dynamic>? ?? {};
    final nom = boutique['nom'] as String? ?? 'Boutique';
    final estPrincipale = boutique['estPrincipale'] as bool? ?? false;
    final caisses = (data['caisses'] as List<dynamic>? ?? []);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(estPrincipale ? Icons.store : Icons.storefront, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(nom, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                if (estPrincipale) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Principale', style: TextStyle(fontSize: 10, color: Colors.amber[800])),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _MiniStat(label: 'CA', value: '${_fmt(data['chiffreAffaires'])} FCFA', color: Colors.green)),
                Expanded(child: _MiniStat(label: 'Encaissé', value: '${_fmt(data['montantEncaisse'])} FCFA', color: Colors.blue)),
                Expanded(child: _MiniStat(label: 'Ventes', value: '${data['nbVentes'] ?? 0}', color: Colors.orange)),
              ],
            ),
            if (caisses.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Text('Caisses', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              ...caisses.map((c) {
                final caisse = c as Map<String, dynamic>;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(caisse['nom'] as String? ?? '', style: const TextStyle(fontSize: 12)),
                    Text(
                      '${_fmt(caisse['soldeActuel'])} FCFA',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
      ],
    );
  }
}
