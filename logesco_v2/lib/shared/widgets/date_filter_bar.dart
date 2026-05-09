/// Widget réutilisable pour filtrer par période
library;

import 'package:flutter/material.dart';

enum PeriodFilter { all, today, week, month, year, custom }

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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
              label: selectedPeriod == PeriodFilter.custom && customRange != null ? '${_fmtDate(customRange!.start)} – ${_fmtDate(customRange!.end)}' : 'Personnalisée',
              selected: selectedPeriod == PeriodFilter.custom,
              icon: Icons.date_range,
              onTap: onCustomRangePick,
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
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

/// Helper pour obtenir les dates de début et fin selon la période
class DateFilterHelper {
  static (DateTime?, DateTime?) getPeriodDates(
    PeriodFilter period,
    DateTimeRange? customRange,
  ) {
    final now = DateTime.now();
    switch (period) {
      case PeriodFilter.all:
        return (null, null);
      case PeriodFilter.today:
        final today = DateTime(now.year, now.month, now.day);
        return (today, now);
      case PeriodFilter.week:
        final start = now.subtract(Duration(days: now.weekday - 1));
        final weekStart = DateTime(start.year, start.month, start.day);
        return (weekStart, now);
      case PeriodFilter.month:
        return (DateTime(now.year, now.month, 1), now);
      case PeriodFilter.year:
        return (DateTime(now.year, 1, 1), now);
      case PeriodFilter.custom:
        return customRange != null ? (customRange.start, customRange.end) : (null, null);
    }
  }

  static List<T> filterByDate<T>(
    List<T> items,
    DateTime Function(T) getDate,
    PeriodFilter period,
    DateTimeRange? customRange,
  ) {
    if (period == PeriodFilter.all) return items;

    final (dateDebut, dateFin) = getPeriodDates(period, customRange);
    if (dateDebut == null || dateFin == null) return items;

    return items.where((item) {
      final date = getDate(item);
      return date.isAfter(dateDebut.subtract(const Duration(seconds: 1))) && date.isBefore(dateFin.add(const Duration(days: 1)));
    }).toList();
  }
}
