import 'package:get/get.dart';
/// Enums pour le module des mouvements financiers

/// Types de mouvements financiers
enum MovementType {
  /// Sortie d'argent (dépense)
  expense('expense', 'financialmovements_depense'.tr, 'Sortie d\'argent'),

  /// Remboursement
  refund('refund', 'Remboursement', 'financialmovements_remboursement_depense'.tr),

  /// Avance
  advance('advance', 'Avance', 'financialmovements_avance_sur_salaire_depense'.tr),

  /// Autre type de mouvement
  other('other', 'Autre', 'financialmovements_autre_type_mouvement'.tr);

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
  pending('pending', 'En attente', 'financialmovements_attente_validation'.tr),

  /// Mouvement validé
  validated('validated', 'financialmovements_valide'.tr, 'financialmovements_mouvement_valide_approuve'.tr),

  /// Mouvement rejeté
  rejected('rejected', 'financialmovements_rejete'.tr, 'financialmovements_mouvement_rejete'.tr),

  /// Mouvement annulé
  cancelled('cancelled', 'suppliers_annule'.tr, 'financialmovements_mouvement_annule'.tr),

  /// Mouvement en cours de traitement
  processing('processing', 'En cours', 'financialmovements_cours_traitement'.tr);

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
  thisWeek('this_week', 'sales_this_week'.tr, 'financial_movements_filter_this_week_desc'.tr),

  /// Ce mois
  thisMonth('this_month', 'analytics_this_month'.tr, 'financial_movements_filter_this_month_desc'.tr),

  /// Cette année
  thisYear('this_year', 'analytics_this_year'.tr, 'financialmovements_mouvements_annee'.tr),

  /// 7 derniers jours
  last7Days('last_7_days', '7 derniers jours', 'financialmovements_mouvements_7_derniers_jours'.tr),

  /// 30 derniers jours
  last30Days('last_30_days', '30 derniers jours', 'financialmovements_mouvements_30_derniers_jours'.tr),

  /// 3 derniers mois
  last3Months('last_3_months', '3 derniers mois', 'financialmovements_mouvements_3_derniers_mois'.tr),

  /// Période personnalisée
  custom('custom', 'sales_custom_period'.tr, 'financialmovements_periode_definie_par_utilisateur'.tr);

  ReportPeriod(this.code, this.label, this.description);

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
  low('low', 'Basse', 'financialmovements_priorite_basse'.tr),

  /// Priorité normale
  normal('normal', 'Normale', 'financialmovements_priorite_normale'.tr),

  /// Priorité haute
  high('high', 'Haute', 'financialmovements_priorite_haute'.tr),

  /// Priorité urgente
  urgent('urgent', 'Urgente', 'financialmovements_priorite_urgente'.tr);

  MovementPriority(this.code, this.label, this.description);

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
  create('create', 'roles_priv_create'.tr, 'financialmovements_creation_nouveau_mouvement_2'.tr),

  /// Modification d'un mouvement
  update('update', 'Modification', 'financialmovements_modification_mouvement_existant'.tr),

  /// Suppression d'un mouvement
  delete('delete', 'Suppression', 'financialmovements_suppression_mouvement_3'.tr),

  /// Validation d'un mouvement
  validate('validate', 'Validation', 'financialmovements_validation_mouvement'.tr),

  /// Rejet d'un mouvement
  reject('reject', 'Rejet', 'financialmovements_rejet_mouvement'.tr),

  /// Annulation d'un mouvement
  cancel('cancel', 'Annulation', 'financialmovements_annulation_mouvement'.tr),

  /// Consultation d'un mouvement
  view('view', 'Consultation', 'financialmovements_consultation_mouvement'.tr);

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
