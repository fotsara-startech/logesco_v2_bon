/// Dashboard consolidé multi-boutique avec design moderne
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/boutique_service.dart';

enum PeriodFilter { today, week, month, year, custom }

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
    );
    if (range != null) {
      setState(() {
        _customRange = range;
        _selectedPeriod = PeriodFilter.custom;
      });
      _load();
    }
  }

  String _fmtDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        title: const Text('Dashboard consolidé', style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildPeriodFilter(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildError()
                    : _data == null
                        ? const Center(child: Text('Aucune donnée'))
                        : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text('Erreur: $_error', style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
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
            // Totaux globaux - Cards modernes
            _buildGlobalStats(totaux),

            const SizedBox(height: 24),

            // Graphique de répartition
            if (boutiques.isNotEmpty) ...[
              _buildRevenueChart(boutiques),
              const SizedBox(height: 24),
            ],

            // Liste des boutiques
            _buildBoutiquesList(boutiques),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalStats(Map<String, dynamic> totaux) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vue d\'ensemble',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _CompactStatCard(
                label: 'Chiffre d\'affaires',
                value: _formatMoney(totaux['chiffreAffaires']),
                icon: Icons.trending_up_rounded,
                color: const Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _CompactStatCard(
                label: 'Montant encaissé',
                value: _formatMoney(totaux['montantEncaisse']),
                icon: Icons.account_balance_wallet_rounded,
                color: const Color(0xFF2196F3),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _CompactStatCard(
                label: 'Nombre de ventes',
                value: '${totaux['nbVentes'] ?? 0}',
                icon: Icons.receipt_long_rounded,
                color: const Color(0xFFFF9800),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _CompactStatCard(
                label: 'Mouvements financiers',
                value: _formatMoney(totaux['totalMouvementsFinanciers']),
                icon: Icons.swap_horiz_rounded,
                color: const Color(0xFF9C27B0),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRevenueChart(List<Map<String, dynamic>> boutiques) {
    final totalCA = boutiques.fold<double>(0, (sum, b) => sum + ((b['chiffreAffaires'] as num?)?.toDouble() ?? 0));

    if (totalCA == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Répartition du chiffre d\'affaires',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 50,
                      sections: boutiques.asMap().entries.map((entry) {
                        final index = entry.key;
                        final b = entry.value;
                        final ca = (b['chiffreAffaires'] as num?)?.toDouble() ?? 0;
                        final percentage = totalCA > 0 ? (ca / totalCA * 100) : 0;
                        final color = _getChartColor(index);

                        return PieChartSectionData(
                          value: ca,
                          title: '${percentage.toStringAsFixed(1)}%',
                          radius: 60,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          color: color,
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: boutiques.asMap().entries.map((entry) {
                      final index = entry.key;
                      final b = entry.value;
                      final boutique = b['boutique'] as Map<String, dynamic>? ?? {};
                      final nom = boutique['nom'] as String? ?? 'Boutique';
                      final ca = (b['chiffreAffaires'] as num?)?.toDouble() ?? 0;
                      final color = _getChartColor(index);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                nom,
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              _formatMoney(ca),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoutiquesList(List<Map<String, dynamic>> boutiques) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Détails par boutique',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...boutiques.map((b) => _ModernBoutiqueCard(data: b)),
      ],
    );
  }

  Color _getChartColor(int index) {
    const colors = [
      Color(0xFF4CAF50),
      Color(0xFF2196F3),
      Color(0xFFFF9800),
      Color(0xFF9C27B0),
      Color(0xFFF44336),
      Color(0xFF00BCD4),
      Color(0xFFFFEB3B),
      Color(0xFF795548),
    ];
    return colors[index % colors.length];
  }

  String _formatMoney(dynamic val) {
    final n = (val as num? ?? 0).toDouble();
    // Format avec séparateur de milliers
    final formatter = n.toStringAsFixed(0);
    final parts = <String>[];
    var remaining = formatter;

    while (remaining.length > 3) {
      parts.insert(0, remaining.substring(remaining.length - 3));
      remaining = remaining.substring(0, remaining.length - 3);
    }
    if (remaining.isNotEmpty) {
      parts.insert(0, remaining);
    }

    return '${parts.join(' ')} FCFA';
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
    const primary = Color(0xFF1565C0);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? primary : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: primary.withAlpha(77),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: selected ? Colors.white : Colors.grey[700]),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? Colors.white : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactStatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;

  const _CompactStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernBoutiqueCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ModernBoutiqueCard({required this.data});

  String _fmt(dynamic val) {
    final n = (val as num? ?? 0).toDouble();
    // Format avec séparateur de milliers
    final formatter = n.toStringAsFixed(0);
    final parts = <String>[];
    var remaining = formatter;

    while (remaining.length > 3) {
      parts.insert(0, remaining.substring(remaining.length - 3));
      remaining = remaining.substring(0, remaining.length - 3);
    }
    if (remaining.isNotEmpty) {
      parts.insert(0, remaining);
    }

    return parts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final boutique = data['boutique'] as Map<String, dynamic>? ?? {};
    final nom = boutique['nom'] as String? ?? 'Boutique';
    final estPrincipale = boutique['estPrincipale'] as bool? ?? false;
    final caisses = (data['caisses'] as List<dynamic>? ?? []);

    final ca = (data['chiffreAffaires'] as num?)?.toDouble() ?? 0;
    final encaisse = (data['montantEncaisse'] as num?)?.toDouble() ?? 0;
    final nbVentes = data['nbVentes'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête boutique
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: estPrincipale ? Colors.amber[50] : Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  estPrincipale ? Icons.store_rounded : Icons.storefront_rounded,
                  color: estPrincipale ? Colors.amber[700] : Colors.blue[700],
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nom,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    if (estPrincipale)
                      Text(
                        'Boutique principale',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Statistiques
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: 'CA',
                  value: '${_fmt(ca)} FCFA',
                  icon: Icons.trending_up_rounded,
                  color: Colors.green,
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: 'Encaissé',
                  value: '${_fmt(encaisse)} FCFA',
                  icon: Icons.payments_rounded,
                  color: Colors.blue,
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: 'Ventes',
                  value: '$nbVentes',
                  icon: Icons.receipt_long_rounded,
                  color: Colors.orange,
                ),
              ),
            ],
          ),

          // Caisses
          if (caisses.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.account_balance_wallet_rounded, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  'Caisses (${caisses.length})',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Tooltip(
                  message: 'Solde actuel total de chaque caisse\n(indépendant de la période sélectionnée)',
                  child: Icon(Icons.info_outline, size: 14, color: Colors.grey[500]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...caisses.map((c) {
              final caisse = c as Map<String, dynamic>;
              final nomCaisse = caisse['nom'] as String? ?? '';
              final solde = (caisse['soldeActuel'] as num?)?.toDouble() ?? 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        nomCaisse,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${_fmt(solde)} FCFA',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Solde actuel',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
