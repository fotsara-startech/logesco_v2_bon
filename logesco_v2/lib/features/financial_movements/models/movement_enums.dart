/// Enums pour le module des mouvements financiers

/// Types de mouvements financiers
enum MovementType {
  /// Sortie d'argent (dépense)
  expense('expense', 'Dépense', 'Sortie d\'argent'),

  /// Remboursement
  refund('refund', 'Remboursement', 'Remboursement de dépense'),

  /// Avance
  advance('advance', 'Avance', 'Avance sur salaire ou dépense'),

  /// Autre type de mouvement
  other('other', 'Autre', 'Autre type de mouvement');

  const MovementType(this.code, this.label, this.description);

  final String code;
  final String label;
  final String description;

  /// Trouve un type de mouvement par son code
  static MovementType? fromCode(String code) {
    for (MovementType type in MovementType.values) {
      if (type.code == code) return type;
    }
    return null;
  }

  /// Obtient tous les types disponibles pour l'interface utilisateur
  static List<MovementType> get availableTypes => MovementType.values;

  @override
  String toString() => label;
}

/// Statuts des mouvements financiers
enum MovementStatus {
  /// Mouvement en attente de validation
  pending('pending', 'En attente', 'En attente de validation'),

  /// Mouvement validé
  validated('validated', 'Validé', 'Mouvement validé et approuvé'),

  /// Mouvement rejeté
  rejected('rejected', 'Rejeté', 'Mouvement rejeté'),

  /// Mouvement annulé
  cancelled('cancelled', 'Annulé', 'Mouvement annulé'),

  /// Mouvement en cours de traitement
  processing('processing', 'En cours', 'En cours de traitement');

  const MovementStatus(this.code, this.label, this.description);

  final String code;
  final String label;
  final String description;

  /// Trouve un statut par son code
  static MovementStatus? fromCode(String code) {
    for (MovementStatus status in MovementStatus.values) {
      if (status.code == code) return status;
    }
    return null;
  }

  /// Vérifie si le statut permet la modification
  bool get canBeModified => this == MovementStatus.pending || this == MovementStatus.rejected;

  /// Vérifie si le statut permet la suppression
  bool get canBeDeleted => this == MovementStatus.pending || this == MovementStatus.rejected;

  /// Vérifie si le mouvement est finalisé
  bool get isFinalized => this == MovementStatus.validated || this == MovementStatus.cancelled;

  /// Couleur associée au statut pour l'interface utilisateur
  String get color {
    switch (this) {
      case MovementStatus.pending:
        return '#F59E0B'; // Orange
      case MovementStatus.validated:
        return '#10B981'; // Vert
      case MovementStatus.rejected:
        return '#EF4444'; // Rouge
      case MovementStatus.cancelled:
        return '#6B7280'; // Gris
      case MovementStatus.processing:
        return '#3B82F6'; // Bleu
    }
  }

  @override
  String toString() => label;
}

/// Périodes pour les rapports
enum ReportPeriod {
  /// Aujourd'hui
  today('today', 'Aujourd\'hui', 'Mouvements d\'aujourd\'hui'),

  /// Cette semaine
  thisWeek('this_week', 'Cette semaine', 'Mouvements de cette semaine'),

  /// Ce mois
  thisMonth('this_month', 'Ce mois', 'Mouvements de ce mois'),

  /// Cette année
  thisYear('this_year', 'Cette année', 'Mouvements de cette année'),

  /// 7 derniers jours
  last7Days('last_7_days', '7 derniers jours', 'Mouvements des 7 derniers jours'),

  /// 30 derniers jours
  last30Days('last_30_days', '30 derniers jours', 'Mouvements des 30 derniers jours'),

  /// 3 derniers mois
  last3Months('last_3_months', '3 derniers mois', 'Mouvements des 3 derniers mois'),

  /// Période personnalisée
  custom('custom', 'Période personnalisée', 'Période définie par l\'utilisateur');

  const ReportPeriod(this.code, this.label, this.description);

  final String code;
  final String label;
  final String description;

  /// Trouve une période par son code
  static ReportPeriod? fromCode(String code) {
    for (ReportPeriod period in ReportPeriod.values) {
      if (period.code == code) return period;
    }
    return null;
  }

  /// Calcule les dates de début et fin pour la période
  DateRange getDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (this) {
      case ReportPeriod.today:
        return DateRange(
          start: today,
          end: today.add(const Duration(days: 1)).subtract(const Duration(microseconds: 1)),
        );

      case ReportPeriod.thisWeek:
        final startOfWeek = today.subtract(Duration(days: now.weekday - 1));
        return DateRange(
          start: startOfWeek,
          end: startOfWeek.add(const Duration(days: 7)).subtract(const Duration(microseconds: 1)),
        );

      case ReportPeriod.thisMonth:
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 1).subtract(const Duration(microseconds: 1));
        return DateRange(start: startOfMonth, end: endOfMonth);

      case ReportPeriod.thisYear:
        final startOfYear = DateTime(now.year, 1, 1);
        final endOfYear = DateTime(now.year + 1, 1, 1).subtract(const Duration(microseconds: 1));
        return DateRange(start: startOfYear, end: endOfYear);

      case ReportPeriod.last7Days:
        return DateRange(
          start: today.subtract(const Duration(days: 6)),
          end: today.add(const Duration(days: 1)).subtract(const Duration(microseconds: 1)),
        );

      case ReportPeriod.last30Days:
        return DateRange(
          start: today.subtract(const Duration(days: 29)),
          end: today.add(const Duration(days: 1)).subtract(const Duration(microseconds: 1)),
        );

      case ReportPeriod.last3Months:
        final start = DateTime(now.year, now.month - 2, 1);
        return DateRange(
          start: start,
          end: today.add(const Duration(days: 1)).subtract(const Duration(microseconds: 1)),
        );

      case ReportPeriod.custom:
        // Pour les périodes personnalisées, retourner la période du mois actuel par défaut
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 1).subtract(const Duration(microseconds: 1));
        return DateRange(start: startOfMonth, end: endOfMonth);
    }
  }

  @override
  String toString() => label;
}

/// Niveaux de priorité pour les mouvements
enum MovementPriority {
  /// Priorité basse
  low('low', 'Basse', 'Priorité basse'),

  /// Priorité normale
  normal('normal', 'Normale', 'Priorité normale'),

  /// Priorité haute
  high('high', 'Haute', 'Priorité haute'),

  /// Priorité urgente
  urgent('urgent', 'Urgente', 'Priorité urgente');

  const MovementPriority(this.code, this.label, this.description);

  final String code;
  final String label;
  final String description;

  /// Trouve une priorité par son code
  static MovementPriority? fromCode(String code) {
    for (MovementPriority priority in MovementPriority.values) {
      if (priority.code == code) return priority;
    }
    return null;
  }

  /// Couleur associée à la priorité
  String get color {
    switch (this) {
      case MovementPriority.low:
        return '#10B981'; // Vert
      case MovementPriority.normal:
        return '#6B7280'; // Gris
      case MovementPriority.high:
        return '#F59E0B'; // Orange
      case MovementPriority.urgent:
        return '#EF4444'; // Rouge
    }
  }

  /// Ordre de priorité (plus le nombre est élevé, plus la priorité est haute)
  int get order {
    switch (this) {
      case MovementPriority.low:
        return 1;
      case MovementPriority.normal:
        return 2;
      case MovementPriority.high:
        return 3;
      case MovementPriority.urgent:
        return 4;
    }
  }

  @override
  String toString() => label;
}

/// Types d'actions pour l'audit
enum AuditAction {
  /// Création d'un mouvement
  create('create', 'Création', 'Création d\'un nouveau mouvement'),

  /// Modification d'un mouvement
  update('update', 'Modification', 'Modification d\'un mouvement existant'),

  /// Suppression d'un mouvement
  delete('delete', 'Suppression', 'Suppression d\'un mouvement'),

  /// Validation d'un mouvement
  validate('validate', 'Validation', 'Validation d\'un mouvement'),

  /// Rejet d'un mouvement
  reject('reject', 'Rejet', 'Rejet d\'un mouvement'),

  /// Annulation d'un mouvement
  cancel('cancel', 'Annulation', 'Annulation d\'un mouvement'),

  /// Consultation d'un mouvement
  view('view', 'Consultation', 'Consultation d\'un mouvement');

  const AuditAction(this.code, this.label, this.description);

  final String code;
  final String label;
  final String description;

  /// Trouve une action par son code
  static AuditAction? fromCode(String code) {
    for (AuditAction action in AuditAction.values) {
      if (action.code == code) return action;
    }
    return null;
  }

  /// Vérifie si l'action modifie les données
  bool get isModifying =>
      this == AuditAction.create || this == AuditAction.update || this == AuditAction.delete || this == AuditAction.validate || this == AuditAction.reject || this == AuditAction.cancel;

  /// Vérifie si l'action est critique (nécessite des permissions élevées)
  bool get isCritical => this == AuditAction.delete || this == AuditAction.validate || this == AuditAction.reject || this == AuditAction.cancel;

  @override
  String toString() => label;
}

/// Classe utilitaire pour représenter une plage de dates
class DateRange {
  final DateTime start;
  final DateTime end;

  const DateRange({
    required this.start,
    required this.end,
  });

  /// Vérifie si une date est dans la plage
  bool contains(DateTime date) {
    return date.isAfter(start.subtract(const Duration(microseconds: 1))) && date.isBefore(end.add(const Duration(microseconds: 1)));
  }

  /// Durée de la plage en jours
  int get durationInDays {
    return end.difference(start).inDays + 1;
  }

  /// Formate la plage pour l'affichage
  String format() {
    if (start.year == end.year && start.month == end.month && start.day == end.day) {
      return '${start.day}/${start.month}/${start.year}';
    }
    return '${start.day}/${start.month}/${start.year} - ${end.day}/${end.month}/${end.year}';
  }

  @override
  String toString() => format();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DateRange && other.start == start && other.end == end;
  }

  @override
  int get hashCode => start.hashCode ^ end.hashCode;
}
